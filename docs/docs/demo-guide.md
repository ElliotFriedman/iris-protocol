---
sidebar_position: 8
title: Demo Guide
---

# Demo Guide

This guide walks through the 9-step demo flow that demonstrates Iris Protocol's core capabilities. Each step shows a distinct feature of trustless agent wallet management.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js 18+

## Running the Demo Locally

```bash
# Clone and build
git clone https://github.com/iris-protocol/iris-protocol.git
cd iris-protocol/contracts
forge install && forge build

# Start Anvil and deploy
anvil &
forge script script/DeployLocal.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# Run the demo script
forge script script/Demo.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## The 9-Step Flow

### Step 1: Agent Registers on ERC-8004

The AI agent registers its identity in the IrisAgentRegistry, minting a lightweight identity NFT.

```solidity
// Agent calls registerAgent()
uint256 agentId = agentRegistry.registerAgent("ipfs://agent-metadata");
// Agent starts with reputation score of 50
```

**What to observe:** The agent now has an onchain identity with an `agentId`. Its initial reputation score is 50.

### Step 2: User Creates Iris Wallet

The user deploys an IrisAccount (ERC-4337 smart contract wallet) via the factory.

```solidity
address wallet = factory.createAccount(
    userAddress,
    address(delegationManager),
    0  // salt
);
```

**What to observe:** The user now has a smart contract wallet that supports delegations. The wallet address is deterministic.

### Step 3: Agent Requests Tier 1 Access

The agent requests a Tier 1 (Supervised) delegation from the user. This follows the ERC-7715 permission request flow.

```solidity
// User sees: "Agent #1 (reputation: 50/100) requests:
//   spend up to X ETH/day on whitelisted contracts, valid 7 days"
```

**What to observe:** The user sees a clear breakdown of what Tier 1 access means -- spending limits, contract restrictions, and reputation requirements.

### Step 4: User Approves Delegation

The user approves the delegation request by building and signing a delegation with EIP-712.

```solidity
// Build Tier 1 caveat array
Caveat[] memory caveats = TierOne.configureTierOne(
    address(spendingCap), address(whitelist), address(timeWindow),
    address(reputationGate), address(reputationOracle), agentId,
    dailyCap, allowedContracts, validUntil, minReputation
);

// Construct delegation and sign with EIP-712
Delegation memory del = Delegation({
    delegator: address(account), delegate: agentOperator,
    authority: address(0), caveats: caveats, salt: 1, signature: ""
});
bytes32 hash = delegationManager.getDelegationHash(del);
// User signs hash...
```

**What to observe:** The delegation is created with all Tier 1 caveat enforcers attached.

### Step 5: Agent Executes a Swap -- Succeeds

The agent redeems its delegation to execute a transaction on an approved contract.

```solidity
// Agent redeems delegation
Delegation[] memory chain = new Delegation[](1);
chain[0] = signedDelegation;

delegationManager.redeemDelegation(chain, Action({
    target: address(vault), value: 3 ether,
    callData: abi.encodeCall(Vault.deposit, ())
}));
// All caveat enforcers pass -- transaction executes
```

**What to observe:** The transaction succeeds because it satisfies every caveat enforcer.

### Step 6: Agent Attempts Excess Spend -- Blocked

The agent attempts a transaction that would exceed a caveat limit.

```solidity
// Agent attempts too-large transaction
delegationManager.redeemDelegation(chain, Action({
    target: address(vault), value: 25 ether,  // exceeds daily cap
    callData: abi.encodeCall(Vault.deposit, ())
}));
// SpendingCapEnforcer: exceeded -- REVERTS
```

**What to observe:** The transaction reverts onchain. The caveat enforcer blocks the operation. The agent cannot bypass this because it is enforced by smart contract code.

### Step 7: User Upgrades to Tier 2

The user upgrades the agent to Tier 2 (Autonomous) -- higher limits, additional SingleTxCap.

```solidity
// Revoke Tier 1
delegationManager.revokeDelegation(tierOneDelegation);

// Build and sign Tier 2 delegation
Caveat[] memory caveats = TierTwo.configureTierTwo(...);
// ... sign new delegation
```

**What to observe:** The old delegation is instantly revoked. The new Tier 2 delegation has higher caps.

### Step 8: Reputation Drop -- Execution Blocked

The agent's reputation score drops below the delegation's minimum requirement.

```solidity
// Negative feedback submitted
reputationOracle.submitFeedback(agentId, false);  // -5
reputationOracle.submitFeedback(agentId, false);  // -5
reputationOracle.submitFeedback(agentId, false);  // -5
// Agent score drops below minReputation threshold

// Agent attempts to use delegation
delegationManager.redeemDelegation(chain, action);
// ReputationGateEnforcer: score < minScore -- REVERTS
```

**What to observe:** Even though the delegation was legitimately granted, the reputation enforcer blocks execution in real-time. No one manually revoked the delegation. The protocol itself detected the reputation change and blocked the agent. This is the dynamic reputation gate in action.

### Step 9: User Revokes All Delegations

The user revokes all outstanding delegations.

```solidity
delegationManager.revokeDelegation(delegation);
// All agent access is immediately terminated
```

**What to observe:** Instant revocation. The agent has zero access to the wallet. Any subsequent attempt to redeem the delegation will revert.

## Key Takeaways

1. **Every permission check is onchain.** No API servers, no TEEs, no trusted intermediaries.
2. **Reputation gates are dynamic.** Step 8 demonstrates that permissions degrade in real-time based on onchain state, without manual intervention.
3. **The system is composable.** Steps 5-6 show multiple enforcers working together as a permission bundle.
4. **Revocation is instant.** Step 9 shows single-transaction revocation.
5. **Standards-first design.** Every component maps to an ERC standard (4337, 7710, 7715, 8004).

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Contracts not deploying | Ensure Foundry is up to date: `foundryup` |
| Transaction failing unexpectedly | Check that the agent is registered and has sufficient reputation |
| Anvil not running | Run `anvil &` in a separate terminal |
| Reputation not updating | Ensure the oracle feedback transaction is confirmed before retesting |
