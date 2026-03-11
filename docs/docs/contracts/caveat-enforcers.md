---
sidebar_position: 3
title: Caveat Enforcers
---

# Caveat Enforcers

Caveat enforcers are independent contracts that gate delegated execution. Each enforcer implements a single validation rule. Multiple enforcers compose together: a delegation succeeds only if **every** attached enforcer passes.

All enforcers implement the `ICaveatEnforcer` interface:

```solidity
interface ICaveatEnforcer {
    /// @notice Called before delegated execution
    function beforeHook(
        bytes calldata terms,       // Enforcer-specific configuration
        bytes calldata args,        // Runtime arguments from redeemer
        address delegationManager,  // The DelegationManager calling this
        bytes32 delegationHash,     // Hash of the delegation being redeemed
        address delegator,          // The account that created the delegation
        address redeemer,           // The agent redeeming the delegation
        address target,             // Target contract of the execution
        uint256 value,              // ETH value of the execution
        bytes calldata callData     // Calldata of the execution
    ) external;

    /// @notice Called after delegated execution
    function afterHook(
        bytes calldata terms,
        bytes calldata args,
        address delegationManager,
        bytes32 delegationHash,
        address delegator,
        address redeemer,
        address target,
        uint256 value,
        bytes calldata callData
    ) external;
}
```

---

## SpendingCapEnforcer

Enforces cumulative spending limits over a configurable rolling period (daily, weekly, or custom).

### Terms Encoding

```solidity
// abi.encode(uint256 allowance, uint256 period)
//   allowance: Maximum spend in wei per period
//   period: Period length in seconds (86400 = daily)
bytes memory terms = abi.encode(uint256(100 ether), uint256(86400));
```

### Behavior

- Tracks cumulative spend per delegation per period via `periodSpend[delegationHash][periodIndex]`
- Period index is calculated as `block.timestamp / period`
- `beforeHook` checks spend would not exceed allowance (view, no state change)
- `afterHook` records the spend for the current period — **only callable by the authorized DelegationManager** (`msg.sender` check prevents external state manipulation)
- Initialized with `delegationManager` address in constructor

### Example

```solidity
// Configure: 100 ETH/day spending limit
bytes memory terms = abi.encode(uint256(100 ether), uint256(86400));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `SpendingCapExceeded(uint256 requested, uint256 remaining)` | Transaction value exceeds remaining cap for the period |

---

## ContractWhitelistEnforcer

Restricts delegated calls to a set of approved target contract addresses.

### Terms Encoding

```solidity
// abi.encode(address[] allowedContracts)
address[] memory allowed = new address[](2);
allowed[0] = UNISWAP_ROUTER;
allowed[1] = AAVE_POOL;
bytes memory terms = abi.encode(allowed);
```

### Behavior

- Checks that `target` is in the allowed list
- Reverts if the agent attempts to call a non-whitelisted contract

### Error Cases

| Error | Condition |
|-------|-----------|
| `ContractNotWhitelisted(address target)` | Target contract is not in the approved list |

---

## FunctionSelectorEnforcer

Restricts delegated calls to a set of approved function selectors.

### Terms Encoding

```solidity
// abi.encode(bytes4[] allowedSelectors)
bytes4[] memory selectors = new bytes4[](2);
selectors[0] = ISwapRouter.swap.selector;
selectors[1] = IERC20.transfer.selector;
bytes memory terms = abi.encode(selectors);
```

### Behavior

- Rejects calldata shorter than 4 bytes with `CalldataTooShort()`
- Extracts the first 4 bytes of calldata to determine the function selector
- Checks that the selector is in the allowed list

### Error Cases

| Error | Condition |
|-------|-----------|
| `CalldataTooShort()` | Calldata is fewer than 4 bytes (no valid function selector) |
| `SelectorNotAllowed(bytes4 selector)` | Function selector is not in the approved list |

---

## TimeWindowEnforcer

Limits delegation validity to a specific time range.

### Terms Encoding

```solidity
// abi.encode(uint256 notBefore, uint256 notAfter)
bytes memory terms = abi.encode(block.timestamp, block.timestamp + 7 days);
```

### Behavior

- Checks `block.timestamp` against the configured window
- Reverts if the current time is outside the valid range

### Error Cases

| Error | Condition |
|-------|-----------|
| `DelegationNotYetValid(uint256 current, uint256 validAfter)` | Current time is before the valid window |
| `DelegationExpired(uint256 current, uint256 validBefore)` | Current time is after the valid window |

---

## SingleTxCapEnforcer

Caps the maximum ETH value per individual transaction.

### Terms Encoding

```solidity
// abi.encode(uint256 maxValue)
bytes memory terms = abi.encode(uint256(10 ether));
```

### Behavior

- Checks the `value` field of the delegated call
- Reverts if the value exceeds the configured cap
- Unlike SpendingCapEnforcer, this does not track cumulative spend

### Error Cases

| Error | Condition |
|-------|-----------|
| `SingleTxCapExceeded(uint256 value, uint256 cap)` | Transaction value exceeds the per-tx cap |

---

## CooldownEnforcer

Enforces a minimum time interval between transactions that exceed a value threshold.

### Terms Encoding

```solidity
// abi.encode(uint256 cooldownPeriod, uint256 valueThreshold)
bytes memory terms = abi.encode(uint256(1 hours), uint256(10 ether));
```

### Behavior

- Tracks the timestamp of the last qualifying transaction per delegation via `lastExecution[delegationHash]`
- If the new transaction's value >= `valueThreshold`, checks that `cooldownPeriod` has elapsed
- Transactions below the threshold are not subject to cooldown and bypass the check
- `afterHook` records `lastExecution[delegationHash] = block.timestamp` if value meets threshold — **only callable by the authorized DelegationManager**
- Initialized with `delegationManager` address in constructor

### Error Cases

| Error | Condition |
|-------|-----------|
| `CooldownNotElapsed(uint256 nextAllowed, uint256 current)` | Not enough time has passed since the last large transaction |

---

## ReputationGateEnforcer

The ReputationGateEnforcer queries an agent's ERC-8004 reputation score in real-time and blocks execution if the score falls below a configurable threshold.

This enforcer enables **dynamic permission degradation**: an agent that misbehaves loses access not just to one user's wallet, but to all delegations across the network that require a minimum reputation score.

See the [dedicated ReputationGateEnforcer page](./reputation-gate.md) for a deep dive.

### Terms Encoding

```solidity
// abi.encode(address reputationOracle, uint256 agentId, uint256 minScore)
//   reputationOracle: Contract exposing getReputationScore(uint256)
//   agentId: The agent's ERC-8004 identity token ID
//   minScore: Minimum reputation score (0-100) required
bytes memory terms = abi.encode(
    address(reputationOracle),
    agentId,
    uint256(70)
);
```

### Behavior

1. Decodes the oracle address, agentId, and minimum score from `terms`
2. Queries `getReputationScore(uint256 agentId)` via staticcall
3. Compares the live score against `minScore`
4. Reverts if the score is below the threshold
5. Returns successfully if the score meets the threshold
6. Score is checked on **every execution**, not just at delegation creation
7. Stateless -- no storage, single instance serves all delegations

### Error Cases

| Error | Condition |
|-------|-----------|
| `ReputationTooLow(uint256 agentId, uint256 currentScore, uint256 requiredScore)` | Agent's reputation score is below the minimum threshold |
| `InvalidTerms()` | Terms cannot be decoded or oracle address is zero |
