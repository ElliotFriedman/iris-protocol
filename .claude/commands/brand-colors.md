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

## Surface Elevation

Use these for layered UI. Every surface must be one of these values — no ad-hoc hex codes.

| Level | Name | Hex | Usage |
|-------|------|-----|-------|
| Base | Void | `#0D0D14` | Page background, modals backdrop |
| Elevation 1 | Obsidian | `#1A1A2E` | Cards, panels, nav, footer |
| Elevation 2 | Onyx | `#22223A` | Nested surfaces, table headers, agent strips, code blocks |
| Border | Graphite | `#2A2A3E` | Borders, dividers, inactive states |

## CSS Variable Naming

Use brand names in CSS custom properties. Do not create aliases (no `--charcoal`, `--charcoal-light`).

```css
--void: #0D0D14;
--obsidian: #1A1A2E;
--onyx: #22223A;
--graphite: #2A2A3E;
--bone: #E8E6E1;
--ash: #8A8A9A;
--iris-purple: #7B2FBE;
--electric-cyan: #00F0FF;
--amber: #FFB800;
--signal-red: #FF3B5C;
--mint: #00E88F;
```

## Rules

- Dark-mode only. Never use light/white backgrounds for primary surfaces. Never expose a light-mode toggle.
- Reserve white (`#FFFFFF`) exclusively for high-contrast text in diagrams or small UI labels.
- A page should be 85% dark neutrals, 10% text, 5% accent. When in doubt, use less color.
- No gradients on backgrounds or large surfaces. Flat, solid fills only.
- Subtle gradients acceptable only on small accent elements (e.g., button hover state).
- Every color in CSS must map to a named brand token. No unnamed hex values outside this palette.
