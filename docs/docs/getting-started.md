---
sidebar_position: 2
title: Getting Started
---

# Getting Started

Get Iris Protocol running locally in under five minutes.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Foundry | Latest | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| Node.js | 18+ | [nodejs.org](https://nodejs.org) |
| Git | Any | Pre-installed on most systems |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/iris-protocol/iris-protocol.git
cd iris-protocol

# Install Foundry dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with verbosity
forge test -vvv
```

## Deploy to Local Fork

```bash
# Start a local fork of Base Sepolia
anvil --fork-url $BASE_SEPOLIA_RPC_URL

# In a new terminal, deploy all contracts
forge script script/Deploy.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key $DEPLOYER_PRIVATE_KEY
```

## Deploy to Base Sepolia

```bash
# Deploy to Base Sepolia testnet
forge script script/Deploy.s.sol \
    --rpc-url $BASE_SEPOLIA_RPC_URL \
    --broadcast \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY
```

## Launch Demo App

```bash
# Install demo dependencies
cd demo && npm install

# Configure environment
cp .env.example .env
# Edit .env with your deployed contract addresses and RPC URL

# Start the demo
npm run dev
```

The demo app will be available at `http://localhost:3000`.

## Project Structure

```
iris-protocol/
├── src/                          # Solidity contracts
│   ├── IrisAccount.sol           # ERC-4337 smart contract wallet
│   ├── IrisAccountFactory.sol    # Deterministic account factory
│   ├── DelegationManager.sol     # ERC-7710 delegation orchestrator
│   ├── enforcers/                # Caveat enforcer contracts
│   │   ├── SpendingCapEnforcer.sol
│   │   ├── ContractWhitelistEnforcer.sol
│   │   ├── FunctionSelectorEnforcer.sol
│   │   ├── TimeWindowEnforcer.sol
│   │   ├── ReputationGateEnforcer.sol
│   │   ├── SingleTxCapEnforcer.sol
│   │   └── CooldownEnforcer.sol
│   ├── identity/                 # ERC-8004 identity contracts
│   │   ├── IrisAgentRegistry.sol
│   │   └── IrisReputationOracle.sol
│   └── presets/                  # Trust tier presets
│       ├── TierOnePreset.sol
│       ├── TierTwoPreset.sol
│       └── TierThreePreset.sol
├── test/                         # Foundry tests
├── script/                       # Deployment scripts
├── demo/                         # Demo application
├── docs/                         # This documentation site
└── foundry.toml                  # Foundry configuration
```

## Environment Variables

Create a `.env` file in the project root:

```bash
# RPC
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

# Deployer
DEPLOYER_PRIVATE_KEY=0x...

# Verification
BASESCAN_API_KEY=...

# Demo App
NEXT_PUBLIC_RPC_URL=https://sepolia.base.org
NEXT_PUBLIC_CHAIN_ID=84532
```

## Next Steps

- Read the [Architecture](./architecture.md) overview to understand how the protocol works
- Explore [Trust Tiers](./trust-tiers.md) to understand the permission model
- Review the [Contract documentation](./contracts/overview.md) for technical details
- Follow the [Demo Guide](./demo-guide.md) to walk through the full demo flow
