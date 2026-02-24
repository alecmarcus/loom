# External Sources

Pull work from Slack messages, Notion pages, or Sentry errors — Loom fetches the context and implements it.

## Slack

### Prerequisites

Install the Slack MCP server:

```bash
claude mcp add --transport http slack https://mcp.slack.com/mcp
```

Or add to `.mcp.json`:

```json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://mcp.slack.com/mcp"
    }
  }
}
```

Complete OAuth by starting Claude Code and triggering a Slack tool — a browser window opens to authorize your workspace. This is a one-time step.

### Usage

Slack mode requires a message permalink URL:

```bash
# From Claude Code
/loom slack https://team.slack.com/archives/C07ABC123/p1234567890

# From bash
.loom/start.sh --slack "https://team.slack.com/archives/C07ABC123/p1234567890"
```

### How to get a permalink

In Slack: hover over a message → click the three dots menu → "Copy link".

### What happens

1. Loom fetches the Slack message and its thread context
2. Reads and understands the request or bug report
3. Implements what's described
4. Runs tests, commits, creates PR

### With extra instructions

```bash
.loom/start.sh --slack "https://team.slack.com/..." --prompt "Only fix the backend, skip frontend changes"
```

---

## Notion

### Prerequisites

Install the Notion MCP server:

```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp
```

Or add to `.mcp.json`:

```json
{
  "mcpServers": {
    "notion": {
      "type": "http",
      "url": "https://mcp.notion.com/mcp"
    }
  }
}
```

Complete OAuth by starting Claude Code and triggering a Notion tool — authorize access to your workspace in the browser. This is a one-time step.

### Usage

Accepts a page URL or search query:

```bash
# By URL
/loom notion https://notion.so/team/API-Redesign-Spec-abc123
.loom/start.sh --notion "https://notion.so/team/API-Redesign-Spec-abc123"

# By search
/loom notion "API redesign spec"
.loom/start.sh --notion "checkout flow requirements"
```

### What happens

1. Loom fetches the Notion page content, including sub-pages, databases, and linked references
2. Reads the full spec or requirements
3. Implements everything specified
4. Runs tests, commits, creates PR

### With extra instructions

```bash
.loom/start.sh --notion "https://notion.so/..." --prompt "Focus on the backend API only, skip the frontend for now"
```

---

## Sentry

### Prerequisites

Install the Sentry MCP server:

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

Or add to `.mcp.json`:

```json
{
  "mcpServers": {
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    }
  }
}
```

Complete OAuth by starting Claude Code and triggering a Sentry tool — authorize access to your Sentry organization in the browser. This is a one-time step.

### Usage

Accepts an issue URL or search query:

```bash
# By URL
/loom sentry https://sentry.io/organizations/org/issues/12345/
.loom/start.sh --sentry "https://sentry.io/organizations/org/issues/12345/"

# By search
/loom sentry "TypeError in checkout flow"
.loom/start.sh --sentry "unhandled promise rejection"
```

### What happens

1. Loom fetches the Sentry error details: exception type, stack trace, breadcrumbs, tags, linked issues
2. Identifies the root cause from the stack trace
3. Fixes the bug
4. Adds a regression test that reproduces the error and verifies the fix
5. Commits, pushes, creates PR

Sentry mode is specifically designed for bug fixing — it always writes regression tests.

### With extra instructions

```bash
.loom/start.sh --sentry "https://sentry.io/..." --prompt "Also add error boundary components to prevent this class of error"
```

---

## Combining Sources

All source types can be combined with each other and with `--prompt`:

```bash
# Sentry error + GitHub issue + custom instructions
.loom/start.sh --sentry "https://sentry.io/..." --github 42 --prompt "Also update the error handling docs"

# Notion spec + Linear ticket
.loom/start.sh --notion "API redesign spec" --linear "TEAM-42"

# Slack request + specific constraints
.loom/start.sh --slack "https://team.slack.com/..." --prompt "Use the v2 API, not v1"
```

Each source adds a section to the directive. The agent receives all sources as context and implements holistically.

## Troubleshooting

**"No MCP tools available" for any source**
- Verify the MCP is configured: `claude mcp list`
- Check `.mcp.json` is valid JSON: `jq '.' .mcp.json`
- Re-authenticate if the OAuth token expired: start Claude Code and trigger the relevant MCP tool

**Slack: "requires a permalink URL"**
- Slack mode only accepts permalink URLs, not channel names or message text
- Get the permalink: hover over message → three dots → "Copy link"

**Notion: page not accessible**
- Ensure the OAuth-authorized workspace includes the page
- Re-authorize if you've been added to a new workspace since initial setup

**Sentry: no stack trace available**
- Some Sentry errors lack full stack traces (e.g., client-side errors without source maps)
- Loom will still attempt a fix based on available context, but results may be less precise
