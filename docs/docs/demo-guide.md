---
sidebar_position: 8
title: Demo Guide
---

# Demo Guide

This guide walks through the 9-step demo flow that demonstrates Iris Protocol's core capabilities. Each step shows a distinct feature of trustless agent wallet management.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js 18+
- A Base Sepolia RPC URL
- Test ETH on Base Sepolia

## Running the Demo Locally

```bash
# Clone the repo
git clone https://github.com/iris-protocol/iris-protocol.git
cd iris-protocol

# Install dependencies
forge install
cd demo && npm install

# Set environment variables
cp .env.example .env
# Edit .env with your RPC URL and private keys

# Deploy contracts to local fork
anvil --fork-url $BASE_SEPOLIA_RPC &
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Start the demo app
cd demo && npm run dev
```

## The 9-Step Flow

### Step 1: Agent Registers on ERC-8004

The AI agent registers its identity in the IrisAgentRegistry, minting a non-transferable identity NFT.

```solidity
// Agent calls register()
uint256 tokenId = agentRegistry.register("ipfs://agent-metadata");
// Agent starts with reputation score of 50
```

**What to observe:** The agent now has an onchain identity. Its initial reputation score is 50, making it eligible for Tier 1 delegations.

`[Screenshot placeholder: Agent registration transaction confirmation]`

### Step 2: User Creates Iris Wallet

The user deploys an IrisAccount (ERC-4337 smart contract wallet) via the factory.

```solidity
IrisAccount wallet = factory.createAccount(userAddress, salt);
```

**What to observe:** The user now has a smart contract wallet that supports delegations. The wallet address is deterministic.

`[Screenshot placeholder: Wallet creation with address displayed]`

### Step 3: Agent Requests Tier 1 Access

The agent requests a Tier 1 (Supervised) delegation from the user. This follows the ERC-7715 permission request flow.

```solidity
// Agent submits a permission request
// User sees: "Agent X requests Tier 1 access to your wallet"
// Tier 1 includes: $100/day spend cap, $50/tx cap, approved contracts only
```

**What to observe:** The user sees a clear breakdown of what Tier 1 access means -- spending limits, contract restrictions, and reputation requirements.

`[Screenshot placeholder: Permission request UI with tier details]`

### Step 4: User Approves Delegation

The user approves the delegation request, signing the delegation offchain (EIP-712).

```solidity
// User approves -- TierOnePreset creates the delegation
bytes32 delegationHash = tierOnePreset.createTierOneDelegation(
    delegationManager,
    agentAddress,
    approvedContracts,
    allowedSelectors,
    validUntil
);
```

**What to observe:** The delegation is created with all Tier 1 caveat enforcers attached. The agent can now execute transactions within the defined bounds.

`[Screenshot placeholder: Delegation approval confirmation]`

### Step 5: Agent Executes $50 Swap -- Succeeds

The agent redeems its delegation to execute a $50 token swap on an approved DEX.

```solidity
// Agent redeems delegation for a $50 swap
delegationManager.redeemDelegation(delegation, swapCalldata);
// All caveat enforcers pass:
// ✅ SpendingCap: $50 < $100/day
// ✅ SingleTxCap: $50 <= $50
// ✅ ContractWhitelist: Uniswap is approved
// ✅ FunctionSelector: swap() is allowed
// ✅ ReputationGate: score 50 >= 50
// → Transaction executes successfully
```

**What to observe:** The transaction succeeds because it satisfies every caveat enforcer. The agent's reputation increases slightly.

`[Screenshot placeholder: Successful swap transaction with enforcer checkmarks]`

### Step 6: Agent Attempts $200 Swap -- Blocked

The agent attempts a $200 swap, exceeding the Tier 1 single-transaction cap.

```solidity
// Agent attempts a $200 swap
delegationManager.redeemDelegation(delegation, largeSwapCalldata);
// ❌ SingleTxCap: $200 > $50 cap
// → Transaction REVERTS with SingleTxCapExceeded(200e18, 50e18)
```

**What to observe:** The transaction reverts onchain. The caveat enforcer blocks the operation. The agent cannot bypass this restriction because it is enforced by smart contract code, not an API.

`[Screenshot placeholder: Blocked transaction with error message]`

### Step 7: User Bumps to Tier 2

The user upgrades the agent to Tier 2 (Autonomous) -- higher limits, broader permissions.

```solidity
// Revoke Tier 1
delegationManager.revokeDelegation(tierOneDelegationHash);

// Grant Tier 2
bytes32 newHash = tierTwoPreset.createTierTwoDelegation(
    delegationManager,
    agentAddress,
    expandedSelectors
);
// New limits: $1,000/day, $500/tx, 5-min cooldown, reputation >= 70
```

**What to observe:** The old delegation is instantly revoked. The new Tier 2 delegation has higher caps. The agent can now execute the $200 swap.

`[Screenshot placeholder: Tier upgrade UI]`

### Step 8: Reputation Drop -- Execution Blocked

The agent's reputation score drops (simulated via the oracle) below the Tier 2 minimum of 70.

```solidity
// Reputation drops to 60 (simulated)
reputationOracle.reportNegative(agentAddress, action, 25);
// Agent score: 85 → 60

// Agent attempts to use Tier 2 delegation
delegationManager.redeemDelegation(delegation, calldata);
// ❌ ReputationGate: score 60 < 70 required
// → Transaction REVERTS with ReputationTooLow(agent, 60, 70)
```

**What to observe:** Even though the delegation was legitimately granted, the reputation enforcer blocks execution in real-time. No one manually revoked the delegation. The protocol itself detected the reputation change and blocked the agent. This is the novel contribution.

`[Screenshot placeholder: Reputation-based block with score visualization]`

### Step 9: User Revokes All Delegations

The user revokes all outstanding delegations in a single transaction.

```solidity
// User revokes all delegations
delegationManager.revokeDelegation(tierTwoDelegationHash);
// All agent access is immediately terminated
```

**What to observe:** Instant revocation. The agent has zero access to the wallet. Any subsequent attempt to redeem the delegation will revert.

`[Screenshot placeholder: Revocation confirmation with clean state]`

## Key Takeaways for Judges

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
| Demo app not connecting | Verify RPC URL and that Anvil fork is running |
| Reputation not updating | Ensure the oracle report transaction is confirmed before retesting |
