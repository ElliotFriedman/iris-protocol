# Iris Protocol

> Privy, but trustless. Embedded agent wallets where every permission lives onchain.

Iris gives AI agents their own smart contract wallets with **configurable trust levels** enforced entirely onchain. No TEEs. No key custodians. No offchain policy engines. You configure the iris — from fully closed (human approves everything) to wide open (agent operates autonomously within bounds).

## The Problem

Embedded wallet providers (Privy, Turnkey, Dynamic) require trusting a company with key shards, TEEs, and offchain policy engines. For AI agents operating with real economic value, these trust assumptions are unacceptable. The alternative — giving agents raw private keys — is worse.

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│  Layer 4: Identity         IrisAgentRegistry             │
│                            IrisReputationOracle          │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Enforcement      SpendingCap │ Whitelist       │
│                            Selector │ TimeWindow         │
│                            SingleTxCap │ Cooldown        │
│                            ReputationGate (novel)        │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Delegation       IrisDelegationManager         │
│                            ERC-7710 + EIP-712            │
├─────────────────────────────────────────────────────────┤
│  Layer 1: Accounts         IrisAccount (ERC-4337)        │
│                            IrisAccountFactory (CREATE2)  │
└─────────────────────────────────────────────────────────┘
```

### Trust Tiers

| Tier | Name | Aperture | What the agent can do |
|------|------|----------|----------------------|
| 0 | View Only | Closed | Read balances, simulate transactions. Cannot execute. |
| 1 | Supervised | Narrow | Spend up to $X/day on whitelisted contracts within time window. Excess requires co-signature. |
| 2 | Autonomous | Wide | Higher caps, broader whitelist, reputation-gated. SingleTxCap + Cooldown enforced. |
| 3 | Full Delegation | Open | Maximum autonomy. Emergency revocation. Weekly spending cap. |

### ERC Stack

| Standard | Role in Iris |
|----------|-------------|
| **ERC-4337** | Agent wallets are smart contract accounts with UserOp execution |
| **ERC-7710** | Core permission primitive — delegations with caveat enforcers |
| **ERC-7715** | Standard for agents to request scoped permissions |
| **ERC-8004** | Agent identity + reputation registry |
| **ERC-8128** | Signed HTTP authentication for agents |
| **EIP-7702** | EOA upgrade path to smart accounts |

### The Novel Piece: ReputationGateEnforcer

A caveat enforcer that queries ERC-8004's Reputation Registry in real-time. If an agent's reputation drops below threshold, its delegations stop working — across all wallets. A network-level immune system for agent misbehavior.

```
Agent reputation drops → ReputationGateEnforcer blocks beforeHook
→ Delegation fails → All wallets with that agent are protected
→ No manual revocation needed
```

## Hyperstructure Properties

The core protocol (DelegationManager, Account, all caveat enforcers, AgentRegistry, ApprovalQueue) is a **hyperstructure**:

| Property | Status |
|----------|--------|
| **Unstoppable** | No pause/freeze mechanisms. Immutable contracts. |
| **Free** | Zero protocol fees on any operation. |
| **Permissionless** | Anyone can deploy accounts, register agents, create delegations. |
| **Credibly neutral** | No privileged actors in core protocol. |
| **No upgrades** | No proxy patterns. No delegatecall. No UUPS. |

**Trust assumption:** `IrisReputationOracle` uses `Ownable` — the oracle owner can submit feedback and add reviewers. This is the only centralization point, intentional for reputation bootstrapping. The core delegation enforcement is fully trustless.

## Demo

1. **Agent registers** on ERC-8004 Identity Registry → gets agentId NFT
2. **User creates an Iris wallet** → smart account with delegation support
3. **Agent requests Tier 1 access** → user sees: "Agent #4521 (reputation: 60/100) requests: spend up to $100/day on Uniswap only, valid 7 days"
4. **User approves** → signs ERC-7710 delegation with caveats
5. **Agent executes a $50 swap** → caveats pass → transaction succeeds
6. **Agent attempts a $200 swap** → SpendingCapEnforcer blocks → queued for approval
7. **User bumps agent to Tier 2** → new delegation with higher cap
8. **Reputation drop** → ReputationGateEnforcer blocks next execution
9. **User revokes** → instant termination

## Deployed Contracts

| Contract | Base Sepolia |
|----------|-------------|
| IrisDelegationManager | TBD |
| IrisAccountFactory | TBD |
| IrisAgentRegistry | TBD |
| IrisReputationOracle | TBD |
| SpendingCapEnforcer | TBD |
| ContractWhitelistEnforcer | TBD |
| FunctionSelectorEnforcer | TBD |
| TimeWindowEnforcer | TBD |
| SingleTxCapEnforcer | TBD |
| CooldownEnforcer | TBD |
| ReputationGateEnforcer | TBD |
| IrisApprovalQueue | TBD |

## Run Locally

```bash
git clone https://github.com/iris-protocol/iris-protocol
cd iris-protocol

