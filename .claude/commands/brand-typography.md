# Iris Protocol — Typography

Apply when setting type in UI, slides, docs, or diagrams.

## Primary: JetBrains Mono

Used for: headlines, section headers, code, data values, contract addresses, logo wordmark.

- Bold (700) — headlines, H1, H2
- Medium (500) — H3, subheads, navigation
- Regular (400) — code blocks, inline code, data values

## Secondary: Satoshi

Used for: body text, descriptions, long-form content, pitch deck body.

- Medium (500) — body text
- Bold (700) — bold emphasis within body
- Regular (400) — captions, secondary text

Source: https://www.fontshare.com/fonts/satoshi

## Type Scale

| Element | Font | Weight | Size | Line height | Letter spacing |
|---------|------|--------|------|-------------|----------------|
| H1 | JetBrains Mono | Bold | 36px / 2.25rem | 1.1 | -0.02em |
| H2 | JetBrains Mono | Bold | 28px / 1.75rem | 1.2 | -0.01em |
| H3 | JetBrains Mono | Medium | 20px / 1.25rem | 1.3 | 0 |
| Body | Satoshi | Medium | 16px / 1rem | 1.6 | 0 |
| Caption | Satoshi | Regular | 13px / 0.8125rem | 1.5 | 0.01em |
| Code | JetBrains Mono | Regular | 14px / 0.875rem | 1.5 | 0 |
| Data value | JetBrains Mono | Medium | 18px / 1.125rem | 1.2 | 0 |

## Font Loading

**JetBrains Mono:** Load from Google Fonts. Weights: 400, 500, 700.

```
https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&display=swap
```

**Satoshi:** Load from Fontsource or self-host. Not available on Google Fonts.

```
npm install @fontsource/satoshi
```

Then import in your entry CSS:

```css
@import '@fontsource/satoshi/400.css';
@import '@fontsource/satoshi/500.css';
@import '@fontsource/satoshi/700.css';
```

**Never use Inter, Arial, Helvetica, or any system sans-serif as the body font.** Inter is not part of the Iris Protocol type system.

## Fallbacks

- JetBrains Mono unavailable: `"SF Mono", "Fira Code", "Courier New", monospace`
- Satoshi unavailable: `"DM Sans", "Outfit", sans-serif`

## CSS Implementation

```css
--font-sans: 'Satoshi', "DM Sans", "Outfit", sans-serif;
--font-mono: 'JetBrains Mono', "SF Mono", "Fira Code", "Courier New", monospace;

body { font-family: var(--font-sans); }
h1, h2, h3, h4, h5, h6 { font-family: var(--font-mono); }
```

## Rules

- Never use serif fonts, decorative fonts, handwritten fonts, or system defaults (Arial, Helvetica, Times).
- Never use Inter. It is not part of the Iris Protocol type system.
- All heading sizes must match the type scale above — do not use arbitrary sizes.
