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

## Type Scale — Display (landing pages, marketing)

| Element | Font | Weight | Size | Line height | Letter spacing |
|---------|------|--------|------|-------------|----------------|
| Display 1 | JetBrains Mono | Bold | 72px / 4.5rem | 1.05 | 0 |
| Display 2 | JetBrains Mono | Bold | 48px / 3rem | 1.1 | 0 |

Display sizes are for short, punchy headlines only (max 5–6 words). Never use negative letter-spacing on monospace — the equal-width grid IS the brand.

## Type Scale — Interface (dashboard, docs, app)

| Element | Font | Weight | Size | Line height | Letter spacing |
|---------|------|--------|------|-------------|----------------|
| H1 | JetBrains Mono | Bold | 36px / 2.25rem | 1.15 | 0 |
| H2 | JetBrains Mono | Bold | 28px / 1.75rem | 1.2 | 0 |
| H3 | JetBrains Mono | Medium | 20px / 1.25rem | 1.3 | 0 |
| Lead | Satoshi | Medium | 18px / 1.125rem | 1.5 | 0 |
| Body | Satoshi | Medium | 16px / 1rem | 1.6 | 0 |
| Body light | Satoshi | Regular | 16px / 1rem | 1.6 | 0 |
| Overline | JetBrains Mono | Regular | 11px / 0.6875rem | 1.4 | 0.08em |
| Caption | Satoshi | Regular | 13px / 0.8125rem | 1.5 | 0.01em |
| Code | JetBrains Mono | Regular | 14px / 0.875rem | 1.5 | 0 |
| Code dense | JetBrains Mono | Regular | 13px / 0.8125rem | 1.5 | 0 |
| Data value | JetBrains Mono | Medium | 18px / 1.125rem | 1.2 | 0 |
| Button | Satoshi | Medium | 14px / 0.875rem | 1 | 0.01em |
| Badge | JetBrains Mono | Regular | 12px / 0.75rem | 1 | 0 |
| Label | Satoshi | Regular | 12px / 0.75rem | 1.5 | 0 |
| Input | JetBrains Mono | Regular | 14px / 0.875rem | 1.5 | 0 |
| Nav | Satoshi | Medium | 14px / 0.875rem | 1 | 0 |

**Overline** is used for stat labels, form labels, table headers: uppercase, wide tracking. This is a core pattern across the dashboard.

**Lead** is for subtitles and prominent descriptions below headings.

**Body light** (400 weight) is for long-form reading contexts (docs, blog). Use Medium (500) for dashboard and short-form copy where dark backgrounds thin lighter text.

**Code dense** (13px) is for the calldata inspector and dense data views only.

**Badge** (JetBrains Mono 12px) is for status indicators, tier labels, and capability tags — anything that looks like a chip or tag with a colored background. Use mono because badges often contain technical identifiers (T1, T2, contract names).

**Label** (Satoshi 12px) is for form field labels, data table headers, and descriptive annotations. Use sans because labels are natural-language text that describes something.

**Button** vs **Nav**: Both are 14px Satoshi Medium. Button has 0.01em letter-spacing and line-height 1 (tightly contained for click targets). Nav has 0 letter-spacing and line-height 1 (for horizontal menu alignment).

## Font Loading

**JetBrains Mono:** Install via Fontsource (self-hosted, no external CDN):

```bash
npm install @fontsource/jetbrains-mono
```

```css
@import '@fontsource/jetbrains-mono/400.css';
@import '@fontsource/jetbrains-mono/500.css';
@import '@fontsource/jetbrains-mono/700.css';
```

**Satoshi:** Not available on Fontsource or Google Fonts. Self-host from Fontshare.

1. Download woff2 files from https://www.fontshare.com/fonts/satoshi (weights 400, 500, 700)
2. Place in `public/fonts/` as `satoshi-400.woff2`, `satoshi-500.woff2`, `satoshi-700.woff2`
3. Declare `@font-face` in your entry CSS:

```css
@font-face {
  font-family: 'Satoshi';
  src: url('/fonts/satoshi-400.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Satoshi';
  src: url('/fonts/satoshi-500.woff2') format('woff2');
  font-weight: 500;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Satoshi';
  src: url('/fonts/satoshi-700.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}
```

**Never load fonts from external CDNs** (Google Fonts, Fontshare API). Self-host all font files to avoid tracking and render-blocking.

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
- Never apply negative letter-spacing to monospace text. The equal-width character grid is the brand aesthetic. If headings feel too wide, reduce font size instead.
- Use `tracking-tight` only on Satoshi (sans) elements, never on JetBrains Mono.
