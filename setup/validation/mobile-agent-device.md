# agent-device

Token-efficient mobile automation via CLI skill — iOS Simulator, Android Emulator, and physical devices.

[agent-device](https://github.com/callstackincubator/agent-device) is a lightweight CLI from Callstack that integrates with Claude Code as a **skill**. The agent runs `agent-device` commands via Bash — no MCP server, no tool discovery. The skill is loaded into context at Claude start, so subagents automatically know the available commands.

For the MCP-based alternative with Loom capability auto-detection, see [Mobile MCP](mobile-mcp.md).

| | Mobile MCP | agent-device |
|---|-----------|-------------|
| Integration | MCP server (tool calls) | CLI skill (Bash commands) |
| Capability detection | Auto-detected as `mobile` | Not auto-detected (skill-based) |
| `tools` field gating | Stories gated by `"tools": ["mobile"]` | No gating — always available if installed |
| Token efficiency | Standard MCP overhead | Designed for minimal token usage |
| Snapshots | Screenshots | Accessibility tree snapshots + screenshots |
| Replay | No | Deterministic replay sessions |

## Prerequisites

### iOS

1. Verify Xcode is installed:
   ```bash
   xcode-select -p
   ```
   If missing, install from the Mac App Store or `xcode-select --install`.

2. Boot a simulator before starting Loom:
   ```bash
   xcrun simctl boot "iPhone 16"
   ```

### Android

1. Verify Android SDK is installed:
   ```bash
   echo $ANDROID_HOME
   ```
   If missing, install [Android Studio](https://developer.android.com/studio) and configure `ANDROID_HOME`.

2. Start an emulator before starting Loom:
   ```bash
   $ANDROID_HOME/emulator/emulator -avd <avd_name> &
   ```

### Node.js

```bash
node --version
```

Requires Node.js 22+.

## Setup

### Step 1: Install the CLI

```bash
npm install -g agent-device
```

### Step 2: Install the skill

```bash
npx skills add callstackincubator/agent-device
```

The skill loads agent-device's documentation into Claude Code's context at startup, so subagents know the full command set without MCP discovery.

### Step 3: Verify

```bash
# Check the CLI works
agent-device devices --platform ios
agent-device devices --platform android

# Open an app and take a snapshot
agent-device open Settings --platform ios
agent-device snapshot --platform ios
```

## Commands

### Navigation

```bash
agent-device open <app>        # Open an app by name
agent-device open <url>        # Open a URL / deep link
agent-device back              # Navigate back
agent-device home              # Go to home screen
```

### Snapshots & Screenshots

```bash
agent-device snapshot          # Accessibility tree (token-efficient)
agent-device screenshot        # Full screenshot image
agent-device diff snapshot     # Diff against previous snapshot baseline
```

### Interactions

```bash
agent-device click @e2                      # Tap element by snapshot ID
agent-device long-press @e3                 # Long press
agent-device fill @e5 "user@example.com"    # Type into a field
agent-device swipe up                       # Swipe gesture
agent-device scroll down                    # Scroll
```

### Debugging

```bash
agent-device logs              # Stream app logs
agent-device appstate          # Current app state
agent-device apps              # List installed apps
```

All commands accept `--platform ios` or `--platform android`.

## Writing Stories

agent-device is not an MCP server, so it won't trigger Loom's `tools` field gating. Stories don't need `"tools": ["mobile"]` — the subagent uses agent-device commands directly if the skill is installed.

### Instruct subagents via actionItems

```json
{
  "id": "APP-015",
  "title": "Build onboarding carousel with swipe navigation",
  "gate": "gate-2",
  "priority": "P1",
  "severity": "major",
  "status": "pending",
  "files": ["src/screens/Onboarding.tsx", "src/components/Carousel.tsx"],
  "description": "Create a three-screen onboarding carousel with swipe navigation, skip button, and get-started CTA on the final screen.",
  "acceptanceCriteria": [
    "Onboarding screen renders on app launch for first-time users",
    "Three carousel pages display in order: Welcome, Features, Get Started",
    "Swipe left advances to the next page with smooth animation",
    "Swipe right returns to the previous page",
    "Page indicator dots update to reflect the current page",
    "Skip button on pages 1-2 jumps to the Get Started page",
    "Get Started button on the final page navigates to the home screen"
  ],
  "actionItems": [
    "Create Carousel component with horizontal scroll and snap behavior",
    "Create three onboarding page components with content",
    "Add page indicator dots that sync with scroll position",
    "Add skip button on first two pages",
    "Add Get Started button on final page with navigation",
    "Use agent-device to open the app, take snapshots, and verify each carousel page",
    "Use agent-device swipe and click to verify navigation between pages"
  ],
  "blockedBy": ["APP-001"],
  "tools": [],
  "sources": [],
  "details": {}
}
```

Note `"tools": []` — no capability gating. The story runs regardless of MCP configuration.

### Or document it in CLAUDE.md

Add to your project's `CLAUDE.md` so all subagents know to use it:

```markdown
## Mobile Validation

Use agent-device for mobile verification:
- `agent-device snapshot --platform ios` for accessibility tree
- `agent-device screenshot --platform ios` for visual verification
- `agent-device click @<id>` to interact with elements
- `agent-device diff snapshot` to compare against baseline
```

## What Happens at Runtime

1. **Skill loading** — Claude Code loads the agent-device skill into context at startup. Subagents inherit it automatically.

2. **Story selection** — Stories with `"tools": []` are always eligible regardless of `LOOM_CAPABILITIES`. No gating.

3. **Subagent execution** — The subagent:
   - Implements the feature code
   - Runs `agent-device open` to launch the app in the simulator
   - Runs `agent-device snapshot` to inspect the accessibility tree (token-efficient — no image transfer)
   - Runs `agent-device click`, `agent-device swipe`, etc. to verify interactions
   - Runs `agent-device screenshot` for visual verification when needed
   - Writes durable test files using the project's test framework
   - All commands run via Bash — no MCP tool calls

4. **Test verification** — The orchestrator runs the full test suite as usual.

## Troubleshooting

**"agent-device: command not found"**
- Install globally: `npm install -g agent-device`
- Or use via npx: `npx agent-device snapshot --platform ios`

**Skill not loaded / subagent doesn't know the commands**
- Re-add the skill: `npx skills add callstackincubator/agent-device`
- Document commands in your project's `CLAUDE.md` as a fallback

**No devices found**
- Boot a simulator/emulator before starting Loom
- iOS: `xcrun simctl boot "iPhone 16"`
- Android: `$ANDROID_HOME/emulator/emulator -avd <name> &`
- Check with `agent-device devices --platform ios` or `--platform android`

**Snapshot returns empty tree**
- The app may not have loaded yet. Add a wait: `agent-device wait 2 && agent-device snapshot`
- Some screens take time to render — retry after a short delay

**Gestures don't register**
- Verify the element ID from the latest snapshot — IDs change between snapshots
- Use `agent-device snapshot` immediately before interacting to get fresh IDs
