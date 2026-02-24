# Mobile MCP

Enable iOS Simulator and Android Emulator testing in Loom runs via MCP — screenshots, tap, swipe, and app state verification.

For a lighter-weight CLI alternative, see [agent-device](mobile-agent-device.md).

## Prerequisites

### iOS

1. Verify Xcode is installed:
   ```bash
   xcode-select -p
   ```
   If missing, install from the Mac App Store or `xcode-select --install`.

2. Verify the iOS Simulator is available:
   ```bash
   xcrun simctl list devices available | head -20
   ```
   You need at least one available device.

3. Boot a simulator before starting Loom:
   ```bash
   # List available devices
   xcrun simctl list devices available

   # Boot a specific device (example: iPhone 16)
   xcrun simctl boot "iPhone 16"

   # Or open Simulator.app (boots the last-used device)
   open -a Simulator
   ```

### Android

1. Verify Android SDK is installed:
   ```bash
   echo $ANDROID_HOME
   ```
   If missing, install [Android Studio](https://developer.android.com/studio) and configure `ANDROID_HOME`.

2. Verify an emulator is available:
   ```bash
   $ANDROID_HOME/emulator/emulator -list-avds
   ```

3. Start an emulator before starting Loom:
   ```bash
   $ANDROID_HOME/emulator/emulator -avd <avd_name> &
   ```

### Both platforms

4. Verify Node.js is installed:
   ```bash
   node --version
   ```

## Setup

### Step 1: Install the Mobile MCP server

```bash
claude mcp add mobile -- npx -y @mobilenext/mobile-mcp@latest
```

### Step 2: Project-scope the MCP (recommended)

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "mobile": {
      "command": "npx",
      "args": ["-y", "@mobilenext/mobile-mcp@latest"]
    }
  }
}
```

Loom copies `.mcp.json` into worktrees automatically.

### Step 3: Verify capability detection

Start a Loom dry run and check the header:

```bash
.loom/start.sh --dry-run
```

The tmux header should show:

```
MCPs  mobile
```

This confirms Loom detected the Mobile MCP and mapped it to the `mobile` capability.

## Writing Stories

### Auto-detection keywords

When you use `/prd` to generate stories, it auto-detects the `tools` field from acceptance criteria. The following keywords trigger `"tools": ["mobile"]`:

- `mobile app`, `simulator`, `emulator`, `gesture`, `tap`, `swipe`, `pinch`, `press`, `hold`, `drag`, `iOS`, `Android`, `app screen`, `push notification`

### Example PRD story

```json
{
  "id": "APP-015",
  "title": "Build onboarding carousel with swipe navigation",
  "gate": "gate-2",
  "priority": "P1",
  "severity": "major",
  "status": "pending",
  "files": ["src/screens/Onboarding.tsx", "src/components/Carousel.tsx", "e2e/onboarding.test.ts"],
  "description": "Create a three-screen onboarding carousel with swipe navigation, skip button, and get-started CTA on the final screen.",
  "acceptanceCriteria": [
    "Onboarding screen renders on app launch for first-time users",
    "Three carousel pages display in order: Welcome, Features, Get Started",
    "Swipe left advances to the next page with smooth animation",
    "Swipe right returns to the previous page",
    "Page indicator dots update to reflect the current page",
    "Skip button on pages 1-2 jumps to the Get Started page",
    "Get Started button on the final page navigates to the home screen",
    "Screenshot of each carousel page shows correct content and layout",
    "Carousel does not scroll past the first or last page"
  ],
  "actionItems": [
    "Create Carousel component with horizontal scroll and snap behavior",
    "Create three onboarding page components with content",
    "Add page indicator dots that sync with scroll position",
    "Add skip button on first two pages",
    "Add Get Started button on final page with navigation",
    "Write e2e tests for swipe navigation and button behavior"
  ],
  "blockedBy": ["APP-001"],
  "tools": ["mobile"],
  "sources": [],
  "details": {}
}
```

### Writing effective mobile acceptance criteria

- **Specify gestures**: "swipe left advances to the next page" not "user can navigate between pages"
- **Include visual state**: "page indicator dots update to reflect the current page"
- **Name screens and elements**: "three carousel pages: Welcome, Features, Get Started"
- **Specify edge cases**: "carousel does not scroll past the first or last page"
- **Request screenshots**: "screenshot of each carousel page shows correct content and layout"

## What Happens at Runtime

1. **Capability detection** — Loom's `start.sh` scans `.mcp.json`, finds `mobile`, maps it to `mobile` via `CAPABILITY_MAP`, exports `LOOM_CAPABILITIES=mobile`.

2. **Story selection** — Stories with `"tools": ["mobile"]` are only selected when `mobile` is in `LOOM_CAPABILITIES`. Without Mobile MCP installed, these stories stay `pending`.

3. **Subagent execution** — The subagent:
   - Implements the feature code
   - Uses Mobile MCP tools to take simulator/emulator screenshots for visual verification
   - Simulates tap and swipe gestures to verify interactive behavior
   - Checks app state (current screen, element visibility) via MCP tools
   - Writes durable test files using the project's mobile test framework (Detox, Maestro, etc.)
   - MCP tools are discovered dynamically via `ListMcpResourcesTool`

4. **Test verification** — The orchestrator runs the full test suite. Mobile tests that interact with the simulator/emulator run as part of the suite.

## Simulator Management

### Before starting Loom

The simulator/emulator must be running before you start Loom. Loom does not boot simulators automatically.

```bash
# iOS: boot and verify
xcrun simctl boot "iPhone 16"
xcrun simctl list devices booted

