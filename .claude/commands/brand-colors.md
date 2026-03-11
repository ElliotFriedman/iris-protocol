# Iris Protocol — Color System

Apply when building UI, diagrams, slides, or any visual asset.

## Primary Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Background | Void | `#0D0D14` | Primary background, all dark surfaces |
| Surface | Obsidian | `#1A1A2E` | Cards, panels, elevated surfaces |
| Border | Graphite | `#2A2A3E` | Borders, dividers, inactive states |
| Text primary | Bone | `#E8E6E1` | Body text, primary content |
| Text secondary | Ash | `#8A8A9A` | Secondary text, labels, captions |

## Accent Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Primary accent | Iris | `#7B2FBE` | Logo, primary CTA, active states, links |
| Highlight | Cyan | `#00F0FF` | Data values, code highlights, success states |
| Warning | Amber | `#FFB800` | Warnings, spending near-limit |
| Danger | Signal Red | `#FF3B5C` | Errors, revocation, over-limit |
| Success | Mint | `#00E88F` | Confirmed transactions, healthy reputation |

## Trust Tier Colors

| Tier | Name | Color | Hex |
|------|------|-------|-----|
| Tier 0 | View Only | Ash | `#8A8A9A` |
| Tier 1 | Supervised | Cyan | `#00F0FF` |
| Tier 2 | Autonomous | Iris | `#7B2FBE` |
| Tier 3 | Full Delegation | Amber | `#FFB800` |

## Rules

- Dark-mode only. Never use light/white backgrounds for primary surfaces.
- Reserve white (`#FFFFFF`) exclusively for high-contrast text in diagrams or small UI labels.
- A page should be 85% dark neutrals, 10% text, 5% accent. When in doubt, use less color.
- No gradients on backgrounds or large surfaces. Flat, solid fills only.
- Subtle gradients acceptable only on small accent elements (e.g., button hover state).
