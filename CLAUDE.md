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

- `contracts/` — Foundry project (build with `cd contracts && forge build`)
  - `contracts/src/` — Solidity contracts (IrisDelegationManager, caveat enforcers, presets)
  - `contracts/test/` — Contract tests
  - `contracts/script/` — Deployment scripts
  - `contracts/lib/` — Git submodules (forge-std, openzeppelin, delegation-framework)
- `apps/dashboard/` — Next.js dashboard app (`@iris-protocol/dashboard`)
- `apps/landing/` — Next.js landing page (`@iris-protocol/landing`)
- `e2e/` — E2E test harness (TypeScript + viem + vitest against local Anvil)
  - Run with `./e2e/run.sh` or `pnpm test:e2e`
  - Starts Anvil, deploys contracts, runs 18 E2E tests
- `docs/` — Docusaurus documentation (independent dep tree)

## Conventions

- Solidity contracts use Foundry for build and test
- Frontend uses Next.js + Tailwind
- Always write **Iris Protocol** (capitalized, no article). Never "IRIS", "iris protocol", or "The Iris Protocol"
- In code: `iris-protocol` (kebab-case) or `IrisProtocol` (PascalCase)
