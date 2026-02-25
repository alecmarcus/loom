# Custom MCP

Extend Loom with any MCP server beyond the built-in Playwright, Mobile, and Figma integrations.

## How Capability Detection Works

Loom auto-detects MCP capabilities at startup. Here's the full pipeline:

### 1. Scan `.mcp.json`

Loom reads your project's `.mcp.json` and extracts all configured MCP server names.

### 2. Map to capabilities

Each server name is checked against the built-in `CAPABILITY_MAP` in `scripts/start.sh` (plugin root):

```bash
CAPABILITY_MAP=(
  "playwright:browser"
  "chrome:browser"
  "puppeteer:browser"
  "browserbase:browser"
  "mobile:mobile"
  "mobile-mcp:mobile"
  "appium:mobile"
  "figma:design"
)
```

Format: `server_name:capability_category`

Multiple servers can map to the same capability (e.g., `playwright`, `chrome`, and `puppeteer` all map to `browser`).

### 3. Expose unknown servers by name

Servers not in `CAPABILITY_MAP` are exposed as capabilities using their server name directly. For example, if you configure a server named `database`, the capability `database` becomes available.

### 4. Export environment

Two environment variables are set:

- `LOOM_MCP_SERVERS` — comma-separated list of all configured server names
- `LOOM_CAPABILITIES` — comma-separated list of resolved capability categories

These are visible in the tmux header and available to the orchestrator and subagents.

## Using a Custom MCP Without Modifying Loom

If you add an MCP server with a unique name, it automatically becomes a capability:

### Step 1: Configure the MCP server

```bash
claude mcp add my-database -- npx @example/database-mcp@latest
```

Or in `.mcp.json`:

```json
{
  "mcpServers": {
    "my-database": {
      "command": "npx",
      "args": ["@example/database-mcp@latest"]
    }
  }
}
```

### Step 2: Verify detection

```bash
/loom:preview
```

The tmux header should show:

```
MCPs  my-database
```

### Step 3: Use in stories

Set the `tools` field to match the server name:

```json
{
  "id": "APP-030",
  "title": "Add database migration for user preferences",
  "tools": ["my-database"],
  ...
}
```

Stories with `"tools": ["my-database"]` will only run when the `my-database` MCP is configured.

### Caveat: `/loom:prd` auto-detection

The `/loom:prd` generator auto-detects `tools` based on acceptance criteria keywords, but it only recognizes `browser`, `mobile`, and `design`. Custom capabilities won't be auto-detected — you'll need to either:

1. Manually set `tools` on stories after `/loom:prd` generates them
2. Or mention the capability explicitly in your spec file and let `/loom:prd` copy it into the story fields

## Adding a Built-in Mapping

If you want multiple server names to map to the same custom capability (like `playwright`/`chrome`/`puppeteer` all mapping to `browser`), add entries to `CAPABILITY_MAP` in `scripts/start.sh` (plugin root):

### Step 1: Edit the CAPABILITY_MAP

Open `scripts/start.sh` in the plugin root and find the `CAPABILITY_MAP` array (near line 731). Add your mappings:

```bash
CAPABILITY_MAP=(
  # browser
  "playwright:browser"
  "chrome:browser"
  "puppeteer:browser"
  "browserbase:browser"
  # mobile
  "mobile:mobile"
  "mobile-mcp:mobile"
  "appium:mobile"
  # design
  "figma:design"
  # database (custom)
  "my-database:database"
  "supabase-mcp:database"
  "postgres-mcp:database"
)
```

Now any of `my-database`, `supabase-mcp`, or `postgres-mcp` will resolve to the `database` capability.

### Step 2: Use in stories

```json
{
  "tools": ["database"]
}
```

Any of the three mapped servers will satisfy this requirement.

## Project-Scoping vs Global Config

### Project `.mcp.json` (recommended)

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["@example/my-mcp@latest"]
    }
  }
}
```

- Travels with the repo
- Loom auto-copies into worktrees
- Other team members get the same config

### Global config

```bash
claude mcp add my-server -- npx @example/my-mcp@latest
```

- Only on your machine
- Not shared with the team
- Won't be copied into worktrees

### Worktree behavior

Loom copies `.mcp.json` from the project root into each worktree at startup. This means:

- MCP servers configured in `.mcp.json` are available in worktrees
- Global MCP servers are always available regardless
- Changes to `.mcp.json` in the main tree take effect on the next worktree creation

## Example: Adding a Supabase MCP

### 1. Install

```bash
claude mcp add supabase -- npx @supabase/mcp@latest --url $SUPABASE_URL --key $SUPABASE_KEY
```

Or in `.mcp.json`:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["@supabase/mcp@latest", "--url", "https://your-project.supabase.co", "--key", "your-key"]
    }
  }
}
```

### 2. Verify

```bash
/loom:preview
# Header should show: MCPs  supabase
```

### 3. Write stories

```json
{
  "id": "APP-031",
  "title": "Create user_preferences table with RLS policies",
  "gate": "gate-1",
  "priority": "P0",
  "severity": "critical",
  "status": "pending",
  "files": ["supabase/migrations/001_user_preferences.sql", "src/lib/supabase.ts"],
  "description": "Create a user_preferences table in Supabase with row-level security policies. Users can only read and write their own preferences.",
  "acceptanceCriteria": [
    "user_preferences table exists with columns: id, user_id, theme, language, notifications_enabled",
    "RLS is enabled on the table",
    "SELECT policy allows users to read only their own rows (auth.uid() = user_id)",
    "INSERT policy allows users to insert only with their own user_id",
    "UPDATE policy allows users to update only their own rows",
    "DELETE policy allows users to delete only their own rows"
  ],
  "actionItems": [
    "Create migration SQL file with table definition",
    "Add RLS policies for CRUD operations",
    "Run migration via Supabase MCP",
    "Verify table and policies exist"
  ],
  "blockedBy": [],
  "tools": ["supabase"],
  "sources": [],
  "details": {}
}
```

### 4. At runtime

The subagent discovers Supabase MCP tools via `ListMcpResourcesTool` and uses them to run migrations, verify table structure, and test RLS policies directly.

## Combining Capabilities

Stories can require multiple capabilities:

```json
{
  "tools": ["browser", "database"]
}
```

This story only runs when **both** `browser` and `database` capabilities are available. All entries in the `tools` array must be present in `LOOM_CAPABILITIES`.

## Troubleshooting

**Custom MCP not appearing in capabilities**
- Check `.mcp.json` is valid JSON: `jq '.' .mcp.json`
- Verify the server name matches what you're using in `tools`
- Run `claude mcp list` to confirm the server is registered

**Capability shows as server name instead of category**
- This is expected for servers not in `CAPABILITY_MAP`
- The server name IS the capability. Use it directly in `tools`
- If you want a category name, add a mapping to `CAPABILITY_MAP`

**MCP not available in worktrees**
- Verify `.mcp.json` is in the project root (not a subdirectory)
- Loom copies `.mcp.json` at worktree creation time — changes after creation require a new worktree
- Global MCP servers are always available

**Stories with custom tools are never selected**
- Verify the exact string in `tools` matches the capability name (case-sensitive)
- Check `LOOM_CAPABILITIES` in the tmux header
- For custom MCPs without a `CAPABILITY_MAP` entry, the capability name is the server name from `.mcp.json`
