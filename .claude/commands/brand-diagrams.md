# Iris Protocol — Architecture Diagrams

Apply when creating any technical diagram, flowchart, or system visualization.

## Layout

- Left-to-right for delegation chains
- Top-to-bottom for stack diagrams
- Never diagonal. Never circular.

## Boxes

- Rounded rectangles, 8px border radius
- Fill: Obsidian (`#1A1A2E`) with 1px Graphite (`#2A2A3E`) border
- Label: JetBrains Mono Medium, Bone (`#E8E6E1`)
- Sub-label (ERC standard): JetBrains Mono Regular, Ash (`#8A8A9A`), smaller

## Arrows

- 1.5px stroke, Ash for flow, accent color for emphasis
- Simple triangle arrowhead, 6px
- Labels: JetBrains Mono Regular, 12px, Ash

## Grouping

- Dashed borders (2px, Graphite) for related components
- Group label: JetBrains Mono Medium, Ash, top-left

## Emphasis

- Novel components (ReputationGateEnforcer): Iris purple border + subtle glow (`box-shadow: 0 0 20px rgba(123, 47, 190, 0.15)`)
- Happy-path arrows: Cyan (`#00F0FF`)
- Blocked/reverted flow: Signal Red (`#FF3B5C`)

## Required Diagrams

1. **System architecture:** User wallet → IrisAccount → DelegationManager → Caveat Enforcers → Agent execution → Target contract. ERC-8004 registry as separate service.
2. **Trust tier comparison:** Four columns (Tier 0–3), iris at different openings, active caveats, agent capabilities, co-signature requirements.
3. **ReputationGateEnforcer flow:** Agent attempts redemption → DelegationManager calls beforeHook → Enforcer queries ERC-8004 → pass/fail → execute or revert.
4. **Iris vs. Privy comparison:** Left: Privy (TEEs, key shards, offchain policy, company dependency) with red markers. Right: Iris (smart contract, onchain caveats, ERC-8004, no dependency) with green markers.