# Android: start and verify
$ANDROID_HOME/emulator/emulator -avd Pixel_7_API_34 &
adb devices
```

### App installation

If your stories require the app to be installed on the simulator:

```bash
# iOS: build and install
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' build
xcrun simctl install booted path/to/MyApp.app

# Android: build and install
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

Consider adding app build/install steps to your story's `actionItems` or as a prerequisite story in the PRD.

### State reset between tests

For clean test runs, reset simulator state:

```bash
# iOS: erase all content and settings
xcrun simctl erase booted

# Android: clear app data
adb shell pm clear com.your.app
```

## Example Test Output

A subagent working on the onboarding story might generate:

```typescript
// e2e/onboarding.test.ts (Detox example)
import { device, element, by, expect } from 'detox';

describe('Onboarding Carousel', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('shows welcome page on first launch', async () => {
    await expect(element(by.text('Welcome'))).toBeVisible();
    await expect(element(by.id('page-indicator-0'))).toHaveValue('active');
  });

  it('swipe left advances to features page', async () => {
    await element(by.id('carousel')).swipe('left');
    await expect(element(by.text('Features'))).toBeVisible();
    await expect(element(by.id('page-indicator-1'))).toHaveValue('active');
  });

  it('swipe right returns to welcome page', async () => {
    await element(by.id('carousel')).swipe('right');
    await expect(element(by.text('Welcome'))).toBeVisible();
  });

  it('skip button jumps to get started page', async () => {
    await element(by.id('skip-button')).tap();
    await expect(element(by.text('Get Started'))).toBeVisible();
    await expect(element(by.id('get-started-button'))).toBeVisible();
  });

  it('get started button navigates to home', async () => {
    await element(by.id('get-started-button')).tap();
    await expect(element(by.id('home-screen'))).toBeVisible();
  });

  it('does not scroll past first page', async () => {
    await device.launchApp({ newInstance: true });
    await element(by.id('carousel')).swipe('right');
    await expect(element(by.text('Welcome'))).toBeVisible();
  });
});
```

## Troubleshooting

**Mobile MCP not detected (no `mobile` in MCPs line)**
- Verify `.mcp.json` has a `mobile` key (or `mobile-mcp` or `appium` — all map to `mobile`)
- Run `claude mcp list` to check registration
- Ensure Node.js is installed

**"No simulator/emulator found"**
- Boot the simulator/emulator before starting Loom
- iOS: `xcrun simctl boot "iPhone 16"`
- Android: `$ANDROID_HOME/emulator/emulator -avd <name> &`
- Verify with `xcrun simctl list devices booted` or `adb devices`

**App not installed on simulator**
- Build and install the app before starting Loom
- Or add build/install steps to your story's `actionItems`
- Check that the app bundle ID matches what tests expect

**Screenshots are black or show the home screen**
- The app may have crashed. Check simulator logs:
  - iOS: `xcrun simctl spawn booted log stream --level error`
  - Android: `adb logcat *:E`
- Ensure the app is in the foreground before taking screenshots

**Gesture timing issues**
- Mobile MCP gestures may execute faster than animations complete
- Add explicit waits in test files: `await waitFor(element(by.id('target'))).toBeVisible().withTimeout(5000)`
- Reduce animation duration in test builds if possible

**Stories with `"tools": ["mobile"]` are skipped**
- Check `LOOM_CAPABILITIES` in the tmux header
- If `mobile` is missing, the MCP server isn't configured
- Verify `.mcp.json` is in the project root (not a subdirectory)

