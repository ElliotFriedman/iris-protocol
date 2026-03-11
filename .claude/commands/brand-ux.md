# Iris Protocol — Approval Notification UX

Apply when building the approval flow UI.

## Layer 1 — Notification Banner

Full-width, 64px height. Obsidian (`#1A1A2E`) background with 4px left-edge severity stripe. Iris mark (16px) left-aligned. Summary in Satoshi Medium, Bone. Pill buttons: `[Approve]` (Mint outline), `[View Details]` (Ash outline).

**Severity stripe colors:**
- Routine (just over cap, known contract): Cyan `#00F0FF`
- Significant (2–5x cap, unfamiliar parameter): Amber `#FFB800`
- Unusual (new contract, large amount, declining reputation): Signal Red `#FF3B5C`

**Text:** `"Agent #[id] requests: [action]. [reason]."` — one sentence, max two lines. Agent ID in JetBrains Mono; rest in Satoshi.

## Layer 2 — Detail Card

480px modal (desktop) or full-width (mobile). Void backdrop at 60% opacity. Obsidian card, 12px radius, 1px Graphite border.

**Sections (top to bottom):**

1. **Agent profile strip:** Agent name (JetBrains Mono Medium, Bone). Reputation score in Cyan (e.g., `87/100`) with trend arrow. Delegation age in Ash. Background: Onyx (`#22223A`).

2. **Transaction block:** Human-readable description (Satoshi Medium, Bone). Data table (JetBrains Mono Regular, 14px): Target Contract, Function, Value, Estimated Gas. Contract name links in Iris purple.

3. **Policy block:** Vertical caveat list. `check-circle` (Mint) for passed, `alert-triangle` (Amber) for triggered. Triggered row gets Amber left border + explanation. Spending bar: Graphite track, Cyan fill, Amber for pending overage.

4. **Action buttons:** Full-width stack, 8px gap, 44px height, JetBrains Mono Medium 14px, 8px radius.
   - `[Approve This Transaction]` — Mint text, 1px Mint border
   - `[Approve & Raise Cap]` — Iris text, 1px Iris border
   - `[Reject]` — Ash text, 1px Graphite border
   - `[Reject & Revoke]` — Signal Red text, 1px Signal Red border
   - `[Inspect Calldata →]` — Ash text, no border, arrow icon

## Layer 3 — Calldata Inspector

Replaces card content (same modal shell). Decoded calldata in JetBrains Mono Regular 13px with syntax highlighting. Decoded function signature at top. Parameter table (name, type, value). Simulation results with green/red balance deltas. Block explorer links in Iris purple. `[← Back to Details]` in Ash at top-left.

## Animation

- 200ms ease-out transitions throughout
- Layer 1→2: card slides up from notification
- Layer 2→3: cross-fade within same card shell (no resize)
- Dismiss: slide down + fade
- No bouncy, spring, or particle effects. Linear or ease-out only.
