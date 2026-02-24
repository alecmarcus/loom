# Loom

Loom is a Ralph Wiggum style autonomous development loop for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) that is optimized for multi-threaded work with subagents.

Loom runs Claude Code in a continuous loop, reading tasks from a source(s) of your choosing, dispatching parallel subagents, testing & validating, committing passing code, and repeating — all inside a tmux session you can monitor.

You can loom from inside Claude Code with the `/loom` skill, or directly via the bash script.

## Quick start

1. Install
   ```bash
   cd your-project
   curl -fsSL https://raw.githubusercontent.com/alecmarcus/loom/main/install.sh | bash
   ```

2. Loom
   ```bash
   # Give it a task
   /loom Refactor all callbacks to async/await

   # Work from a GitHub issue
   /loom github 42

   # Work from a Linear ticket
   /loom linear TEAM-42

   # Build a feature from specs
   /prd spec.md design.md
   /loom

   # Set up a loop, or a specific integration
   /loom setup a prd for the first three phases of the project
   /loom setup playwright
   ```

## How it works

```
┌─────────────────────────────────────────────────┐
│                  start.sh (loop)                 │
│                                                 │
│  ┌───────────┐    ┌──────────┐    ┌──────────┐  │
│  │ Read PRD  │───▶│ Dispatch │───▶│  Tests   │  │
│  │ + status  │    │ subagents│    │ + commit │  │
│  └───────────┘    └──────────┘    └──────────┘  │
│        ▲                               │        │
│        └───────────────────────────────┘        │
│                 write status.md                 │
└─────────────────────────────────────────────────┘
```

Each iteration:

1. **Recall** — reads `status.md` (short-term memory) and queries Vestige (long-term memory)
2. **Select** — picks parallelizable stories from `prd.json` using `jq`
3. **Execute** — launches one subagent per story, all in parallel
4. **Verify** — runs tests, fixes failures (up to 3 attempts)
5. **Commit** — commits only green code using conventional commits
6. **Report** — writes `status.md`, which triggers a hard kill and loop restart

## Installation

### Prerequisites

