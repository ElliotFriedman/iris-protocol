# Iris Protocol — Approval Notification UX

Apply when building the approval flow UI.

## Layer 1 — Notification Banner

Full-width, 64px height. Obsidian (`#1A1A2E`) background with 4px left-edge severity stripe. Iris mark (16px) left-aligned. Summary in Satoshi Medium, Bone. Two action buttons (8px radius, not pill-shaped): `[Approve]` (Mint outline), `[View Details]` (Ash outline).

**Severity stripe colors:**
- Routine (just over cap, known contract): Cyan `#00F0FF`
- Significant (2–5x cap, unfamiliar parameter): Amber `#FFB800`
- Unusual (new contract, large amount, declining reputation): Signal Red `#FF3B5C`

**Text:** `"Agent #[id] requests: [action]. [reason]."` — one sentence, max two lines. Agent ID in JetBrains Mono; rest in Satoshi.

## Layer 2 — Detail Card

480px modal (desktop) or full-width (mobile). Void backdrop at 60% opacity. Obsidian card, 12px radius, 1px Graphite border. Max height: `calc(100vh - 48px)`. Inner content scrolls; action buttons are sticky at bottom with an Obsidian fade-out gradient (24px) above them.

**Sections (top to bottom):**

1. **Agent profile strip:** Agent name (JetBrains Mono Medium, Bone). Reputation score in Cyan (e.g., `87/100`) with trend arrow. Delegation age in Ash. Background: Onyx (`#22223A`).

2. **Transaction block:** Human-readable description (Satoshi Medium, Bone). Data table (JetBrains Mono Regular, 14px): Target Contract, Function, Value, Estimated Gas. Contract name links in Iris Light (`#A76BE0`).

3. **Policy block:** Vertical caveat list. `check-circle` (Mint) for passed, `alert-triangle` (Amber) for triggered. Triggered row gets Amber left border + explanation. Spending bar: Graphite track, Cyan fill, Amber for pending overage.

4. **Action buttons:** Full-width stack, 8px gap, 44px height, Satoshi Medium 14px (Button style), 8px radius.
   - `[Approve This Transaction]` — Mint text, 1px Mint border
   - `[Approve & Raise Cap]` — Iris Light text, 1px Iris border
   - `[Reject]` — Ash text, 1px Graphite border
   - `[Reject & Revoke]` — Signal Red text, 1px Signal Red border
   - `[Inspect Calldata →]` — Ash text, no border, arrow icon

## Layer 3 — Calldata Inspector

Replaces card content (same modal shell). Decoded calldata in JetBrains Mono Regular 13px with syntax highlighting. Decoded function signature at top. Parameter table (name, type, value). Simulation results with green/red balance deltas. Block explorer links in Iris Light (`#A76BE0`). `[← Back to Details]` in Ash at top-left.

## Button Interactive States

All action buttons follow the interactive state system from `/brand-colors`:
- **Hover:** Border thickens to 2px, text brightens 10%
- **Focus:** 2px Cyan focus ring, 2px offset
- **Disabled:** Ash text at 40% opacity, Graphite border at 40% opacity, no pointer cursor
- **Loading:** Text replaced with factual status (e.g., "Submitting transaction...", "Verifying delegation...") + subtle pulse animation (1.5s, ease-out), button non-interactive
- **Pressed:** Background fills at 10% opacity of the button's accent color

## Microcopy

**Notification text format:** `"Agent #[id] requests: [human-readable action]. [reason for approval]."`

**Error messages:** `[What happened]. [Why]. [What to do next].` — no apologetic language ("Oops"), no exclamation marks.

**Empty states:** `[What belongs here]. [How to get started].` — e.g., "No agents delegated. Create your first delegation to get started."

**Loading states:** Factual status only. "Verifying delegation..." not "Just a moment" or "Hang tight."

**Success confirmations:** Declarative past tense. "Delegation created. Agent #42 can now execute within Tier 2 constraints."

## Animation

- Entry transitions: 250ms ease-out
- Exit transitions: 200ms ease-out
- Layer 1→2: card slides up from notification
- Layer 2→3: cross-fade within same card shell (no resize)
- Dismiss: slide down + fade (200ms)
- No bouncy, spring, or particle effects. Linear or ease-out only.
