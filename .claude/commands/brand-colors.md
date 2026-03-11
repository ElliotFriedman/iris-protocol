# Iris Protocol — Color System

Apply when building UI, diagrams, slides, or any visual asset.

## Primary Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Background | Void | `#0D0D14` | Primary background, all dark surfaces |
| Surface | Obsidian | `#1A1A2E` | Cards, panels, elevated surfaces |
| Border | Graphite | `#2A2A3E` | Borders, dividers, inactive states |
| Text primary | Bone | `#E8E6E1` | Body text, primary content |
| Text secondary | Ash | `#9494A6` | Secondary text, labels, captions (passes AA on all surfaces) |

## Accent Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Primary accent | Iris | `#7B2FBE` | Logo, filled backgrounds, badges, non-text accents |
| Iris text | Iris Light | `#A76BE0` | Links, CTA text, active state text (passes AA on Void/Obsidian) |
| Highlight | Electric Cyan | `#00F0FF` | Data values, code highlights, focus rings |
| Warning | Amber | `#FFB800` | Warnings, spending near-limit |
| Danger | Signal Red | `#FF3B5C` | Errors, revocation, over-limit (use on Void/Obsidian only) |
| Success | Mint | `#00E88F` | Confirmed transactions, healthy reputation |

### Text-on-accent pairing rules

On Iris (`#7B2FBE`) backgrounds, use Bone for text. On Cyan, Amber, Mint, or Signal Red backgrounds, use Void (`#0D0D14`) for text. Never place Bone on bright accent backgrounds.

## Trust Tier Colors

| Tier | Name | Color | Hex | Notes |
|------|------|-------|-----|-------|
| Tier 0 | View Only | Ash | `#9494A6` | |
| Tier 1 | Supervised | Tier Cyan | `#40E0FF` | Distinct from highlight Cyan |
| Tier 2 | Autonomous | Iris | `#7B2FBE` | |
| Tier 3 | Full Delegation | Tier Gold | `#E6A800` | Distinct from warning Amber — intentionally warm to signal high-trust, high-risk |

Tier colors must never be the sole differentiator. Always pair with a label (T0, T1, T2, T3) or distinct icon.

## Surface Elevation

Every surface must be one of these values — no ad-hoc hex codes.

| Level | Name | Hex | Usage |
|-------|------|-----|-------|
| Base | Void | `#0D0D14` | Page background, modals backdrop |
| Elevation 1 | Obsidian | `#1A1A2E` | Cards, panels, nav, footer |
| Elevation 2 | Onyx | `#22223A` | Nested surfaces, table headers, agent strips, code blocks |
| Border | Graphite | `#2A2A3E` | Borders, dividers, inactive states |

## Interactive States

| State | Rule |
|-------|------|
| Hover (surface) | One elevation step up (Obsidian → Onyx, Onyx → Graphite) |
| Hover (accent) | 10% lighter variant (e.g., Iris → `#8E4FCC`) |
| Focus | 2px Cyan (`#00F0FF`) ring, 2px offset from element |
| Disabled | Ash at 40% opacity. No interaction cursor. |
| Loading/skeleton | Onyx base with subtle Graphite shimmer (pulse animation, 1.5s, ease-out) |
| Pressed | 10% darker than default accent |
| Selected/active | Left border in accent color + Onyx background |
| Input error | 1px Signal Red border, error message in Signal Red below field |
| Read-only | Same as default but cursor: default, no hover/focus effects, text at full opacity |
| Visited link | Iris Light at 80% opacity (`#A76BE0cc`) |

## Border Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `8px` | Buttons, code blocks, diagram boxes, small components |
| `--radius-md` | `12px` | Cards, modals, elevated containers |

No other radius values. Button height of 44px is an accessibility-driven exception to the 8px grid (Apple HIG touch target minimum).

## CSS Variable Naming

Use brand names in CSS custom properties. Do not create aliases (no `--charcoal`, `--charcoal-light`).

```css
--void: #0D0D14;
--obsidian: #1A1A2E;
--onyx: #22223A;
--graphite: #2A2A3E;
--bone: #E8E6E1;
--ash: #9494A6;
--iris-purple: #7B2FBE;
--iris-light: #A76BE0;
--electric-cyan: #00F0FF;
--tier-cyan: #40E0FF;
--amber: #FFB800;
--tier-gold: #E6A800;
--signal-red: #FF3B5C;
--mint: #00E88F;

--radius-sm: 8px;
--radius-md: 12px;
```

## Rules

- Dark-mode only. Never use light/white backgrounds for primary surfaces. Never expose a light-mode toggle.
- Reserve white (`#FFFFFF`) exclusively for high-contrast text in diagrams or small UI labels.
- Default ratio: 80% dark neutrals, 12% text, 8% accent. Data-dense views (dashboards, monitoring) may shift to 75/12/13.
- No gradients on backgrounds or large surfaces. Flat, solid fills only.
- Subtle gradients acceptable only on small accent elements (e.g., button hover state).
- Every color in CSS must map to a named brand token. No unnamed hex values outside this palette.
- Cyan and Mint can appear similar under deuteranopia — always pair success states with a checkmark icon, never rely on color alone.