- git
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview) (`claude` in PATH)
- [jq](https://jqlang.github.io/jq/)
- [mdq](https://github.com/yshavit/mdq) (markdown query tool, used by `/prd` to extract sections from spec files)
- [tmux](https://github.com/tmux/tmux/wiki) (recommended — provides split-pane monitoring)

### Install script

The remote install script shallow-clones the necessary files from this repo into a temporary directory, installs brew deps, runs `setup.sh` in the cwd, and cleans itself up after.

```bash
curl -fsSL https://raw.githubusercontent.com/alecmarcus/loom/main/install.sh | bash
```

Or specify a target project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/alecmarcus/loom/main/install.sh | bash -s -- /path/to/your-project
```

### Manual setup

If you don't have them, install `jq`, `mdq`, and `tmux`:

```bash
# Loom uses jq to pre-parse JSON before sending to claude, optimizing context
brew install jq

# mdq extracts sections from markdown spec files during PRD generation
brew install mdq

# tmux provides split-pane monitoring stream inside the terminal
brew install tmux
```

Clone the repo and run the setup script:

```bash
git clone https://github.com/alecmarcus/loom.git
cd loom
./setup.sh /path/to/your-project
```

The setup script:
- Copies `.loom/` (scripts, hooks, prompt templates)
- Installs the `/loom` and `/prd` [skills](https://code.claude.com/docs/en/skills) for Claude Code
- Configures Claude Code hooks in `.claude/settings.json`
- Updates `.gitignore`

## Usage

Everything in Loom can be run from the `/loom` slash command inside Claude Code or from the `.loom/start.sh` bash script directly. Both support the same sources and options.

### Sources

Sources tell Loom where to get work. Without a source, Loom defaults to PRD mode (reads `.loom/prd.json`). Sources can be combined — e.g., `--github 42 --prompt "Also fix lint"`.

| Source | Bash flag | `/loom` subcommand | Accepts | MCP / tool required | Auth |
|--------|-----------|-------------------|-------|-------------------|------|
| PRD | *(default)* | `/loom` | — | — | — |
| Prompt | `--prompt` | `/loom <text>` | text, file path | — | — |
| Piped | `echo "..." \| .loom/start.sh` | — | stdin | — | — |
| GitHub | `--github` | `/loom github` | issue #, URL, search query | `gh` CLI | `gh auth login` |
| Linear | `--linear` | `/loom linear` | ticket ID, URL, search query | [Linear MCP](https://mcp.linear.app) | OAuth |
| Slack | `--slack` | `/loom slack` | permalink URL | [Slack MCP](https://mcp.slack.com) | OAuth |
| Notion | `--notion` | `/loom notion` | page URL, search query | [Notion MCP](https://mcp.notion.com) | OAuth |
| Sentry | `--sentry` | `/loom sentry` | issue URL, search query | [Sentry MCP](https://mcp.sentry.dev) | OAuth |

Loom always runs in a git worktree — an isolated branch so your main tree stays clean. When the loop completes, the branch is pushed and a PR is created automatically.

#### Examples

```bash
# PRD mode — work through stories until done
/loom
.loom/start.sh

# Directive — give it a task directly
/loom Refactor all callbacks to async/await
.loom/start.sh --prompt "Fix all lint errors"

# GitHub — issue number, URL, or search
/loom github 42
.loom/start.sh --github "https://github.com/org/repo/issues/42"

# Linear — ticket ID, URL, or natural language
/loom linear TEAM-42
/loom linear fix all tickets with less than 24h left in the SLA

# Slack — message permalink
/loom slack https://team.slack.com/archives/C.../p...

# Notion — page URL or search
/loom notion https://notion.so/team/My-Spec-Page-abc123
/loom notion "API redesign spec"

# Sentry — issue URL or search
/loom sentry https://sentry.io/organizations/org/issues/12345/
/loom sentry "TypeError in checkout flow"

# Combine sources
.loom/start.sh --github 42 --prompt "Also fix the related lint warnings"
```

### Generating a PRD

```bash
# From Claude Code (recommended)
/prd spec.md planning-session.md sketch.md

# Standalone script
.loom/prd.sh spec.md planning-session.md

# Append to existing PRD
/prd additional-spec.md append
```

The PRD generator decomposes your documents into atomic stories grouped into prioritized gates, with dependency tracking, acceptance criteria, and predicted file paths.

### Options

| Flag | Short | Default | Description |
|------|-------|-------|-------------|
| `--max-iterations` | `-m` | `500` | Maximum loop iterations |
| `--dry-run` | `-d` | off | Analyze one iteration without executing changes |
| `--timeout` | — | `10800` | Per-iteration timeout in seconds |
| `--max-failures` | — | `3` | Consecutive failures before halt |
| `--worktree` | — | on | Git worktree isolation |
| `--pr` | — | on | Push branch + create PR after loop |
| `--resume` | — | — | Resume an existing worktree by path or branch |

## MCP integrations

Loom subagents can use any MCP tools configured in the project. These are especially useful for stories with visual, browser, or mobile acceptance criteria.

### Supported servers

| MCP | Install | Capability | What it provides |
|-----|-------|------------|------------------|
| [Playwright](https://github.com/microsoft/playwright-mcp) | `claude mcp add playwright -- npx @playwright/mcp@latest --headless` | `browser` | Browser automation, screenshots, DOM interaction. Use `--headless` for unattended Loom runs. |
| [Mobile MCP](https://github.com/mobile-next/mobile-mcp) | `claude mcp add mobile -- npx -y @mobilenext/mobile-mcp@latest` | `mobile` | iOS Simulator + Android Emulator screenshots, tap, swipe, app management. Requires a running simulator/emulator. |
| [Figma](https://developers.figma.com/docs/figma-mcp-server/) | `claude mcp add --transport http figma https://mcp.figma.com/mcp` | `design` | Full Figma integration (Code Connect, design system rules, bidirectional). Requires interactive OAuth on first use — better for interactive sessions than unattended Loom runs. |

To scope an MCP server to a single project, add it to your project's `.mcp.json` instead of global config. Loom copies `.mcp.json` into worktrees automatically.

### Capability auto-detection

Loom automatically detects MCP capabilities at startup by scanning `.mcp.json`. Known server names map to capability categories:

| Server names | Capability |
|-------------|-----------|
| `playwright`, `chrome`, `puppeteer`, `browserbase` | `browser` |
| `mobile`, `mobile-mcp`, `appium` | `mobile` |
| `figma` | `design` |

Servers not in this list are exposed by their own name as a capability (e.g., a server named `supabase` becomes the `supabase` capability).

The resolved capabilities are exported as `LOOM_CAPABILITIES` and displayed in the tmux header. During story selection, Loom checks each story's `tools` array against the available capabilities — stories requiring missing capabilities stay `pending` and are skipped. The `/prd` generator auto-detects `tools` from acceptance criteria keywords (e.g., "screenshot" → `["browser"]`, "simulator" → `["mobile"]`, "design tokens" → `["design"]`).

## Setup guides

Step-by-step guides for common scenarios — written as agent-executable instructions. Setup guides live in this repo and are fetched on demand. Use `/loom setup` to have an agent fetch and execute any guide for your project:

```bash
/loom setup playwright
/loom setup mobile testing
/loom setup github issues
/loom setup how do I run loom on a large feature
```

Or browse all [setup guides](setup/) directly.

**Usage patterns:**

| Guide | When to use |
|-------|-------------|
| [Large Feature](setup/large-feature.md) | Build a multi-story feature from specs using PRD mode |
| [Quick Task](setup/quick-task.md) | Run a focused directive without PRD overhead |
| [PRD Creation](setup/prd-creation.md) | Generate, review, and refine PRDs from spec files |
| [GitHub Issues](setup/github-issues.md) | Implement GitHub issues — fetch, build, close |
| [Linear Tickets](setup/linear-tickets.md) | Implement Linear tickets — fetch, build, update |
| [External Sources](setup/external-sources.md) | Pull work from Slack, Notion, or Sentry |
| [Testing](setup/testing.md) | Configure test suites for any language/framework |
| [Worktrees & PRs](setup/worktrees-and-prs.md) | Control isolation, branching, and PR creation |

**Validation:**

| Guide | Capability | What it sets up |
|-------|-----------|-----------------|
| [Playwright](setup/validation/playwright.md) | `browser` | Browser testing, screenshots, DOM verification |
| [Mobile MCP](setup/validation/mobile-mcp.md) | `mobile` | iOS Simulator & Android Emulator via MCP |
| [agent-device](setup/validation/mobile-agent-device.md) | — | iOS & Android via CLI skill (token-efficient) |
| [Figma](setup/validation/figma.md) | `design` | Design token extraction & visual fidelity |
| [Custom MCP](setup/validation/custom-mcp.md) | any | Extend Loom with any MCP server |

## Monitoring & control

Loom launches in a tmux session with four panes:

| Pane | Content |
|------|-------|
| Top (fixed) | Session header — PID, mode, config (always visible) |
| Middle | Live Claude Code output |
| Bottom-left | `status.md` (refreshes every 3s) |
| Bottom-right | `master.log` tail |

```bash
tmux attach -t loom-<project>   # attach to the session
/loom status                     # view status summary
```

### Stopping

```bash
touch .loom/.stop                        # graceful — finishes current iteration
tmux kill-session -t loom-<project>      # immediate
/loom stop                               # from Claude Code
```

## Safety

Loom enforces safety through Claude Code hooks and automatic circuit breakers — not just prompt instructions.

### Hooks

| Hook | Purpose |
|------|-------|
| `bash-guard.sh` | Blocks destructive commands (`rm -rf /`, `git push --force`, etc.) |
| `block-interactive.sh` | Prevents `EnterPlanMode` and `AskUserQuestion` (no human present) |
| `block-task-output.sh` | Prevents `TaskOutput` polling (results auto-deliver) |
| `background-tasks.sh` | Forces all subagents to run in background |
| `status-kill.sh` | Hard-kills the agent when `status.md` is written |
| `stop-guard.sh` | Blocks exit until `status.md` has been updated |
| `subagent-recall.sh` | Nudges subagents to check .docs, CLAUDE.md, and memory before starting |
| `subagent-stop-guard.sh` | Validates subagent output and nudges to update docs + memory |

### Circuit breakers

Loom won't run forever. It stops when:

- **All stories done** — emits `LOOM_RESULT:DONE`
- **Consecutive failures** — 3 failures in a row trips the circuit breaker (configurable with `--max-failures`)
- **Max iterations** — hard cap at 500 (configurable with `--max-iterations`)
- **Graceful stop** — `touch .loom/.stop`
- **Timeout** — per-iteration timeout kills stuck runs (configurable with `--timeout`)

## PRD format

`.loom/prd.json` contains gates (priority-ordered story groups) and stories:

```json
{
  "project": "my-app",
  "description": "A brief project description.",
  "gates": [
    {
      "id": "gate-1",
      "name": "Core Infrastructure",
      "priority": "P0",
      "status": "pending",
      "stories": ["APP-001", "APP-002"]
    },
    {
      "id": "gate-2",
      "name": "Features",
      "priority": "P1",
      "status": "pending",
      "stories": ["APP-003", "APP-004"]
    }
  ],
  "stories": [
    {
      "id": "APP-001",
      "title": "Add user authentication",
      "gate": "gate-1",
      "priority": "P0",
      "severity": "critical",
      "status": "pending",
      "files": ["src/auth/router.ts", "src/auth/middleware.ts"],
      "description": "Implement JWT-based auth with login/signup endpoints.",
      "acceptanceCriteria": [
        "POST /auth/login returns a JWT",
        "POST /auth/signup creates a user and returns a JWT",
        "Protected routes return 401 without a valid token"
      ],
      "actionItems": [
        "Create auth middleware that validates JWT from Authorization header",
        "Add login route with bcrypt password comparison",
        "Add signup route with input validation"
      ],
      "blockedBy": [],
      "tools": [],
      "details": {}
    }
  ]
}
```

**Required fields** on every story: `id`, `title`, `gate`, `priority`, `severity`, `status`, `files`, `description`, `acceptanceCriteria`, `actionItems`, `blockedBy`, `tools`, `details`.

- `severity`: `"critical"` | `"major"` | `"minor"`
- `actionItems`: concrete implementation steps (what to do)
- `acceptanceCriteria`: concrete verification steps (what to check)
- `tools`: array of capability categories the story requires (`"browser"`, `"mobile"`, `"design"`). Defaults to `[]`. Stories with tool requirements are skipped when the required MCP servers aren't installed. Auto-detected from acceptance criteria by `/prd`.
- `details`: object for arbitrary project-specific metadata (always present, `{}` when empty)

Loom uses `jq` to read stories in waves of 10 (never loading the full file), selects stories whose `blockedBy` dependencies are resolved, and dispatches them as parallel subagents.

Statuses: `pending` → `in_progress` → `done` | `blocked` | `cancelled`

## File structure

```
.claude/skills/
├── loom/
│   ├── SKILL.md          # /loom skill (router)
│   ├── exec.md           # /loom — loop execution
│   └── setup.md          # /loom setup — fetches and runs setup guides
└── prd/SKILL.md          # /prd skill (PRD generator)

.loom/
├── start.sh              # Main loop controller
├── loom-status.sh       # Status reporter
├── prd.sh          # Standalone PRD generator
├── stop.sh               # Graceful stop helper
├── prompt.md             # PRD mode prompt template
├── directive.md          # Directive mode prompt template
├── prd.json              # Your project stories
├── status.md             # Inter-iteration state (auto-managed)
├── hooks/
│   ├── background-tasks.sh
│   ├── bash-guard.sh
│   ├── block-interactive.sh
│   ├── block-task-output.sh
│   ├── status-kill.sh
│   ├── stop-guard.sh
│   ├── subagent-recall.sh
│   └── subagent-stop-guard.sh
└── logs/                 # Per-iteration logs + master.log
```

## License

MIT
