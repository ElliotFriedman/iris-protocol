# Iris Protocol — Code & Doc Style

Apply when writing documentation or showing code in any visual context.

## Solidity Syntax Highlighting

| Element | Color |
|---------|-------|
| Keywords (`function`, `contract`, `require`) | Iris purple (`#7B2FBE`) |
| Types (`uint256`, `address`, `bool`) | Cyan (`#00F0FF`) |
| Strings and comments | Ash (`#8A8A9A`) |
| Function names | Bone (`#E8E6E1`) |
| Numbers and constants | Amber (`#FFB800`) |
| Storage variables | Mint (`#00E88F`) |

## Documentation Structure

1. One-sentence summary of what the page covers
2. Content using H2 and H3 only (never H4+)
3. Code examples where applicable
4. Links to related pages

## Code Block Styling

- Background: Onyx (`#22223A`) with 1px Graphite (`#2A2A3E`) border, 8px border radius
- Font: JetBrains Mono Regular 14px, line height 1.5
- Do not use third-party syntax themes (Dracula, GitHub, etc.) as-is — customize to match the brand palette above

## Docusaurus / Prism Integration

When using Prism for syntax highlighting, override the default theme colors to match brand tokens. The dark theme base must use Onyx (`#22223A`) for the code background, not the Prism default.

## Code Dense (13px)

For the calldata inspector and dense data views, use `Code dense`: JetBrains Mono Regular 13px, line-height 1.5. This is the only context where 13px code is acceptable.

## Doc Rules

- No emoji in documentation
- No colloquial language ("let's dive in", "here's the deal")
- Start every page with a declarative statement
- Never use serif fonts in any code or doc context
- All code backgrounds use Onyx (`#22223A`), never Void or Obsidian
- Never apply negative letter-spacing (`tracking-tight`) to monospace text
