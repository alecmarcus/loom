# Figma

Enable design token extraction, Code Connect mappings, and visual fidelity verification in Loom runs.

## Prerequisites

1. A Figma account with access to the design file(s) your project references.

2. The design file URL. You'll need this for PRD story `details.designUrl` fields. Format:
   ```
   https://figma.com/design/<fileKey>/<fileName>?node-id=<nodeId>
   ```

## Setup

### Step 1: Install the Figma MCP server

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
```

This uses HTTP transport (not stdio) because Figma's MCP server is hosted.

### Step 2: Complete OAuth authentication

The Figma MCP requires OAuth on first use. This is an **interactive step** — you must complete it in a Claude Code session:

1. Start Claude Code: `claude`
2. Trigger any Figma MCP tool (e.g., ask Claude to fetch a design)
3. A browser window opens for Figma OAuth
4. Authorize the connection
5. The token is cached for future sessions

**Important:** OAuth cannot be completed in unattended Loom runs. Complete this step interactively before starting Loom, or use `/loom` from inside Claude Code (which can handle the OAuth prompt).

### Step 3: Project-scope the MCP (optional)

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
```

Loom copies `.mcp.json` into worktrees automatically.

### Step 4: Verify capability detection

Start a Loom dry run and check the header:

```bash
.loom/start.sh --dry-run
```

The tmux header should show:

```
MCPs  design
```

This confirms Loom detected the Figma MCP and mapped it to the `design` capability.

## Writing Stories

### Auto-detection keywords

When you use `/prd` to generate stories, it auto-detects the `tools` field from acceptance criteria. The following keywords trigger `"tools": ["design"]`:

- `Figma`, `design fidelity`, `design tokens`, `pixel-matching`, `design system`, `design spec`, `color tokens`, `typography tokens`, `spacing tokens`, `component library`

### Example PRD story

```json
{
  "id": "APP-020",
  "title": "Implement Button component matching design system",
  "gate": "gate-1",
  "priority": "P0",
  "severity": "critical",
  "status": "pending",
  "files": ["src/components/Button.tsx", "src/styles/tokens.ts", "tests/Button.test.tsx"],
  "description": "Create a Button component that matches the design system spec in Figma. Supports primary, secondary, and ghost variants with sm/md/lg sizes. Uses design tokens for colors, typography, and spacing.",
  "acceptanceCriteria": [
    "Button renders with primary, secondary, and ghost variants",
    "Button supports sm, md, and lg sizes",
    "Primary button uses design token colors: background $color-primary-500, text $color-white",
    "Secondary button uses design token colors: background transparent, border $color-primary-500, text $color-primary-500",
    "Typography matches design system: font-family $font-sans, font-weight 600",
    "Spacing matches design tokens: sm=8px/16px, md=12px/24px, lg=16px/32px (vertical/horizontal padding)",
    "Border radius uses design token $radius-md (8px)",
    "Hover, focus, and disabled states match Figma design spec",
    "Component matches Figma design with high fidelity — no visual regressions"
  ],
  "actionItems": [
    "Extract design tokens from Figma using MCP tools",
    "Create token constants file with color, typography, and spacing values",
    "Implement Button component with variant and size props",
    "Add hover, focus, and disabled state styles",
    "Write unit tests for all variant/size combinations",
    "Verify visual fidelity against Figma design"
  ],
  "blockedBy": [],
  "tools": ["design"],
  "sources": [],
  "details": {
    "designUrl": "https://figma.com/design/abc123/MyApp?node-id=42-1337"
  }
}
```

### Writing effective design acceptance criteria

- **Reference specific tokens**: "$color-primary-500" not "the primary color"
- **Include exact values**: "padding sm=8px/16px" not "appropriate padding"
- **Specify all states**: "hover, focus, and disabled states" not "interactive states"
- **Name variants**: "primary, secondary, and ghost" not "multiple variants"
- **Request fidelity checks**: "matches Figma design with high fidelity" triggers visual verification
- **Include the design URL** in `details.designUrl` so the subagent knows where to look

## What Happens at Runtime

1. **Capability detection** — Loom's `start.sh` scans `.mcp.json`, finds `figma`, maps it to `design` via `CAPABILITY_MAP`, exports `LOOM_CAPABILITIES=design`.

2. **Story selection** — Stories with `"tools": ["design"]` are only selected when `design` is in `LOOM_CAPABILITIES`.

3. **Subagent execution** — The subagent:
   - Reads the `details.designUrl` from the story
   - Calls Figma MCP's `get_design_context` to fetch design code, screenshots, and component metadata
   - Extracts design tokens (colors, typography, spacing) from the Figma file
   - Checks for Code Connect mappings that link Figma components to codebase components
   - Implements the component using extracted tokens and design context
   - Takes Figma screenshots for visual comparison during development
   - Writes tests that verify token values and component structure

4. **Design verification** — The subagent uses Figma MCP to:
   - `get_screenshot` — capture the Figma design for visual reference
   - `get_design_context` — get code hints, component structure, and design tokens
   - `get_variable_defs` — extract variable/token definitions
   - `get_code_connect_map` — check if Figma components are already mapped to code components

## Interactive vs Unattended

| Mode | Works? | Notes |
|------|--------|-------|
| `/loom` from Claude Code | Yes | OAuth can be completed interactively |
| `.loom/start.sh` (first run) | No | OAuth requires a browser — complete it interactively first |
| `.loom/start.sh` (after OAuth) | Yes | Cached token is reused |

**Recommendation:** Complete OAuth interactively once, then use either mode. If the token expires, you'll need another interactive session.

## Code Connect

If your project uses [Figma Code Connect](https://www.figma.com/developers/code-connect), the subagent will discover existing mappings automatically:

1. The subagent calls `get_code_connect_map` for the design node
2. If a mapping exists, it shows which codebase component corresponds to the Figma component
3. The subagent reuses the existing component instead of building from scratch
4. New mappings can be created with `add_code_connect_map`

This prevents duplicate component implementations when Figma components are already mapped to your codebase.

## Troubleshooting

**Figma MCP not detected (no `design` in MCPs line)**
- Verify `.mcp.json` has a `figma` key
- Run `claude mcp list` to check registration
- Ensure the transport type is `http`, not the default stdio

**"OAuth required" / "Not authenticated"**
- Complete OAuth interactively first: start Claude Code, trigger a Figma tool, authorize in the browser
- Check if the token has expired — re-authorize if needed
- The Figma MCP server must be able to reach `https://mcp.figma.com/mcp`

**"File not found" or permission errors**
- Verify the Figma file URL is correct and the authenticated user has access
- Check that the `node-id` in the URL points to a valid node
- The file may be in a team/org that requires separate access

**Design tokens not extracted**
- Not all Figma files use variables/tokens. The subagent falls back to extracting raw values (hex colors, px values) from the design
- Check if the Figma file has a published styles/variables library
- Use `get_variable_defs` to inspect available tokens

**Rate limiting**
- Figma's API has rate limits. If Loom is running many design stories in parallel, subagents may hit limits
- Reduce parallelism by adding `blockedBy` dependencies between design stories
- The Figma MCP server handles retries internally for most cases

**Stories with `"tools": ["design"]` are skipped**
- Check `LOOM_CAPABILITIES` in the tmux header
- If `design` is missing, the Figma MCP isn't configured or `.mcp.json` isn't in the project root
