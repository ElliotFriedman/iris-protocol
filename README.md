# Iris Protocol

**Trustless payment infrastructure for AI agents.**

Onchain embedded wallets with ERC-7710 delegation, configurable trust tiers, and reputation-gated permissions via ERC-8004.

> "Every competitor gives agents a wallet. Iris Protocol gives them a leash — one that loosens as they prove themselves trustworthy."

## The Problem

AI agents need to transact, but today's options are broken:
- **Full wallet access** — catastrophic risk ($47K lost to one recursive agent loop)
- **Locked out entirely** — agents can't do their job
- **Custodial wallets** (Privy, Turnkey) — trust a company with your keys

42% of consumers fear losing control over AI purchases. 97% of CFOs understand agent autonomy — only 11% are testing it. **Trust is the bottleneck.**

## The Solution

Iris Protocol creates a middle ground: **delegated authority with enforceable limits.**

Agents get onchain wallets with smart contract-enforced permissions. No custodian. No admin keys. Every permission verifiable onchain.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Human Owner                     │
│              (ERC-4337 Smart Account)             │
└──────────────────────┬──────────────────────────┘
                       │ ERC-7710 Delegation
                       ▼
┌─────────────────────────────────────────────────┐
│              IrisDelegationManager                │
│         (validates signatures + caveats)          │
└──────────────────────┬──────────────────────────┘
                       │ Caveat Enforcement
                       ▼
┌─────────────────────────────────────────────────┐
│            7 Caveat Enforcers (composable)        │
│  ┌────────────┐ ┌────────────┐ ┌──────────────┐ │
│  │ SpendingCap│ │SingleTxCap │ │ContractWhite-│ │
│  │            │ │            │ │  list        │ │
│  └────────────┘ └────────────┘ └──────────────┘ │
│  ┌────────────┐ ┌────────────┐ ┌──────────────┐ │
│  │FunctionSel-│ │ TimeWindow │ │  Cooldown    │ │
│  │  ector     │ │            │ │              │ │
│  └────────────┘ └────────────┘ └──────────────┘ │
│  ┌──────────────────────────────────────────────┐│
│  │     ReputationGateEnforcer (ERC-8004)        ││
│  │     "Network-level immune system"            ││
│  └──────────────────────────────────────────────┘│
└──────────────────────┬──────────────────────────┘
                       │ Authorized Action
                       ▼
┌─────────────────────────────────────────────────┐
│                  AI Agent                         │
│         (operates within delegation scope)        │
└─────────────────────────────────────────────────┘
```

## Trust Tiers

| Tier | Name | Iris State | Permissions | Use Case |
|------|------|-----------|-------------|----------|
| 0 | View Only | Closed | Read state, no execution | Monitoring |
| 1 | Supervised | Narrow | $100/day, approved contracts, reputation >= 50 | Shopping agents |
| 2 | Autonomous | Wide | $1,000/day, broader access, reputation >= 75 | DeFi agents |
| 3 | Full Delegation | Open | $10,000/week, max autonomy, reputation >= 90 | Enterprise agents |

**Trust is earned, not assumed.** Agents start restricted and graduate through onchain reputation.

## Standards

| Standard | Role | Origin |
|----------|------|--------|
| [ERC-7710](https://eips.ethereum.org/EIPS/eip-7710) | Onchain delegation framework | MetaMask |
| [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) | Agent identity and reputation | EF dAI team |
| [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) | Account abstraction | Ethereum |
| [EIP-712](https://eips.ethereum.org/EIPS/eip-712) | Typed data signing | Ethereum |

## Novel Contribution: ReputationGateEnforcer

The first caveat enforcer that queries live ERC-8004 reputation scores at execution time. When an agent misbehaves:

1. Reputation drops via oracle feedback
2. ALL delegations using ReputationGateEnforcer auto-block the agent
3. No manual revocation required
4. Network heals itself

**A self-healing trust network at the protocol level.**

## Security

- **152 tests** across unit, integration, and multi-agent scenarios
- **53 symbolic proofs** via Halmos formal verification across 10 test suites
- **TOCTOU vulnerability** identified and fixed in SpendingCap/CooldownEnforcer
- **4 defense layers**: Account -> Delegation -> Caveat -> Reputation
- **Hyperstructure**: no pause, no fees, no admin keys, no proxies

## Project Structure

```
iris-protocol/
├── contracts/           # Foundry project (Solidity 0.8.28)
│   ├── src/             # 22 source contracts
│   │   ├── caveats/     # 7 composable caveat enforcers
│   │   ├── identity/    # ERC-8004 agent registry + reputation oracle
│   │   ├── presets/     # Trust tier presets (Tier 1-3)
│   │   └── deployers/   # Shared deployment fixture
│   ├── test/            # 152 tests (unit + integration + formal)
│   │   ├── formal/      # 53 Halmos symbolic proofs (10 suites)
│   │   └── integration/ # 7 integration test suites
│   └── script/          # Deployment scripts
├── apps/
│   ├── dashboard/       # Next.js agent management UI
│   └── landing/         # Next.js landing page + pitch deck
├── docs/                # Docusaurus documentation
└── e2e/                 # End-to-end tests (viem + vitest + Anvil)
```

## Quick Start

```bash
# Clone
git clone --recursive https://github.com/ElliotFriedman/iris-protocol.git
cd iris-protocol

# Build contracts
cd contracts && forge build

# Run tests
forge test -vvv

# Start dashboard
cd ../apps/dashboard && pnpm install && pnpm dev

# Start landing page
cd ../apps/landing && pnpm install && pnpm dev
```

## Links

- [Demo Dashboard](./apps/dashboard/) — Configure trust tiers and manage agent delegations
- [Landing Page](./apps/landing/) — Project overview and pitch deck at /deck
- [Documentation](./docs/) — Full technical docs
- [Contracts](./contracts/src/) — Solidity source code

## Hackathon Tracks

**Agents that Pay** — Transparent scoping of agent spending, verification that spending is correct, settlement without middlemen.

**Agents that Trust** — Decentralized identity for entities without faces. ERC-8004 agent identity can't be revoked by a centralized provider.

## Built by

**Elliot** — Smart contract security and infrastructure. 67+ contracts deployed, $2B+ TVL secured, 0 security incidents. Stanford Blockchain Review contributor.

---

*Built for [The Synthesis](https://synthesis.md/) 2026*
