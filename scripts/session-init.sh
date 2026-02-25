#!/usr/bin/env bash
# ─── Loom Session Init ────────────────────────────────────────
# Runs on every Claude Code session start (via SessionStart hook).
# Writes the plugin root path to .loom/.plugin_root so skills
# can locate scripts at runtime.
# Only activates if the project has been initialized for Loom.
# ─────────────────────────────────────────────────────────────────

# Only activate if this project has been initialized for Loom
[ -d ".loom" ] || exit 0

# Write plugin root for skill script discovery
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "$PLUGIN_ROOT" > .loom/.plugin_root

exit 0
