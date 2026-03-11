# Iris Protocol — One-Pager

## Privy, but trustless. Embedded agent wallets where every permission lives onchain.

---

### The Problem

AI agents need wallets. Today's embedded wallet providers (Privy, Turnkey, Dynamic) shard private keys across TEEs and company infrastructure. If the provider is compromised, shut down, or changes terms — the agent's wallet is at risk. For agents moving real economic value, trusting a company with key management is an unacceptable design choice.

### The Solution

Iris Protocol gives every AI agent a smart contract wallet (ERC-4337) with configurable trust levels enforced entirely onchain. No TEEs. No key custodians. No offchain policy engines.

**How it works:**
- The wallet owner signs an ERC-7710 delegation granting the agent scoped permissions
- Caveat enforcers (spending caps, contract whitelists, time windows, function selectors) validate every execution onchain
- The agent's identity and reputation are registered via ERC-8004
- A novel ReputationGateEnforcer queries the agent's live reputation score — if it drops below threshold, permissions degrade across all wallets automatically

### Trust Tiers

| Tier | Name | Agent Autonomy |
|------|------|---------------|
| 0 | View Only | Agent reads, human signs everything |
| 1 | Supervised | Up to $X/day, whitelisted contracts only |
| 2 | Autonomous | Higher bounds, reputation-gated access |
| 3 | Full Delegation | Maximum autonomy, emergency revocation |

### What's Novel

**ReputationGateEnforcer** — the first caveat enforcer that reads ERC-8004's Reputation Registry to dynamically gate delegation. Agent misbehaves anywhere on the network → reputation drops → permissions degrade across all wallets that delegated to it. A network-level immune system for agent misbehavior.

### Technical Stack

| Standard | Role |
|----------|------|
| ERC-4337 | Smart contract accounts |
| ERC-7710 | Delegation with caveat enforcers |
| ERC-8004 | Agent identity + reputation |
| ERC-7715 | Permission requests |
| ERC-8128 | Signed HTTP authentication |

Deployed on Base. Built with Foundry. Composable with MetaMask Delegation Toolkit.

### Builder

**Elliot** — Smart contract engineer. 67+ contracts deployed, $2B+ TVL secured, zero losses. Stanford Blockchain Review. DeFi Security Summit. Founder, Kleidi Wallet.

### Links

- GitHub: [repo]
- Demo: [video]
- Devfolio: [submission]

---

*Built at The Synthesis | EthereumSF 2026*
