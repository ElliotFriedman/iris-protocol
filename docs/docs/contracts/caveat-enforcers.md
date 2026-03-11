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
    /// @param terms Enforcer-specific configuration (encoded)
    /// @param args Execution-specific arguments
    /// @param delegation The delegation being redeemed
    function beforeHook(
        bytes calldata terms,
        bytes calldata args,
        Delegation calldata delegation
    ) external;

    /// @notice Called after delegated execution
    /// @param terms Enforcer-specific configuration (encoded)
    /// @param args Execution-specific arguments
    /// @param delegation The delegation being redeemed
    function afterHook(
        bytes calldata terms,
        bytes calldata args,
        Delegation calldata delegation
    ) external;
}
```

---

## SpendingCapEnforcer

Enforces cumulative spending limits over a configurable time period (daily, weekly, or monthly).

### Parameters

```solidity
struct SpendingCapTerms {
    uint256 cap;        // Maximum spend in wei
    uint256 period;     // Period in seconds (86400 = daily)
}
```

### Behavior

- Tracks cumulative spend per delegation per period
- Resets at the start of each new period
- Reverts with `SpendingCapExceeded` if the transaction would exceed the cap

### Example

```solidity
// Configure: $100/day spending limit
bytes memory terms = abi.encode(SpendingCapTerms({
    cap: 100e18,    // 100 USDC (18 decimals)
    period: 86400   // 1 day
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `SpendingCapExceeded(uint256 requested, uint256 remaining)` | Transaction value exceeds remaining cap for the period |

---

## ContractWhitelistEnforcer

Restricts delegated calls to a set of approved target contract addresses.

### Parameters

```solidity
struct WhitelistTerms {
    address[] allowedContracts; // Approved target addresses
}
```

### Behavior

- Checks that `target` is in the allowed list
- Reverts if the agent attempts to call a non-whitelisted contract

### Example

```solidity
// Configure: only allow Uniswap and Aave
address[] memory allowed = new address[](2);
allowed[0] = UNISWAP_ROUTER;
allowed[1] = AAVE_POOL;
bytes memory terms = abi.encode(WhitelistTerms({
    allowedContracts: allowed
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `ContractNotWhitelisted(address target)` | Target contract is not in the approved list |

---

## FunctionSelectorEnforcer

Restricts delegated calls to a set of approved function selectors.

### Parameters

```solidity
struct SelectorTerms {
    bytes4[] allowedSelectors; // Approved function selectors
}
```

### Behavior

- Extracts the first 4 bytes of calldata to determine the function selector
- Checks that the selector is in the allowed list
- Reverts if the agent attempts to call a non-whitelisted function

### Example

```solidity
// Configure: only allow swap() and transfer()
bytes4[] memory selectors = new bytes4[](2);
selectors[0] = ISwapRouter.swap.selector;
selectors[1] = IERC20.transfer.selector;
bytes memory terms = abi.encode(SelectorTerms({
    allowedSelectors: selectors
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `SelectorNotAllowed(bytes4 selector)` | Function selector is not in the approved list |

---

## TimeWindowEnforcer

Limits delegation validity to a specific time range.

### Parameters

```solidity
struct TimeWindowTerms {
    uint256 validAfter;  // Unix timestamp: delegation valid after this time
    uint256 validBefore; // Unix timestamp: delegation valid before this time
}
```

### Behavior

- Checks `block.timestamp` against the configured window
- Reverts if the current time is outside the valid range
- Useful for time-limited delegations or active-hours-only configurations

### Example

```solidity
// Configure: valid for the next 24 hours
bytes memory terms = abi.encode(TimeWindowTerms({
    validAfter: block.timestamp,
    validBefore: block.timestamp + 86400
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `DelegationNotYetValid(uint256 current, uint256 validAfter)` | Current time is before the valid window |
| `DelegationExpired(uint256 current, uint256 validBefore)` | Current time is after the valid window |

---

## SingleTxCapEnforcer

Caps the maximum ETH value per individual transaction.

### Parameters

```solidity
struct SingleTxCapTerms {
    uint256 maxValue; // Maximum ETH value in wei per transaction
}
```

### Behavior

- Checks the `value` field of the delegated call
- Reverts if the value exceeds the configured cap
- Unlike SpendingCapEnforcer, this does not track cumulative spend

### Example

```solidity
// Configure: max $50 per transaction
bytes memory terms = abi.encode(SingleTxCapTerms({
    maxValue: 50e18
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `SingleTxCapExceeded(uint256 value, uint256 cap)` | Transaction value exceeds the per-tx cap |

---

## CooldownEnforcer

Enforces a minimum time interval between transactions that exceed a value threshold.

### Parameters

```solidity
struct CooldownTerms {
    uint256 cooldownPeriod;   // Minimum seconds between qualifying transactions
    uint256 valueThreshold;   // Transactions above this value trigger the cooldown
}
```

### Behavior

- Tracks the timestamp of the last qualifying transaction per delegation
- If the new transaction's value exceeds `valueThreshold`, checks that `cooldownPeriod` has elapsed since the last qualifying transaction
- Transactions below the threshold are not subject to cooldown

### Example

```solidity
// Configure: 5-minute cooldown between transactions over $200
bytes memory terms = abi.encode(CooldownTerms({
    cooldownPeriod: 300,        // 5 minutes
    valueThreshold: 200e18      // $200
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `CooldownNotElapsed(uint256 timeRemaining)` | Not enough time has passed since the last large transaction |

---

## ReputationGateEnforcer

**This is the novel contribution of Iris Protocol.** The ReputationGateEnforcer queries an agent's ERC-8004 reputation score in real-time and blocks execution if the score falls below a configurable threshold.

This enforcer enables **dynamic permission degradation**: an agent that misbehaves loses access not just to one user's wallet, but to all delegations across the network that require a minimum reputation score.

See the [dedicated ReputationGateEnforcer page](./reputation-gate.md) for a deep dive.

### Parameters

```solidity
struct ReputationGateTerms {
    address reputationOracle;  // Address of the IrisReputationOracle
    uint256 minimumScore;      // Minimum reputation score (0-100)
    address agentRegistry;     // Address of the IrisAgentRegistry (ERC-8004)
}
```

### Behavior

1. Extracts the agent's address from the delegation
2. Queries `IrisReputationOracle.getScore(agentAddress)` onchain
3. Compares the live score against `minimumScore`
4. Reverts if the score is below the threshold
5. Score is checked on **every execution**, not just at delegation creation

### Example

```solidity
// Configure: require minimum reputation score of 70
bytes memory terms = abi.encode(ReputationGateTerms({
    reputationOracle: IRIS_REPUTATION_ORACLE,
    minimumScore: 70,
    agentRegistry: IRIS_AGENT_REGISTRY
}));
```

### Error Cases

| Error | Condition |
|-------|-----------|
| `ReputationTooLow(address agent, uint256 score, uint256 required)` | Agent's reputation score is below the minimum threshold |
| `AgentNotRegistered(address agent)` | Agent does not have an ERC-8004 identity |
