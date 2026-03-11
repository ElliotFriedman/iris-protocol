---
sidebar_position: 2
title: Getting Started
---

# Getting Started

Iris Protocol runs locally in under five minutes with Foundry and Node.js.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Foundry | Latest | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| Node.js | 18+ | [nodejs.org](https://nodejs.org) |
| pnpm | 8+ | `npm install -g pnpm` |
| Git | Any | Pre-installed on most systems |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/iris-protocol/iris-protocol.git
cd iris-protocol

# Build and test contracts
cd contracts
forge install && forge build && forge test

# Run tests with verbosity
forge test -vvv
```

## Deploy to Local Anvil

```bash
# Start a local Anvil node
anvil &

# Deploy all contracts
forge script script/DeployLocal.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## Deploy to Base Sepolia

```bash
# Deploy to Base Sepolia testnet
cd contracts
forge script script/Deploy.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY
```

## Run E2E Tests

```bash
# From the project root
cd e2e
./run.sh
# Starts Anvil, deploys contracts, runs 18 E2E tests via vitest
```

## Run Frontend Apps

```bash
# Landing page
cd apps/landing
pnpm install && pnpm dev

# Dashboard
cd apps/dashboard
pnpm install && pnpm dev
```

## Project Structure

```
iris-protocol/
├── contracts/                    # Foundry project
│   ├── src/
│   │   ├── IrisAccount.sol               # ERC-4337 smart account
│   │   ├── IrisAccountFactory.sol        # CREATE2 factory
│   │   ├── IrisDelegationManager.sol     # ERC-7710 delegation lifecycle
│   │   ├── IrisApprovalQueue.sol         # Approval queue for over-limit txs
│   │   ├── caveats/                      # 7 caveat enforcers
│   │   │   ├── SpendingCapEnforcer.sol
│   │   │   ├── ContractWhitelistEnforcer.sol
│   │   │   ├── FunctionSelectorEnforcer.sol
│   │   │   ├── TimeWindowEnforcer.sol
│   │   │   ├── SingleTxCapEnforcer.sol
│   │   │   ├── CooldownEnforcer.sol
│   │   │   └── ReputationGateEnforcer.sol
│   │   ├── identity/
│   │   │   ├── IrisAgentRegistry.sol     # ERC-8004 identity
│   │   │   └── IrisReputationOracle.sol  # Reputation scores
│   │   ├── presets/
│   │   │   ├── TierOne.sol               # Supervised (4 caveats)
│   │   │   ├── TierTwo.sol               # Autonomous (5 caveats)
│   │   │   └── TierThree.sol             # Full delegation (6 caveats)
│   │   └── deployers/
│   │       └── IrisDeployer.sol          # Shared deployment fixture
│   ├── test/
│   │   ├── integration/                  # Integration test suites
│   │   └── helpers/
│   │       └── IrisTestBase.sol          # Shared test base
│   └── script/
│       ├── Deploy.s.sol                  # Production deploy
│       ├── DeployLocal.s.sol             # Local Anvil deploy
│       └── Demo.s.sol                    # Demo script
├── apps/
│   ├── landing/                          # Next.js landing page
│   └── dashboard/                        # Next.js dashboard
├── e2e/                                  # E2E tests (viem + vitest + Anvil)
└── docs/                                 # Docusaurus documentation
```

## Environment Variables

Create a `.env` file in the `contracts/` directory:

```bash
# RPC
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

# Deployer
DEPLOYER_PRIVATE_KEY=0x...

# Verification
BASESCAN_API_KEY=...
```

For frontend apps, create `.env.local` in each app directory:

```bash
NEXT_PUBLIC_RPC_URL=https://sepolia.base.org
NEXT_PUBLIC_CHAIN_ID=84532
```

## Next Steps

- Read the [Architecture](./architecture.md) overview to understand how the protocol works
- Explore [Trust Tiers](./trust-tiers.md) to understand the permission model
- Review the [Contract documentation](./contracts/overview.md) for technical details
- Follow the [Demo Guide](./demo-guide.md) to walk through the full demo flow
