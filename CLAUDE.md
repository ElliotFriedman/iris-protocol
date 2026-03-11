# Iris Protocol

Trustless embedded wallet infrastructure for AI agents. Onchain embedded wallets with ERC-7710 delegation, configurable trust tiers, and reputation-gated permissions via ERC-8004.

## Brand

All written content, UI, diagrams, and presentations must follow Iris Protocol brand guidelines. Use the relevant skill before creating or reviewing any brand-facing asset:

| Skill | When to use |
|-------|-------------|
| `/brand-identity` | Naming, positioning, metaphor, naming conventions |
| `/brand-voice` | Writing copy, docs, tweets, taglines, tone |
| `/brand-colors` | Choosing colors, palettes, trust tier colors |
| `/brand-typography` | Setting type, font choices, type scale |
| `/brand-logo` | Placing logos, choosing icons (Lucide) |
| `/brand-diagrams` | Creating architecture diagrams, flowcharts |
| `/brand-slides` | Designing pitch deck or presentation slides |
| `/brand-social` | Social media posts, profile assets, tweet visuals |
| `/brand-code` | Code syntax highlighting, documentation structure |
| `/brand-ux` | Approval notification flow UI (layers 1–3) |
| `/brand-donts` | Final checklist before shipping any asset |

## Frontend Testing

Use `/frontend-test` to screenshot and interact with the frontend using Playwright. Use for visual debugging, responsive testing, brand compliance checks, and capturing console/network errors.

## Project Structure

- `src/` — Solidity contracts (IrisDelegationManager, caveat enforcers, presets)
- `demo/` — Frontend demo and landing page
- `test/` — Contract tests
- `script/` — Deployment scripts

## Conventions

- Solidity contracts use Foundry for build and test
- Frontend uses Next.js + Tailwind
- Always write **Iris Protocol** (capitalized, no article). Never "IRIS", "iris protocol", or "The Iris Protocol"
- In code: `iris-protocol` (kebab-case) or `IrisProtocol` (PascalCase)
