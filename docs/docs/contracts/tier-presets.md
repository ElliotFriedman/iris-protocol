---
sidebar_position: 5
title: Tier Presets
---

# Tier Presets

Tier presets are Solidity **libraries** that construct the correct `Caveat[]` array for each trust tier. Instead of manually configuring individual enforcers, call a single library function to get a fully-configured caveat array for signing a delegation.

## TierOne (Supervised) -- 4 Caveats

Bundles enforcers for tightly scoped, monitored agent access.

### Configuration

| Enforcer | Setting |
|----------|---------|
| SpendingCapEnforcer | User-specified daily cap (86400s period) |
| ContractWhitelistEnforcer | User-specified approved contracts |
| TimeWindowEnforcer | Valid from now until user-specified expiry |
| ReputationGateEnforcer | User-specified minimum score |

### Usage

```solidity
Caveat[] memory caveats = TierOne.configureTierOne(
    address(spendingCapEnforcer),
    address(whitelistEnforcer),
    address(timeWindowEnforcer),
    address(reputationGateEnforcer),
    address(reputationOracle),
    agentId,              // ERC-8004 identity token ID
    10 ether,             // dailyCap
    allowedContracts,     // address[] memory
    block.timestamp + 7 days,  // validUntil
    40                    // minReputation
);
```

### Example

```solidity
address[] memory contracts = new address[](1);
contracts[0] = UNISWAP_ROUTER;

Caveat[] memory caveats = TierOne.configureTierOne(
    address(d.spendingCap), address(d.contractWhitelist),
    address(d.timeWindow), address(d.reputationGate),
    address(d.reputationOracle), agentId,
    10 ether, contracts, block.timestamp + 7 days, 40
);

// Use caveats in a Delegation struct, then sign with EIP-712
Delegation memory del = Delegation({
    delegator: address(account),
    delegate: agentOperator,
    authority: address(0),
    caveats: caveats,
    salt: 1,
    signature: ""
});
```

## TierTwo (Autonomous) -- 5 Caveats

Bundles enforcers for autonomous agent operation with safety guardrails. Adds SingleTxCap on top of Tier 1.

### Configuration

| Enforcer | Setting |
|----------|---------|
| SpendingCapEnforcer | User-specified daily cap (86400s period) |
| ContractWhitelistEnforcer | User-specified approved contracts |
| TimeWindowEnforcer | Valid from now until user-specified expiry |
| ReputationGateEnforcer | User-specified minimum score |
| SingleTxCapEnforcer | User-specified max value per transaction |

### Usage

```solidity
Caveat[] memory caveats = TierTwo.configureTierTwo(
    address(spendingCapEnforcer),
    address(whitelistEnforcer),
    address(timeWindowEnforcer),
    address(reputationGateEnforcer),
    address(singleTxCapEnforcer),
    address(reputationOracle),
    agentId,
    50 ether,             // dailyCap
    10 ether,             // maxTxValue
    allowedContracts,
    block.timestamp + 30 days,
    40                    // minReputation
);
```

## TierThree (Full Delegation) -- 6 Caveats

Maximum autonomy with all 6 safety mechanisms. Uses struct parameters to avoid stack-too-deep.

### Configuration

| Enforcer | Setting |
|----------|---------|
| SpendingCapEnforcer | User-specified **weekly** cap (604800s period) |
| ContractWhitelistEnforcer | User-specified approved contracts |
| TimeWindowEnforcer | Valid from now until user-specified expiry |
| ReputationGateEnforcer | User-specified minimum score (typically higher) |
| SingleTxCapEnforcer | User-specified max value per transaction |
| CooldownEnforcer | User-specified cooldown period and threshold |

### Usage

```solidity
TierThree.Enforcers memory enforcers = TierThree.Enforcers({
    spendingCapEnforcer: address(d.spendingCap),
    whitelistEnforcer: address(d.contractWhitelist),
    timeWindowEnforcer: address(d.timeWindow),
    reputationGateEnforcer: address(d.reputationGate),
    singleTxCapEnforcer: address(d.singleTxCap),
    cooldownEnforcer: address(d.cooldown)
});

TierThree.Params memory params = TierThree.Params({
    reputationOracle: address(d.reputationOracle),
    agentId: agentId,
    weeklyCap: 100 ether,
    maxTxValue: 20 ether,
    allowedContracts: allowedContracts,
    validUntil: block.timestamp + 90 days,
    minReputation: 40,
    cooldownPeriod: 1 hours,
    cooldownThreshold: 10 ether
});

Caveat[] memory caveats = TierThree.configureTierThree(enforcers, params);
```

## Custom Caveat Bundles

Presets are not mandatory. Build custom delegations by combining any enforcers:

```solidity
// Custom: high spending cap + single contract + reputation gate
Caveat[] memory caveats = new Caveat[](3);

caveats[0] = Caveat({
    enforcer: address(spendingCapEnforcer),
    terms: abi.encode(uint256(5000 ether), uint256(86400))
});

caveats[1] = Caveat({
    enforcer: address(contractWhitelistEnforcer),
    terms: abi.encode(allowedContracts)
});

caveats[2] = Caveat({
    enforcer: address(reputationGateEnforcer),
    terms: abi.encode(address(reputationOracle), agentId, uint256(80))
});
```

## Upgrading Tiers

To change an agent's tier:

1. Revoke the existing delegation
2. Create a new delegation with the desired tier preset

```solidity
// Revoke Tier 1 delegation
delegationManager.revokeDelegation(tierOneDelegation);

// Build new Tier 2 caveats and sign a new delegation
Caveat[] memory newCaveats = TierTwo.configureTierTwo(...);
// ... construct and sign new Delegation struct
```

Revocation is instant. The agent's old delegation becomes invalid immediately. The new delegation takes effect as soon as it is signed by the user.
