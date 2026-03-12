# Iris Protocol — Hackathon Presentation

---

<!-- SLIDE 1 — HOOK (Type A: Statement) -->

## 6% trust agents with purchasing control

$3–5 trillion in projected agent transactions by 2030 — and almost no one trusts the infrastructure to handle it.

<!-- Worldpay survey of 8,000 consumers across 7 countries. McKinsey agent economy projection. -->
<!-- Speaker: Open with the number. Pause. The gap between market scale and consumer trust is where fraud happens. Slide 2 shows what that looks like in practice. -->
<!-- Judge notes — Illia Polosukhin: No token. No speculation. Practical infrastructure solving a real problem today. Working system with 233 tests, formal proofs, dashboard, and landing page. -->

---

<!-- SLIDE 2 — THE TRUST GAP (Type C: Comparison) -->

## The trust gap is not theoretical

| What happened | Impact |
|---------------|--------|
| AiXBT trading bot: attacker queued fraudulent prompts via dashboard | 55.5 ETH ($106K) stolen. Token dropped 15.5%. |
| Prompt injection at financial institution: hidden instructions in email | $2.3M in unauthorized wire transfers |
| Single compromised agent in multi-agent network | Poisoned 87% of downstream decisions within 4 hours |
| Perplexity shopping agent: charged the card, then failed to deliver | Agent commerce credibility damaged |

45% of consumers in Asia Pacific will not proceed to AI checkout without stronger security assurances. Only 14% trust AI recommendations alone to make a purchase.

<!-- Speaker: Don't dwell on each incident. Read AiXBT in detail, gesture at the others. The pattern: agents with keys and no guardrails fail. Close with the 45% stat — nearly half of consumers refuse to check out through AI without security guarantees. -->

---

<!-- SLIDE 3 — WHY CURRENT SOLUTIONS FAIL (Type C: Comparison) -->

## Current agent wallets require blind trust

| | Privy / Custodial | Iris Protocol |
|---|---|---|
| Key storage | TEEs, key shards, company servers | Smart contract wallet (ERC-4337) |
| Permission model | Offchain policy, company-enforced | Onchain caveats, math-enforced |
| Spending limits | Backend rules, trust the company | SpendingCapEnforcer, verifiable onchain |
| Identity | API key, revocable by provider | ERC-8004 onchain identity, self-sovereign |
| What if the company disappears? | Agent loses access | Nothing changes. Contracts persist. |

They trust hardware. We trust math.

<!-- Speaker: Be precise, not dismissive. "Privy is great infrastructure. But if your agent's permissions live on someone else's server, you don't have trustless delegation — you have a service agreement." -->

---

<!-- SLIDE 4 — Iris Protocol IN ONE SENTENCE (Type A: Statement) -->

## Every permission lives onchain

Iris Protocol: embedded agent wallets with configurable trust. Configure the aperture. Control what passes through.

<!-- Speaker: Slow down. This is the thesis. Explain the aperture metaphor in one breath: "A camera iris controls light. Our protocol controls autonomy. You set the aperture — $100/day autonomous, anything above needs your signature. All enforced by smart contracts." -->

---

<!-- SLIDE 5 — HOW IT WORKS (Type B: Diagram) -->

## Trust tiers: configure the aperture

| Tier | Name | What the agent can do | Caveats active |
|------|------|-----------------------|----------------|
| T0 | View Only | Read balances, no execution | — |
| T1 | Supervised | Execute within tight bounds | Spending cap (daily), contract whitelist, time window, reputation gate |
| T2 | Autonomous | Broader execution with per-tx limits | T1 + single transaction cap |
| T3 | Full Delegation | Wide autonomy with cooldowns | Weekly spending cap, whitelist, time window, reputation gate (higher threshold), per-tx cap, cooldown enforcer |

Every tier is a bundle of caveat enforcers — independent, composable smart contracts that run before and after every agent action. Not one permission check. Defense in depth.

<!-- Speaker: Point at the diagram. "Each tier is a stack of independent security checks. An agent at Tier 2 passes through five separate enforcer contracts before a single transaction executes." -->

---

<!-- SLIDE 6 — THE NOVEL CONTRIBUTION (Type B: Diagram) -->

## Reputation-gated delegation

Traditional access control: grant permission, revoke manually if agent misbehaves.

Iris Protocol: grant permission, agent reputation is checked at **execution time**, not delegation time.

```
Agent attempts action
  → DelegationManager calls beforeHook
    → ReputationGateEnforcer queries ERC-8004 registry
      → Score ≥ threshold? Execute.
      → Score < threshold? Revert. No manual intervention.
```

If an agent's reputation drops below the threshold encoded in the delegation, access degrades automatically. No human needs to notice. No emergency revocation. The aperture narrows on its own.

The ReputationGateEnforcer is the first caveat enforcer that gates delegated execution on real-time onchain reputation.

<!-- Speaker: "Every other delegation system is static — you grant, you revoke. Ours is dynamic. The aperture adjusts to the agent's reputation automatically." -->
<!-- Judge notes — Davide Crapis: This is the application ERC-8004 was designed for. 49,400+ agents have registered identities via ERC-8004 — the ReputationGateEnforcer is the first enforcer that reads this registry at execution time. Not at delegation creation, at execution. -->

---

<!-- SLIDE 7 — SECURITY / DEFENSE IN DEPTH (Type A: Statement) -->

## Security is the design constraint

Seven independent caveat enforcers. Each one is a separate security boundary:

1. **SpendingCapEnforcer** — rolling period limits (daily, weekly)
2. **SingleTxCapEnforcer** — per-transaction value ceiling
3. **ContractWhitelistEnforcer** — only approved contracts callable
4. **FunctionSelectorEnforcer** — only approved functions callable
5. **TimeWindowEnforcer** — execution only within valid windows
6. **CooldownEnforcer** — mandatory delays between high-value transactions
7. **ReputationGateEnforcer** — dynamic reputation-based access

233 passing tests. 74 Halmos symbolic proofs verifying invariants hold for ALL possible inputs. Reentrancy protection. Full chain enforcement. Stateful enforcer caller verification.

Not a hackathon prototype. Production-grade infrastructure.

<!-- Speaker: "We built seven independent layers. To compromise an Iris delegation, you'd need to bypass all of them simultaneously. 53 formal proofs verify these invariants hold for every possible input — not just the ones we tested." -->
<!-- Judge notes — Tomasz Stanczak: Emphasize institutional-grade quality. 233 tests + 53 formal proofs. Ethereum as the agent settlement layer. This is the kind of infrastructure Nethermind would deploy. -->
<!-- Judge notes — Austin Griffith: Composability is key. Each enforcer is independent, importable, composable via AND-logic. Clean DX — import TierOne.sol, call configureTierOne(), get a ready-made caveat array. Pure Foundry tooling. -->

---

<!-- SLIDE 8 — DEMO (Type D: Demo) -->

## Demo: 60-second walkthrough

1. **Register an agent** on the ERC-8004 identity registry — agent gets an onchain identity
2. **Create an Iris wallet** — deterministic ERC-4337 smart contract account
3. **Configure the aperture** — select Tier 2, set $100/day spending cap, whitelist Uniswap
4. **Agent executes** — swaps within bounds, all caveats pass, transaction succeeds
5. **Agent hits the cap** — tries to exceed $100, SpendingCapEnforcer reverts
6. **Reputation drops** — oracle feedback lowers score, ReputationGateEnforcer blocks execution
7. **No manual intervention** — the protocol enforced every boundary automatically

<!-- Speaker: Keep this tight. Click through the dashboard. Show the aperture visualization opening and closing. Show a transaction succeed, then show one get blocked. The visual is the argument. -->

---

<!-- SLIDE 9 — STANDARDS STACK (Type B: Diagram) -->

## Built on Ethereum standards

| Standard | Role in Iris |
|----------|-------------|
| ERC-4337 | Smart contract accounts (IrisAccount) |
| ERC-7710 | Delegation with caveat enforcers |
| ERC-7715 | Permission request flow |
| ERC-8004 | Agent identity and reputation registry |
| EIP-7702 | EOA upgrade path (forward-compatible) |

Every component is an open standard. No vendor lock-in. No API keys. No company dependency.

If Iris Protocol disappears tomorrow, your delegations still enforce.

<!-- Speaker: "Every standard is open. Your delegations enforce regardless of whether Iris Protocol exists. That's the point of building on Ethereum." -->

---

<!-- SLIDE 10 — PATH TO ADOPTION (Type A: Statement) -->

## Who needs this today

| Segment | Use case |
|---------|----------|
| **Agent frameworks** (ElizaOS, LangChain) | Default wallet for any agent that moves money |
| **Onchain protocols** (Uniswap, Aave) | Agent-driven strategies within user-set bounds |
| **Enterprise AI** (87% cite trust as blocker) | Auditable permission model for compliance teams |
| **Consumer commerce** ($261B projected by 2030) | Configurable tiers from supervised to autonomous |

<!-- Speaker: "These users exist right now. The trust gap is already blocking adoption. Iris Protocol is the permission layer they need." -->

---

<!-- SLIDE 11 — THE ASK (Type A: Statement) -->

## Iris Protocol

Privy, but trustless. Embedded agent wallets where every permission lives onchain.

- 7 caveat enforcers, composable and independent
- Dynamic reputation-gated access via ERC-8004
- 233 tests. 53 formal proofs. Zero failures.
- Full documentation, dashboard, and landing page

Give your agent a wallet. Keep the keys.

<!-- Speaker: "Thank you. Questions?" -->
<!-- Judge notes — Venture panel: "Privy but trustless" positions against a $3B+ market (Stripe acquired Privy for $1.1B). Defensible moat: onchain delegation is a protocol, not a feature. Network effects via portable ERC-8004 reputation. No token — pure infra play. -->

---

## Appendix: Data Sources

- Worldpay survey (8,000 consumers, 7 countries): 6% would grant full autonomous purchasing control
- Visa/Asia Pacific (2026): 45% won't proceed to AI checkout without stronger security assurances
- Salsify (2026): Only 14% trust AI recommendations alone to make a purchase
- Stellar Cyber (2026): Single compromised agent poisoned 87% of downstream decisions in 4 hours
- Hogan Lovells (2026): Agentic payments introduce new fraud landscape — attackers target agent permissions
- McKinsey: $3-5T annual agent transaction volume by 2030
- Gartner: 87% of executives cite trust as primary agentic AI adoption obstacle
- AiXBT incident (March 2025): 55.5 ETH stolen via dashboard compromise
- Obsidian Security: $2.3M wire transfer fraud via prompt injection
- WEF (Jan 2026): AI agents market could reach $236B by 2034
- ERC-8004: 49,400+ AI agents registered as of Feb 2026