# Build and test contracts
cd contracts
forge install && forge build && forge test

# Deploy to local Anvil
anvil &
forge script script/DeployLocal.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# Run E2E tests (TypeScript + viem against local Anvil)
cd ../e2e
./run.sh

# Run landing page
cd ../apps/landing
pnpm install && pnpm dev

# Run dashboard
cd ../apps/dashboard
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
│   │   ├── caveats/
│   │   │   ├── SpendingCapEnforcer.sol
│   │   │   ├── ContractWhitelistEnforcer.sol
│   │   │   ├── FunctionSelectorEnforcer.sol
│   │   │   ├── TimeWindowEnforcer.sol
│   │   │   ├── SingleTxCapEnforcer.sol
│   │   │   ├── CooldownEnforcer.sol
│   │   │   └── ReputationGateEnforcer.sol  # Novel contribution
│   │   ├── identity/
│   │   │   ├── IrisAgentRegistry.sol       # ERC-8004 identity
│   │   │   └── IrisReputationOracle.sol    # Reputation scores
│   │   ├── presets/
│   │   │   ├── TierOne.sol                 # Supervised preset
│   │   │   ├── TierTwo.sol                 # Autonomous preset
│   │   │   └── TierThree.sol              # Full delegation preset
│   │   └── deployers/
│   │       └── IrisDeployer.sol            # Shared deployment fixture
│   ├── test/                               # 158 tests, 0 failures
│   │   ├── integration/                    # 7 integration test suites
│   │   └── helpers/
│   │       └── IrisTestBase.sol            # Shared test base (uses IrisDeployer)
│   └── script/
│       ├── Deploy.s.sol                    # Production deploy (uses IrisDeployer)
│       ├── DeployLocal.s.sol               # Local Anvil deploy
│       └── Demo.s.sol                      # Demo script
├── apps/
│   ├── landing/                            # Next.js landing page
│   └── dashboard/                          # Next.js dashboard
├── e2e/                                    # E2E tests (viem + vitest + Anvil)
└── docs/                                   # Docusaurus documentation
```

## Architecture Decisions

**Shared deployment fixture:** `IrisDeployer.sol` is used by both deploy scripts and integration tests, guaranteeing tests exercise the exact same deployment path as mainnet.

**Composable caveats:** All 7 caveat enforcers are independent, stateless (except SpendingCap and Cooldown which track per-delegation state), and compose via AND-logic. Any combination works.

**No token:** Iris has no governance token. Pure infrastructure.

## Built With

Base | MetaMask Delegation Toolkit (ERC-7710) | ERC-8004 Registry | Foundry | OpenZeppelin

## Team

**Elliot** — Smart contract engineer. 67+ contracts deployed, $2B+ TVL secured, zero losses. Stanford Blockchain Review. Founder, Kleidi Wallet.
