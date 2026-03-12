# Iris Protocol

**Privy, but trustless. Embedded agent wallets where every permission lives onchain.**

![Solidity 0.8.28](https://img.shields.io/badge/Solidity-0.8.28-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C)
![Tests](https://img.shields.io/badge/tests-233-brightgreen)
![Halmos](https://img.shields.io/badge/Halmos%20proofs-74-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

---

## The Problem

Embedded wallet providers -- Privy, Turnkey, Coinbase -- solve onboarding but introduce a custodian. The agent's private key lives on someone else's infrastructure, secured by a service agreement rather than cryptography. When an agent needs to spend money, the user must either trust a company with their keys or lock the agent out entirely.

This is not a theoretical concern. 42% of consumers fear losing control over AI agent purchases. 97% of CFOs understand the value of agent autonomy, but only 11% are testing it in production. The bottleneck is not capability -- it is trust. There is no onchain mechanism to grant an agent limited, enforceable, revocable authority without handing over a private key.

## The Solution

Iris Protocol replaces custodial key management with smart contract accounts (ERC-4337) and onchain delegation (ERC-7710). A user deploys an `IrisAccount`, then signs a delegation granting an agent specific permissions -- spending caps, contract whitelists, time windows, reputation thresholds -- all encoded as composable caveat enforcers. No custodian holds the key. No admin can freeze the account. Every permission is verifiable onchain and revocable by the delegator at any time.

## Trust Tiers

Agents start restricted and graduate through onchain reputation.

| Tier | Name | Caveats | Limits | Min Reputation |
|------|------|---------|--------|----------------|
| **0** | View Only | -- | Read state only, no execution | -- |
| **1** | Supervised | SpendingCap, ContractWhitelist, TimeWindow, ReputationGate | $100/day, approved contracts only | 50 |
| **2** | Autonomous | SpendingCap, ContractWhitelist, TimeWindow, ReputationGate, SingleTxCap | $1,000/day, broader contract access | 75 |
| **3** | Full Delegation | SpendingCap, ContractWhitelist, TimeWindow, ReputationGate, SingleTxCap, Cooldown | $10,000/week, per-tx caps, cooldown periods | 90 |

Higher tiers grant more autonomy but demand higher reputation and stack more enforcers. Trust is earned, not assumed.

## Defense in Depth: 7 Caveat Enforcers

Every delegated execution must pass through all caveats attached to the delegation. These enforcers are composable -- stack them to define arbitrary permission boundaries.

1. **SpendingCapEnforcer** -- Tracks cumulative spend over a rolling time window (daily or weekly). Reverts if the agent exceeds its budget.
2. **SingleTxCapEnforcer** -- Caps the ETH value of any individual transaction. Prevents single catastrophic transfers.
3. **ContractWhitelistEnforcer** -- Restricts which contract addresses the agent may call. Limits the agent's attack surface.
4. **FunctionSelectorEnforcer** -- Restricts which function selectors the agent may invoke. Enforces operation-level granularity.
5. **TimeWindowEnforcer** -- Enforces a validity window with start and end timestamps. Delegations expire automatically.
6. **CooldownEnforcer** -- Requires a minimum delay between high-value executions. Prevents rapid-fire drain attacks.
7. **ReputationGateEnforcer** -- Queries a live ERC-8004 reputation score and blocks agents below threshold. The novel contribution described below.

## Novel Contribution: ReputationGateEnforcer

The core innovation of Iris Protocol is the `ReputationGateEnforcer` -- the first caveat enforcer that creates a dynamic trust boundary using live ERC-8004 reputation scores.

Traditional access control is binary: an agent either has permission or it does not. Revoking a compromised agent requires the delegator to notice the problem and manually submit a revocation transaction. This fails at scale -- a user managing ten agents across five protocols cannot monitor them all.

The `ReputationGateEnforcer` inverts this model. At execution time, it queries an ERC-8004 Reputation Registry (the standard created by Davide Crapis and the EF dAI team) for the agent's current score. If the score has dropped below the threshold encoded in the delegation's terms, execution reverts -- no human intervention required. The enforcer is stateless: it holds no mappings and writes no storage. It performs a single `staticcall` to the oracle, keeping gas costs minimal and composability intact.

This produces a self-healing property. When an agent misbehaves, its reputation drops via oracle feedback. That drop propagates instantly across every delegation that references the `ReputationGateEnforcer` -- not just the delegation where the misbehavior occurred, but all of them. The network's immune system activates automatically. The oracle address is encoded in `terms` rather than the constructor, so a single enforcer deployment can serve multiple reputation registries across different domains.

## Architecture

```
                        ┌───────────────────┐
                        │    Human Owner     │
                        │   (EOA / Signer)   │
                        └────────┬──────────┘
                                 │ signs EIP-712 delegation
                                 ▼
                        ┌───────────────────┐
                        │    IrisAccount     │
                        │  (ERC-4337 Smart   │
                        │   Account)         │
                        └────────┬──────────┘
                                 │ delegationManager()
                                 ▼
                   ┌─────────────────────────────┐
                   │   IrisDelegationManager      │
                   │                              │
                   │  - validates EIP-712 sigs    │
                   │  - walks delegation chains   │
                   │  - calls beforeHook/afterHook│
                   └──────────┬───────────────────┘
                              │
              ┌───────────────┼───────────────────┐
              ▼               ▼                   ▼
     ┌──────────────┐ ┌──────────────┐   ┌──────────────────┐
     │ SpendingCap  │ │ TimeWindow   │   │ ReputationGate   │
     │ Enforcer     │ │ Enforcer     │   │ Enforcer         │
     └──────────────┘ └──────────────┘   └────────┬─────────┘
     ┌──────────────┐ ┌──────────────┐            │
     │ SingleTxCap  │ │ Cooldown     │            │ staticcall
     │ Enforcer     │ │ Enforcer     │            ▼
     └──────────────┘ └──────────────┘   ┌──────────────────┐
     ┌──────────────┐ ┌──────────────┐   │  IrisReputation  │
     │ Contract     │ │ Function     │   │  Oracle          │
     │ Whitelist    │ │ Selector     │   │  (ERC-8004)      │
     └──────────────┘ └──────────────┘   └──────────────────┘
```

## Quick Start

```bash
git clone https://github.com/ElliotFriedman/iris-protocol.git
cd iris-protocol/contracts
forge install
forge build
forge test -vvv
```

## Project Structure

```
iris-protocol/
├── contracts/              # Foundry project (Solidity 0.8.28)
│   ├── src/                # 22 source contracts
│   │   ├── IrisAccount.sol           # ERC-4337 smart account + ERC-7710 delegator
│   │   ├── IrisDelegationManager.sol # Delegation lifecycle + caveat orchestration
│   │   ├── caveats/                  # 7 composable caveat enforcers
│   │   ├── identity/                 # ERC-8004 agent registry + reputation oracle
│   │   ├── presets/                  # Trust tier presets (Tier 1-3)
│   │   └── deployers/               # Shared deployment fixtures
│   ├── test/               # 233 tests
│   │   ├── formal/         # 74 Halmos symbolic proofs (10 suites)
│   │   └── integration/    # 7 integration test suites
│   └── script/             # Deployment scripts
├── apps/
│   ├── dashboard/          # Next.js agent management UI
│   └── landing/            # Next.js landing page
└── docs/                   # Technical documentation
```

## Security

- **233 tests** across unit, integration, and multi-agent scenarios
- **74 Halmos symbolic proofs** across 10 formal verification suites with non-vacuity checks
- **TOCTOU vulnerability** identified and fixed in SpendingCap/CooldownEnforcer interaction
- **4 defense layers**: Account -> Delegation -> Caveat -> Reputation
- **Hyperstructure**: no pause functions, no admin keys, no proxy upgradeability, no fees

## Standards

| Standard | Role | Origin |
|----------|------|--------|
| [ERC-7710](https://eips.ethereum.org/EIPS/eip-7710) | Onchain delegation framework | MetaMask Delegation Framework |
| [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) | Agent identity and reputation | EF dAI team (Davide Crapis) |
| [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) | Account abstraction | Ethereum |
| [EIP-712](https://eips.ethereum.org/EIPS/eip-712) | Typed structured data signing | Ethereum |

## Built With

- [Foundry](https://book.getfoundry.sh/) -- build, test, and deploy
- [Solidity 0.8.28](https://docs.soliditylang.org/) -- smart contract language
- [MetaMask Delegation Toolkit](https://github.com/MetaMask/delegation-framework) -- ERC-7710 reference
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) -- ECDSA, EIP-712, ReentrancyGuard
- [Halmos](https://github.com/a16z/halmos) -- symbolic execution for formal verification

## License

MIT

---

Built for [The Synthesis](https://synthesis.md/) 2026 by **Elliot** -- smart contract security and infrastructure. 67+ contracts deployed, $2B+ TVL secured, 0 security incidents.
