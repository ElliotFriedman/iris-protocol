# Speaker Notes

## Slide 1 — Hook
Open with "6%." Pause. Then deliver the context: $3-5 trillion market, almost no one trusts the infrastructure. The judges (likely Tomasz Stanczak, Austin Griffith, Davide Crapis) care about practical agentic utility — this frames the entire presentation as solving a real, quantified problem.

## Slide 2 — Trust Gap
Don't dwell on each incident. Read one (AiXBT) in detail, gesture at the others. The point is pattern recognition: agents with keys and no guardrails fail. Close with the 48% stat — fraud protection is what consumers want.

## Slide 3 — Current Solutions
Be precise, not dismissive. "Privy is great infrastructure" — then explain the trust assumption. The judges likely know Privy. Don't trash it. Show the architectural difference: offchain policy vs. onchain enforcement. The column that matters most: "What if the company disappears?"

## Slide 4 — One Sentence
Slow down. This is the thesis. Let the tagline breathe. Then explain the aperture metaphor in one breath: "A camera iris controls light. Our protocol controls autonomy. You set the aperture."

## Slide 5 — Trust Tiers
Walk through the tiers quickly but make sure judges understand the composability. Each tier is a *bundle* of independent enforcers, not a single permission level. Emphasize "defense in depth" — this phrase should land hard for judges evaluating production readiness.

## Slide 6 — ReputationGateEnforcer
This is the key differentiator. Spend the most time here. The key insight: traditional access control is static (grant/revoke). Iris is dynamic (checked at execution time). Use the aperture metaphor: "The aperture narrows automatically when reputation drops." This is what separates Iris from every other delegation system.

## Slide 7 — Security
Rapid-fire through the seven enforcers. The point is quantity and independence — seven separate security boundaries. Then hit the test coverage: 22 unit suites, 8 E2E suites. Close with "This is not a demo. This is production-grade infrastructure." Judges at Synthesis care about d/acc and defensive technology — this slide is for them.

## Slide 8 — Demo
60 seconds maximum. Pre-record a backup video in case of technical issues. The three moments that matter: (1) a transaction succeeding within bounds, (2) a transaction getting blocked by the spending cap, (3) reputation dropping and the enforcer automatically blocking. The aperture visualization opening/closing is the visual payoff.

## Slide 9 — Standards
Quick slide. The point is: no vendor lock-in, no proprietary infrastructure. Everything is an open Ethereum standard. "If Iris Protocol disappears tomorrow, your delegations still enforce." This line should get a reaction from judges who care about d/acc.

## Slide 10 — Path to Adoption
Name the specific users. Agent framework developers, DeFi protocols, enterprise, consumer commerce. The 87% executive trust stat is for the enterprise pitch. The $261B projection is for the commerce pitch. Make it concrete: "These users exist right now."

## Slide 11 — Close
Repeat the tagline. Let the stats speak. "Give your agent a wallet. Keep the keys." Stop talking. Wait for questions.

## Anticipated Questions

**"How does the reputation oracle work? Who submits feedback?"**
Authorized reviewers per agent, set by the agent owner. Positive feedback: +2 points (capped at 100). Negative: -5 points (floored at 0). Default score: 50. The asymmetry is intentional — it's harder to build reputation than to lose it.

**"What prevents the reputation oracle from being gamed?"**
The oracle is permissioned — only authorized reviewers can submit feedback for a given agent. In production, this would connect to a decentralized reputation aggregator (DeFi protocol completion rates, dispute resolution outcomes). The enforcer is oracle-agnostic: any ERC-8004 compliant registry works.

**"How is this different from MetaMask's delegation framework?"**
We build on top of it. MetaMask's delegation-framework handles the ERC-7710 delegation lifecycle. Iris adds: the ReputationGateEnforcer, the trust tier presets, the approval queue, the ERC-8004 identity layer, and the full account abstraction stack. We're an application of the framework, not a competitor to it.

**"Is this deployed?"**
Base Sepolia. All contracts verified on Basescan. Local Anvil deployment for demo. 22 unit test suites, 8 E2E test suites all passing.

**"What's the gas cost?"**
Each caveat enforcer adds ~5-15K gas. A Tier 2 delegation with 5 enforcers adds ~50-75K gas to a transaction. On Base, that's less than $0.01. The security cost is negligible.

## Timing Target
- Slides 1-3 (problem): 90 seconds
- Slides 4-6 (solution + novel): 120 seconds
- Slide 7 (security): 45 seconds
- Slide 8 (demo): 60 seconds
- Slides 9-11 (standards + adoption + close): 90 seconds
- **Total: ~7 minutes** (leaves 3 minutes for Q&A in a 10-minute slot)
