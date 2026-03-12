# Architecture

Iris Protocol is a four-layer stack. Each layer is independently useful, but together they form a complete trust infrastructure for AI agent wallets.

```
Layer 4: Identity        IrisAgentRegistry (ERC-8004) + IrisReputationOracle
Layer 3: Enforcement     7 caveat enforcers (AND-composed per delegation)
Layer 2: Delegation      IrisDelegationManager (ERC-7710 + EIP-712)
Layer 1: Accounts        IrisAccount (ERC-4337) + IrisAccountFactory (CREATE2)
```

## Layer 1: Smart Accounts

`IrisAccount` is an ERC-4337 smart contract account. It validates UserOperations via the canonical EntryPoint (v0.7), supports ERC-7710 delegation redemption, and allows the owner to revoke delegations.

`IrisAccountFactory` deploys accounts deterministically via CREATE2, enabling counterfactual addresses.

## Layer 2: Delegation

`IrisDelegationManager` implements the ERC-7710 delegation lifecycle: creation (offchain EIP-712 signatures), redemption (onchain chain validation with caveat enforcement), and revocation (permanent, monotonic). Delegations can be chained — caveats are enforced on **every** delegation in the chain, not just the leaf.

## Layer 3: Caveat Enforcers

Seven independent enforcers compose via AND-logic on each delegation:

| Enforcer | State | What it enforces |
|----------|-------|-----------------|
| SpendingCapEnforcer | Stateful | Cumulative spend per rolling period |
| ContractWhitelistEnforcer | Stateless | Target address must be in whitelist |
| FunctionSelectorEnforcer | Stateless | Function selector must be in allowed set |
| TimeWindowEnforcer | Stateless | Execution only within [notBefore, notAfter] |
| SingleTxCapEnforcer | Stateless | Per-transaction value ceiling |
| CooldownEnforcer | Stateful | Minimum delay between executions |
| ReputationGateEnforcer | Stateless | Queries ERC-8004 reputation at execution time |

Stateful enforcers (`SpendingCap`, `Cooldown`) verify `msg.sender == delegationManager` before mutating state.

**ReputationGateEnforcer** is the novel contribution. It reads the agent's reputation score at execution time — not at delegation creation. If reputation degrades after a delegation is granted, the enforcer blocks execution automatically. No manual revocation needed.

## Layer 4: Identity

`IrisAgentRegistry` (ERC-8004) provides onchain agent identity. Each agent gets an NFT-based identity with metadata URI.

`IrisReputationOracle` maintains reputation scores (0-100, default 50). Authorized reviewers submit positive (+2) or negative (-5) feedback. The asymmetric penalty makes reputation hard to game.

## Trust Tiers

Pre-configured caveat combinations that map to human-interpretable trust levels:

- **Tier 0 (View Only):** No execution. Human signs everything.
- **Tier 1 (Supervised):** SpendingCap + ContractWhitelist + TimeWindow + ReputationGate (4 caveats)
- **Tier 2 (Autonomous):** Tier 1 + SingleTxCap (5 caveats)
- **Tier 3 (Full Delegation):** Tier 2 + Cooldown, weekly cap, higher reputation threshold (6 caveats)

## Key Design Decisions

- **No proxy patterns.** All contracts are immutable after deployment.
- **No protocol fees.** Zero rent-seeking on any operation.
- **Shared deployment fixture.** `IrisDeployer.sol` is used by both deploy scripts and tests, guaranteeing identical deployment paths.
- **Formal verification.** 74 Halmos symbolic proofs covering all enforcers, the delegation manager, and the account contract.

## Detailed Documentation

See [`docs/`](./docs/) for full contract reference, API docs, and demo guide.
