#!/usr/bin/env bash
# ─── Loom Session Init ────────────────────────────────────────
# Runs on every Claude Code session start (via SessionStart hook).
# Writes the plugin root path to .loom/.plugin_root so skills
# can locate scripts at runtime.
# Only activates if the project has been initialized for Loom.
# ─────────────────────────────────────────────────────────────────

# Only activate if this project has been initialized for Loom
[ -d ".loom" ] || exit 0

# Resolve plugin root: registry > $0 > existing .plugin_root
PLUGIN_ROOT=""
REGISTRY="$HOME/.claude/plugins/installed_plugins.json"

if [ -f "$REGISTRY" ] && command -v jq &>/dev/null; then
  # Find loom in the plugin registry — handles any marketplace prefix
  PLUGIN_ROOT=$(jq -r '
    .plugins | to_entries[]
    | select(.key | startswith("loom@"))
    | .value[0].installPath // empty
  ' "$REGISTRY" 2>/dev/null)
fi

# Fallback: infer from this script's location
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT" ]; then
  PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Sanity check: plugin root must contain scripts/start.sh
if [ -f "$PLUGIN_ROOT/scripts/start.sh" ]; then
  echo "$PLUGIN_ROOT" > .loom/.plugin_root
fi

exit 0
