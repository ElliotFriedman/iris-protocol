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

## Audience Registers

The four voice attributes always apply, but depth and reference density shift by audience:

| Audience | Register | What changes |
|----------|----------|-------------|
| Protocol developers | Full technical depth, ERC references, Solidity examples | Default register — nothing changes |
| Product/BD readers | Mechanism descriptions without Solidity, outcomes over implementation | Reduce ERC density, add context for standards |
| Crypto-native social | Shorter, punchier, shared cultural context | Sentence length drops, direct comparisons OK |
| Enterprise/institutional | More measured confidence, evidence-based claims | "State what it does" becomes "show what it does" — use data, architecture diagrams, and concrete deployment scenarios rather than assertions |

## Writing Modes

**Technical mode** (API refs, contract docs, integration guides): Declarative. No superlatives ("novel," "first," "only"). Let the reader decide.

**Narrative mode** (intros, overviews, landing pages, social): Can make claims ("first," "only") but they must be falsifiable and specific. "First caveat enforcer that gates on real-time reputation" is specific enough. "Revolutionary new approach" is not.

## Terminology

| Term | Status | Usage |
|------|--------|-------|
| onchain | Preferred | Use instead of "on the blockchain" |
| trustless | Allowed in technical context | Not as generic marketing adjective |
| delegation | Preferred | Not "permission grant" or "access token" |
| caveat enforcer | Preferred (formal) | "Caveats" acceptable as informal shorthand |
| ReputationGateEnforcer | Always PascalCase, one word | UI short name: "Reputation Gate" |
| contract | Preferred | Use over "smart contract" when audience knows |
| web3 | Prohibited | Name the specific standard or mechanism |
| blockchain | Allowed as noun | Prohibited as adjective ("blockchain-powered") |
| DeFi | Prohibited in marketing | Acceptable in technical comparisons |
| decentralized | Allowed as technical descriptor | Prohibited as marketing term |

## Doc Writing Rules

- No emoji in documentation
- No colloquial language ("let's dive in", "here's the deal")
- Start every doc page with a declarative statement
- Doc hierarchy: one-sentence summary → content (H2/H3 only, never H4+) → code examples → related links
- First mention of an ERC in docs: `ERC-7710 (delegation framework)` — parenthetical context. Subsequent: `ERC-7710` alone.
- UI short names: ReputationGateEnforcer → "Reputation Gate" in UI labels; full PascalCase in code contexts.
