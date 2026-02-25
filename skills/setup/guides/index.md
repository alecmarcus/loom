# Setup Guides

Step-by-step guides for Loom — written as agent-executable instructions. Run `/loom:setup <name>` to have an agent fetch and execute any guide, or browse them here.

## Usage

| Guide | When to use |
|-------|-------------|
| [Large Feature](large-feature.md) | Build a multi-story feature from specs using PRD mode |
| [Quick Task](quick-task.md) | Run a focused directive without PRD overhead |
| [PRD Creation](prd-creation.md) | Generate, review, and refine PRDs from spec files |
| [GitHub Issues](github-issues.md) | Implement GitHub issues — fetch, build, close |
| [Linear Tickets](linear-tickets.md) | Implement Linear tickets — fetch, build, update |
| [External Sources](external-sources.md) | Pull work from Slack, Notion, or Sentry |
| [Testing](testing.md) | Configure test suites for any language/framework |
| [Worktrees & PRs](worktrees-and-prs.md) | Control isolation, branching, and PR creation |

## Validation

Guides for visual, browser, and mobile validation — verifying that output looks and behaves correctly.

| Guide | Capability | What it sets up |
|-------|-----------|-----------------|
| [Playwright](validation/playwright.md) | `browser` | Browser testing, screenshots, DOM verification |
| [Mobile MCP](validation/mobile-mcp.md) | `mobile` | iOS Simulator & Android Emulator via MCP |
| [agent-device](validation/mobile-agent-device.md) | — | iOS & Android via CLI skill (token-efficient) |
| [Figma](validation/figma.md) | `design` | Design token extraction & visual fidelity |
| [Custom MCP](validation/custom-mcp.md) | any | Extend Loom with any MCP server |

Loom auto-detects MCP servers from your project's `.mcp.json` at startup. Known servers map to capability categories (`browser`, `mobile`, `design`). PRD stories declare required capabilities in their `tools` field — stories are skipped when the capability isn't available. See [Custom MCP](validation/custom-mcp.md) for the full detection pipeline.
