# Playwright

Enable browser testing, screenshots, and DOM verification in Loom runs.

## Prerequisites

1. Verify Node.js is installed:
   ```bash
   node --version
   ```
   If missing, install via [nodejs.org](https://nodejs.org/) or `brew install node`.

2. Verify your project has a dev server. Check `package.json` for a `dev` or `start` script:
   ```bash
   jq '.scripts.dev // .scripts.start' package.json
   ```
   Loom subagents need a running server to test against. If your project doesn't have one, you'll need to configure one before browser stories can be verified.

## Setup

### Step 1: Install the Playwright MCP server

For unattended Loom runs (recommended):

```bash
claude mcp add playwright -- npx @playwright/mcp@latest --headless
```

For interactive sessions where you want to see the browser:

```bash
claude mcp add playwright -- npx @playwright/mcp@latest
```

### Step 2: Project-scope the MCP (recommended)

Add to your project's `.mcp.json` instead of global config so it travels with the repo:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headless"]
    }
  }
}
```

Loom copies `.mcp.json` into worktrees automatically.

### Step 3: Verify capability detection

Start a Loom dry run and check the header for `browser` in the MCPs line:

```bash
.loom/start.sh --dry-run
```

The tmux header should show:

```
MCPs  browser
```

This confirms Loom detected the Playwright MCP and mapped it to the `browser` capability via its internal `CAPABILITY_MAP`.

## Writing Stories

### Auto-detection keywords

When you use `/prd` to generate stories, it auto-detects the `tools` field from acceptance criteria. The following keywords in your acceptance criteria trigger `"tools": ["browser"]`:

- `browser`, `web UI`, `screenshots`, `DOM`, `CSS`, `responsive`, `HTML`, `page`, `viewport`, `click`, `form`, `input`, `button`, `navigation`, `render`

Write acceptance criteria using these terms and `/prd` will set `"tools": ["browser"]` automatically.

### Example PRD story

```json
{
  "id": "APP-012",
  "title": "Build login page with form validation",
  "gate": "gate-2",
  "priority": "P1",
  "severity": "major",
  "status": "pending",
  "files": ["src/pages/login.tsx", "src/components/LoginForm.tsx", "tests/login.spec.ts"],
  "description": "Create a login page with email and password fields, client-side validation, and error states. The page must be responsive and accessible.",
  "acceptanceCriteria": [
    "Login page renders at /login with email and password fields",
    "Empty form submission shows validation errors below each field",
    "Invalid email format shows 'Please enter a valid email' error",
    "Password field has type='password' and a show/hide toggle",
    "Form is responsive: single column on mobile (<768px), centered card on desktop",
    "All form inputs have associated labels and aria attributes",
    "Screenshot of login page matches design intent — no visual regressions",
    "Tab order follows logical flow: email → password → submit"
  ],
  "actionItems": [
    "Create LoginForm component with controlled inputs",
    "Add client-side validation with error message display",
    "Add responsive styles with mobile breakpoint",
    "Write Playwright tests for form behavior and visual state",
    "Add aria-labels and role attributes for accessibility"
  ],
  "blockedBy": ["APP-003"],
  "tools": ["browser"],
  "sources": [],
  "details": {}
}
```

### Writing effective browser acceptance criteria

- **Be specific about URLs**: "renders at /login" not "the login page works"
- **Name the elements**: "email and password fields" not "the form fields"
- **Include visual checks**: "responsive: single column on mobile (<768px)" not "works on mobile"
- **Include accessibility**: "all form inputs have associated labels and aria attributes"
- **Reference screenshots**: "screenshot of login page matches design intent" tells the subagent to use Playwright MCP for visual verification

## What Happens at Runtime

1. **Capability detection** — Loom's `start.sh` scans `.mcp.json`, finds `playwright`, maps it to `browser` via `CAPABILITY_MAP`, exports `LOOM_CAPABILITIES=browser`.

2. **Story selection** — The orchestrator checks each story's `tools` array. Stories with `"tools": ["browser"]` are only selected when `browser` is in `LOOM_CAPABILITIES`. Without Playwright installed, these stories stay `pending` and are skipped.

3. **Subagent execution** — The subagent receives the story and is told that `browser` capabilities are available. It:
   - Reads the acceptance criteria
   - Implements the feature code
   - Uses Playwright MCP tools ad-hoc to take screenshots, inspect DOM elements, and verify visual state during development
   - Writes durable Playwright test files that verify the acceptance criteria programmatically
   - The MCP tools are discovered dynamically — the subagent calls `ListMcpResourcesTool` to find available Playwright actions

4. **Test verification** — The orchestrator runs the full test suite (including the new Playwright tests). If tests fail, it attempts fixes up to 3 times before moving on.

## Example Test Output

A subagent working on the login form story above might generate a test file like this:

```typescript
// tests/login.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Login Page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('renders email and password fields', async ({ page }) => {
    await expect(page.getByLabel('Email')).toBeVisible();
    await expect(page.getByLabel('Password')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Log in' })).toBeVisible();
  });

  test('shows validation errors on empty submission', async ({ page }) => {
    await page.getByRole('button', { name: 'Log in' }).click();
    await expect(page.getByText('Please enter a valid email')).toBeVisible();
    await expect(page.getByText('Password is required')).toBeVisible();
  });

  test('validates email format', async ({ page }) => {
    await page.getByLabel('Email').fill('not-an-email');
    await page.getByRole('button', { name: 'Log in' }).click();
    await expect(page.getByText('Please enter a valid email')).toBeVisible();
  });

  test('password field has show/hide toggle', async ({ page }) => {
    const passwordInput = page.getByLabel('Password');
    await expect(passwordInput).toHaveAttribute('type', 'password');
    await page.getByRole('button', { name: /show password/i }).click();
    await expect(passwordInput).toHaveAttribute('type', 'text');
  });

  test('responsive layout on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    const form = page.locator('form');
    const formBox = await form.boundingBox();
    expect(formBox?.width).toBeLessThanOrEqual(375);
  });

  test('accessible form inputs', async ({ page }) => {
    const emailInput = page.getByLabel('Email');
    const passwordInput = page.getByLabel('Password');
    await expect(emailInput).toHaveAttribute('aria-required', 'true');
    await expect(passwordInput).toHaveAttribute('aria-required', 'true');
  });

  test('tab order follows logical flow', async ({ page }) => {
    await page.keyboard.press('Tab');
    await expect(page.getByLabel('Email')).toBeFocused();
    await page.keyboard.press('Tab');
    await expect(page.getByLabel('Password')).toBeFocused();
    await page.keyboard.press('Tab');
    await expect(page.getByRole('button', { name: 'Log in' })).toBeFocused();
  });
});
```

## Dev Server Considerations

Playwright tests need a running dev server. Common approaches:

### Option A: Playwright `webServer` config (recommended)

Add to `playwright.config.ts`:

```typescript
export default defineConfig({
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: true,
  },
});
```

This starts the dev server automatically before tests and reuses it if already running.

### Option B: Pre-start the dev server

Start the dev server in a separate terminal or tmux pane before running Loom:

```bash
npm run dev &
```

### Option C: Include in acceptance criteria

Add to your story's `actionItems`:

```json
"actionItems": [
  "Ensure playwright.config.ts has a webServer entry pointing to the dev server"
]
```

## Troubleshooting

**Playwright MCP not detected (no `browser` in MCPs line)**
- Verify `.mcp.json` exists and has a `playwright` key
- Run `claude mcp list` to check if the server is registered
- Check that the server name is exactly `playwright` (or `chrome` or `puppeteer` — all map to `browser`)

**Tests fail with "page.goto: net::ERR_CONNECTION_REFUSED"**
- The dev server isn't running. Add a `webServer` block to `playwright.config.ts` or start it manually before Loom
- Check the port matches your dev server's port

**Tests fail with "browser has been closed"**
- Missing `--headless` flag. For unattended Loom runs, always use `--headless`
- Check `.mcp.json` args include `"--headless"`

**Screenshots are blank or wrong size**
- Set explicit viewport sizes in tests: `await page.setViewportSize({ width: 1280, height: 720 })`
- Headless mode may render differently — add viewport assertions

**Stories with `"tools": ["browser"]` are skipped**
- Loom skips tool-gated stories when the capability isn't available
- Check `LOOM_CAPABILITIES` in the tmux header
- If empty, the MCP server isn't configured or `.mcp.json` isn't in the project root
