# Frontend Tester

Use Playwright to screenshot and interact with the frontend for debugging.

## Instructions

1. Determine the frontend dev server URL. Check for a running dev server or start one:
   - Look in `demo/landing/` for the Next.js landing page (default: `http://localhost:3000`)
   - Look in `demo/app/` for the main app (default: `http://localhost:3001`)
   - If no server is running, start it with `npm run dev` or `pnpm dev` in the appropriate directory, running in the background.

2. Use Playwright to navigate, screenshot, and interact. Run commands like:

```bash
# Install Playwright if needed
npx playwright install chromium 2>/dev/null

# Take a full-page screenshot
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto('http://localhost:3000');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: '/tmp/iris-screenshot.png', fullPage: true });
  await browser.close();
})();
"
```

3. Read the screenshot with the Read tool to visually inspect it.

4. For debugging specific issues, interact with the page:

```bash
# Click elements, fill forms, navigate
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto('http://localhost:3000');
  await page.waitForLoadState('networkidle');

  // Example: click a button and screenshot the result
  // await page.click('button:has-text(\"Connect Wallet\")');
  // await page.waitForTimeout(1000);

  await page.screenshot({ path: '/tmp/iris-screenshot.png', fullPage: true });
  await browser.close();
})();
"
```

5. For responsive testing, vary the viewport:

```bash
# Mobile viewport
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 375, height: 812 } });
  await page.goto('http://localhost:3000');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: '/tmp/iris-mobile.png', fullPage: true });
  await browser.close();
})();
"
```

6. After capturing screenshots, read them and report:
   - Visual issues (layout broken, colors wrong, elements overlapping)
   - Brand compliance (check against `/brand-colors`, `/brand-typography`)
   - Console errors (capture with `page.on('console', ...)`)
   - Network failures (capture with `page.on('requestfailed', ...)`)

## Debugging Workflow

When investigating a bug:
1. Screenshot the current state
2. Identify the problematic element using selectors
3. Click/interact to reproduce the issue
4. Screenshot each step
5. Check console output for errors
6. Report findings with screenshots

## Console & Network Error Capture

```bash
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  const errors = [];
  const networkFailures = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
  page.on('requestfailed', req => networkFailures.push(req.url() + ' ' + req.failure().errorText));

  await page.goto('http://localhost:3000');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: '/tmp/iris-screenshot.png', fullPage: true });

  if (errors.length) console.log('CONSOLE ERRORS:', JSON.stringify(errors, null, 2));
  if (networkFailures.length) console.log('NETWORK FAILURES:', JSON.stringify(networkFailures, null, 2));

  await browser.close();
})();
"
```
