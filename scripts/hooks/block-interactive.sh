# No-op outside Loom — detect via .loom/.pid with live PID check
_is_loom() {
  local d="$1"
  [ -f "$d/.pid" ] || return 1
  local pid; pid=$(cat "$d/.pid" 2>/dev/null) || return 1
  kill -0 "$pid" 2>/dev/null
}

LOOM_DIR="${PWD}/.loom"
_is_loom "$LOOM_DIR" || LOOM_DIR="${CLAUDE_PROJECT_DIR:-.}/.loom"
_is_loom "$LOOM_DIR" || exit 0#!/usr/bin/env bash
# ─── Loom Interactive Tool Blocker ─────────────────────────────
# Blocks EnterPlanMode and AskUserQuestion during autonomous Loom
# runs. No human is present — execute directly.
# Only active inside a Loom loop (LOOM_ACTIVE=1).
# ─────────────────────────────────────────────────────────────────

# No-op outside Loom — detect via .loom marker file instead of env var
LOOM_DIR="${PWD}/.loom"
[ -f "$LOOM_DIR/.pid" ] || LOOM_DIR="${CLAUDE_PROJECT_DIR:-.}/.loom"
[ -f "$LOOM_DIR/.pid" ] || exit 0
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [block-interactive] denied interactive tool" >> "$LOOM_DIR/logs/debug.log" 2>/dev/null || true

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "No human is present. Execute directly."
  }
}'
