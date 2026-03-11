# Iris Protocol — Voice & Tone

Apply when writing any copy, docs, tweets, or descriptions for Iris Protocol.

## Voice Attributes

**Precise.** Every word earns its place. No filler, no hedging, no marketing fluff.

**Confident.** No "might," "could potentially," or "aims to." State what it does.

**Technical.** Assume the reader is smart. Name ERC standards. Describe contract interactions. Use the iris metaphor for intuition before diving into details.

**Understated.** No exclamation marks. No "revolutionary." No "game-changing."

## Taglines

**Primary:** "Privy, but trustless. Embedded agent wallets where every permission lives onchain."

**Secondary:**
- "Give your agent a wallet. Keep the keys."
- "Configure the aperture. Control what passes through."
- "They trust hardware. We trust math."

**Technical:** "Onchain embedded wallets with ERC-7710 delegation, configurable trust tiers, and reputation-gated permissions via ERC-8004."

**Rule:** Never use hype language — no "revolutionary," "game-changing," "next-generation," "web3-native," "unlock the future."

## Examples

**Good:**
> Iris gives AI agents smart contract wallets with configurable trust. Set the aperture: $100/day autonomous, anything above queued for your signature. All permissions enforced onchain via ERC-7710 caveat enforcers.

**Bad:**
> Iris Protocol is a revolutionary new platform that leverages cutting-edge blockchain technology to create next-generation AI agent wallets with unprecedented security!

**Good (technical):**
> The ReputationGateEnforcer queries ERC-8004's Reputation Registry in the beforeHook of delegation redemption. If the agent's score has dropped below the threshold encoded in the caveat terms, execution reverts.

**Bad (technical):**
> Our innovative reputation system uses advanced AI trust scores powered by the blockchain to ensure only the best agents can access your funds.

## Doc Writing Rules

- No emoji in documentation
- No colloquial language ("let's dive in", "here's the deal")
- Start every doc page with a declarative statement
- Doc hierarchy: one-sentence summary → content (H2/H3 only, never H4+) → code examples → related links
