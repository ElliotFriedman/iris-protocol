# Iris Protocol — Twitter Thread

**Target: 10 tweets. Post after submission on March 22.**

---

**1/10 — Hook**

We built the first fully trustless embedded wallet for AI agents.

No TEEs. No key custodians. No offchain policy engines. Just smart contracts.

Introducing Iris Protocol.

🧵

---

**2/10 — The problem**

Privy powers 75M+ embedded wallets. Hyperliquid, pump.fun, Blackbird.

But your keys are sharded across Privy's infrastructure using Shamir's Secret Sharing + TEEs.

If Privy gets compromised, your agent's wallet is compromised.

For AI agents moving real money, that's not good enough.

---

**3/10 — The solution**

Iris = smart contract accounts + ERC-7710 delegations + onchain caveat enforcers.

The wallet IS the policy engine. The permissions ARE smart contracts.

No company holds your keys. The Ethereum network IS the infrastructure.

They trust hardware. We trust math.

---

**4/10 — Trust tiers**

You configure the iris — like a camera aperture:

Closed → Agent reads only, human signs everything
Narrow → Agent spends up to $100/day autonomously
Wide → Broader bounds, reputation-gated
Open → Full delegation with emergency revocation

Adjust anytime. Revoke instantly.

---

**5/10 — The novel piece**

ReputationGateEnforcer: a caveat enforcer that queries ERC-8004's Reputation Registry in real-time.

Agent's reputation drops below threshold → permissions degrade across ALL wallets.

No manual revocation needed. A network-level immune system for agent misbehavior.

---

**6/10 — How it works**

1. Agent registers on ERC-8004 (gets identity NFT)
2. User creates Iris wallet (ERC-4337 smart account)
3. User signs delegation: "spend up to $100/day on Uniswap only, for 7 days"
4. Agent executes within bounds → success
5. Agent exceeds bounds → blocked, queued for approval
6. Reputation drops → all delegations degrade

---

**7/10 — The ERC stack**

Built on the standards the judges authored:

- ERC-4337: Smart accounts
- ERC-7710: Delegation + caveats (Dan Finlay / MetaMask)
- ERC-8004: Agent identity + reputation (Davide Crapis / EF)
- ERC-7715: Permission requests
- ERC-8128: Signed HTTP auth

Standards-native. Composable with existing infra.

---

**8/10 — Why this matters**

AI agents will move trillions onchain.

The trust layer between you and your agent shouldn't be:
- A company holding key shards
- A TEE you can't verify
- An offchain policy engine you can't audit

It should be a smart contract. Onchain. Verifiable. Yours.

---

**9/10 — Built by**

Elliot — smart contract engineer
- 67+ contracts deployed
- $2B+ TVL secured, zero losses
- Stanford Blockchain Review
- Founder, Kleidi Wallet

Production-grade security engineering applied to agent infrastructure.

---

**10/10 — Try it**

Built at @synthesis_md for EthereumSF 2026.

[GitHub repo link]
[Devfolio submission link]
[Demo video link]

@base @MetaMask @selfaboratorprotocol @Uniswap

The iris is open.
