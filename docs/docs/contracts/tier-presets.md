---
sidebar_position: 5
title: Tier Presets
---

# Tier Presets

Tier presets are convenience contracts that bundle the correct set of caveat enforcers for each trust tier. Instead of manually configuring individual enforcers, users can call a single function to create a fully-configured delegation.

## TierOnePreset (Supervised)

Bundles enforcers for tightly scoped, monitored agent access.

### Configuration

| Enforcer | Setting |
|----------|---------|
| SpendingCapEnforcer | 100 USDC / day |
| SingleTxCapEnforcer | 50 USDC per transaction |
| ContractWhitelistEnforcer | User-specified approved contracts |
| FunctionSelectorEnforcer | User-specified allowed selectors |
| TimeWindowEnforcer | User-specified active window |
| ReputationGateEnforcer | Minimum score: 50 |

### Usage

```solidity
/// @notice Create a Tier 1 delegation for an agent
/// @param manager The DelegationManager address
/// @param agent The agent's address
/// @param approvedContracts Whitelisted target contracts
/// @param allowedSelectors Whitelisted function selectors
/// @param validUntil Delegation expiry timestamp
function createTierOneDelegation(
    IDelegationManager manager,
    address agent,
    address[] calldata approvedContracts,
    bytes4[] calldata allowedSelectors,
    uint256 validUntil
) external returns (bytes32 delegationHash);
```

### Example

```solidity
address[] memory contracts = new address[](1);
contracts[0] = UNISWAP_ROUTER;

bytes4[] memory selectors = new bytes4[](1);
selectors[0] = ISwapRouter.exactInputSingle.selector;

bytes32 hash = tierOnePreset.createTierOneDelegation(
    delegationManager,
    agentAddress,
    contracts,
    selectors,
    block.timestamp + 30 days
);
```

## TierTwoPreset (Autonomous)

Bundles enforcers for autonomous agent operation with safety guardrails.

### Configuration

| Enforcer | Setting |
|----------|---------|
| SpendingCapEnforcer | 1,000 USDC / day |
| SingleTxCapEnforcer | 500 USDC per transaction |
| FunctionSelectorEnforcer | Broader function whitelist |
| CooldownEnforcer | 5-minute cooldown on transactions over 200 USDC |
| ReputationGateEnforcer | Minimum score: 70 |

### Usage

```solidity
/// @notice Create a Tier 2 delegation for an agent
/// @param manager The DelegationManager address
/// @param agent The agent's address
/// @param allowedSelectors Whitelisted function selectors
function createTierTwoDelegation(
    IDelegationManager manager,
    address agent,
    bytes4[] calldata allowedSelectors
) external returns (bytes32 delegationHash);
```

### Example

```solidity
bytes4[] memory selectors = new bytes4[](3);
selectors[0] = ISwapRouter.exactInputSingle.selector;
selectors[1] = IPool.supply.selector;
selectors[2] = IPool.withdraw.selector;

bytes32 hash = tierTwoPreset.createTierTwoDelegation(
    delegationManager,
    agentAddress,
    selectors
);
```

## TierThreePreset (Full Delegation)

Minimal restrictions. Only reputation gates the agent.

### Configuration

| Enforcer | Setting |
|----------|---------|
| ReputationGateEnforcer | Minimum score: 90 |

### Usage

```solidity
/// @notice Create a Tier 3 delegation for an agent
/// @param manager The DelegationManager address
/// @param agent The agent's address
function createTierThreeDelegation(
    IDelegationManager manager,
    address agent
) external returns (bytes32 delegationHash);
```

### Example

```solidity
bytes32 hash = tierThreePreset.createTierThreeDelegation(
    delegationManager,
    agentAddress
);
```

## Custom Caveat Bundles

Presets are not mandatory. You can build custom delegations by combining any enforcers:

```solidity
// Custom: high spending cap but restricted to a single contract
Caveat[] memory caveats = new Caveat[](3);

caveats[0] = Caveat({
    enforcer: address(spendingCapEnforcer),
    terms: abi.encode(SpendingCapTerms({cap: 5000e18, period: 86400}))
});

caveats[1] = Caveat({
    enforcer: address(contractWhitelistEnforcer),
    terms: abi.encode(WhitelistTerms({allowedContracts: [AAVE_POOL]}))
});

caveats[2] = Caveat({
    enforcer: address(reputationGateEnforcer),
    terms: abi.encode(ReputationGateTerms({
        reputationOracle: REPUTATION_ORACLE,
        minimumScore: 80,
        agentRegistry: AGENT_REGISTRY
    }))
});

delegationManager.createDelegation(agentAddress, caveats);
```

## Upgrading Tiers

To change an agent's tier:

1. Revoke the existing delegation
2. Create a new delegation with the desired tier preset

```solidity
// Upgrade from Tier 1 to Tier 2
delegationManager.revokeDelegation(tierOneDelegationHash);

bytes32 newHash = tierTwoPreset.createTierTwoDelegation(
    delegationManager,
    agentAddress,
    selectors
);
```

Revocation is instant. The agent's Tier 1 delegation becomes invalid immediately. The new Tier 2 delegation takes effect as soon as it is signed by the user.
