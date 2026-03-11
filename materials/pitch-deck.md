# Iris Protocol — Pitch Deck

## Slide 1: Title

**Iris Protocol**
Trustless Embedded Agent Wallets

*Every permission lives onchain.*

Built at The Synthesis | EthereumSF 2026
By Elliot — 67+ contracts deployed, $2B+ TVL secured, zero losses

---

## Slide 2: The Problem

**Your agent needs a wallet. Privy gives it one — but Privy holds the keys.**

| | Privy | Turnkey | Dynamic |
|---|---|---|---|
| Key storage | TEEs + Shamir shards | TEE enclaves | MPC + TEEs |
| Policy engine | Offchain | Offchain | Offchain |
| If provider is compromised | Agent wallet at risk | Agent wallet at risk | Agent wallet at risk |
| If provider shuts down | Keys potentially lost | Keys potentially lost | Keys potentially lost |

75M+ Privy accounts exist today. Every one of them trusts a company with their keys.

For AI agents moving real economic value, these trust assumptions are unacceptable.

---

## Slide 3: The Solution

**Iris: the wallet IS the policy engine.**

No TEEs. No key shards. No offchain policy.

- Smart contract account (ERC-4337) = the wallet
- ERC-7710 delegations = the permissions
- Caveat enforcers = the policy engine
- ERC-8004 = the identity and reputation layer

Everything enforceable is enforced by Ethereum.

*They trust hardware. We trust math.*

---

## Slide 4: Trust Tiers — Configure the Iris

**The iris metaphor: you dial how wide it opens.**

| Tier | Aperture | Autonomy | Controls |
|------|----------|----------|----------|
| **0** — View Only | Closed | Agent reads only | Human signs everything |
| **1** — Supervised | Narrow | $100/day autonomous | Spending cap, contract whitelist, time window, reputation gate |
| **2** — Autonomous | Wide | $10K/day, broader scope | + Single tx cap |
| **3** — Full Delegation | Open | Near-full authority | + Cooldown, higher reputation threshold, weekly cap |

Users pick a tier or customize. Adjust anytime. Revoke instantly.

---

## Slide 5: The Novel Piece — ReputationGateEnforcer

**The first caveat enforcer that reads ERC-8004's Reputation Registry to dynamically gate delegation.**

How it works:
1. Agent registered on ERC-8004 → gets reputation score
2. Delegation includes ReputationGateEnforcer with minimum threshold
3. On every execution: enforcer queries agent's live reputation score
4. If score dropped below threshold → execution blocked

**Why this matters:**
- Agent misbehaves → gets negative feedback → reputation drops → ALL delegations across ALL wallets degrade
- No wallet owner needs to manually revoke
- Network-level immune system for agent misbehavior

This is the application ERC-8004's authors envisioned but no one has built yet.

---

## Slide 6: Demo

**Live walkthrough: the full delegation lifecycle**

1. Agent registers on ERC-8004 → gets identity NFT
2. User creates Iris wallet → smart account with delegation support
3. Agent requests Tier 1 access → user sees scoped permission request
4. User approves → signs delegation with spending cap + whitelist + reputation gate
5. Agent executes $50 swap → caveats pass → success
6. Agent attempts $200 swap → spending cap blocks → queued for approval
7. User bumps to Tier 2 → higher autonomy bounds
8. Reputation drops → ReputationGateEnforcer blocks execution
9. User revokes all delegations → instant termination

All four hackathon themes covered:
- **Pay** → Scoped spending with onchain enforcement
- **Trust** → ERC-8004 identity + reputation-gated permissions
- **Cooperate** → Delegation chains (agents delegating to agents)
- **Keep Secrets** → Agent's own account shields user's main address

---

## Slide 7: Why Us

**Elliot**

- 67+ smart contracts deployed
- $2B+ TVL secured across protocols, zero losses
- Stanford Blockchain Review: blind signing vulnerability research
- DeFi Security Summit, SEAL contributor
- Founded Kleidi Wallet: smart contract vaults for high-net-worth self-custody

Iris applies production-grade security engineering to agent wallet infrastructure.

This isn't a hackathon toy. It's the foundation for how agents should hold value.

---

## Slide 8: What's Next

**Post-hackathon roadmap:**

1. **Open-source release** — Iris Protocol contracts as an audited, composable library
2. **MetaMask Delegation Toolkit integration** — ship as a first-party extension
3. **ERC-8004 reference applications** — reference implementations for the standard's authors
4. **SDK for agent developers** — `npm install @iris-protocol/sdk` with one-line delegation setup
5. **Multi-chain deployment** — Base (primary), Ethereum mainnet, L2s
6. **Agent framework integrations** — AgentKit, ElizaOS, LangChain plugins

**The thesis:** AI agents will move trillions onchain. The trust layer between humans and agents should be a smart contract, not a company.

---

## Appendix: Technical Architecture

See `materials/architecture.mmd` for the full system diagram.

### ERC Stack

| Standard | Role |
|----------|------|
| ERC-4337 | Smart contract accounts |
| ERC-7710 | Delegation with caveat enforcers |
| ERC-7715 | Permission request standard |
| ERC-8004 | Agent identity + reputation |
| ERC-8128 | Signed HTTP authentication |
| EIP-7702 | EOA upgrade path |
