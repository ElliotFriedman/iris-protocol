# Talking Points — The Synthesis 2026

## Elevator Pitch (30 seconds)
Iris Protocol is trustless payment infrastructure for AI agents. Instead of giving agents full wallet access or locking them out entirely, we use ERC-7710 delegation with 7 composable caveat enforcers to create configurable trust tiers. Agents start restricted and earn autonomy through onchain reputation via ERC-8004. No custodian. No admin keys. Every permission lives onchain.

## Competitive Differentiation

### vs. Privy (acquired by Stripe)
"Privy gives agents wallets controlled by a company. Iris Protocol gives agents delegated permissions controlled by smart contracts. If Privy goes down, agent wallets are inaccessible. Iris Protocol works as long as the chain is live."

### vs. Coinbase AgentKit
"AgentKit locks you into the Coinbase ecosystem. Iris Protocol is built on open ERC standards — any wallet, any chain, any agent framework can integrate."

### vs. Safe (Gnosis)
"Safe requires multiple signers per transaction — heavy for autonomous agents. Iris Protocol pre-authorizes scoped actions via delegation, so agents operate independently within defined boundaries."

### vs. Turnkey
"Turnkey's policies are enforced off-chain by their servers. Iris Protocol's caveats are enforced on-chain by smart contracts. One requires trust; the other doesn't."

### vs. Lit Protocol
"Lit provides programmable keys but no delegation framework, no trust tiers, no reputation system. Iris Protocol combines all three on open standards."

## Judge-Specific Angles

### If Davide Crapis (EF dAI) is judging:
"We implement ERC-8004 for agent identity and reputation. The ReputationGateEnforcer queries the ERC-8004 registry in real-time — if an agent's reputation drops below the threshold, all its delegations are blocked automatically. It's a network-level immune system built on your standard."

### If Illia Polosukhin (NEAR) is judging:
"This is pure infrastructure — no token, no speculation. Practical tooling that any agent framework can use today. Your thesis that 'AI is the front end, blockchain is the back end' is exactly what we've built."

### If Austin Griffith (EF dev/acc) is judging:
"Built with Foundry, 158 passing tests, open source. ERC-7710 delegation from MetaMask's framework, composed with ERC-8004. It's scaffold-eth energy applied to agent infrastructure."

### If Tomasz Stanczak (Nethermind) is judging:
"158 tests, TOCTOU vulnerability found and fixed, defense in depth with 7 independent caveat enforcers. This is institutional-grade infrastructure, not a hackathon prototype."

## Market Data
- Agentic AI market: $7.29B (2025) → $139.19B (2034) at 40.5% CAGR
- 42% of consumers fear losing control over AI purchases
- 97% of CFOs understand agent autonomy, only 11% testing it — trust is the bottleneck
- $40B projected US fraud losses by 2027 from generative AI
- 49,400+ agents registered via ERC-8004 on mainnet
- Consumers only comfortable with AI spending up to $233 autonomously

## Hard Questions

**"Is this just a hackathon project?"**
"158 tests, TOCTOU fix, 7 caveat enforcers, hyperstructure design (no admin keys, no pause, no fees). The security posture says otherwise."

**"Who's the team?"**
"Solo founder. Previously secured $2B+ TVL across 67+ contract deployments with zero security incidents. Stanford Blockchain Review contributor."

**"Why not just use a multisig?"**
"Multisigs require human approval for every transaction. That defeats the purpose of autonomous agents. Iris Protocol pre-authorizes bounded actions — the agent operates freely within its delegation scope."

**"What if the reputation oracle is compromised?"**
"The oracle owner can add reviewers, but scores are based on verifiable onchain history. The oracle is one layer of seven — even if bypassed, spending caps, time windows, and contract whitelists still protect the delegator."

**"Why Ethereum? Why not Solana?"**
"ERC-7710 and ERC-8004 are Ethereum standards with growing adoption. 49,400+ agents already registered via ERC-8004. The composability of EVM + account abstraction makes this possible. That said, the architecture is chain-agnostic — any EVM chain works."

**"What's the business model?"**
"Open protocol, no fees. Revenue opportunities exist at the integration layer — SDKs, hosted infrastructure, enterprise deployments — but the protocol itself is a hyperstructure."
