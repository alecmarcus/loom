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
# ─── Loom Subagent Recall Nudge ───────────────────────────────
# Injects context at subagent start reminding it to check .docs,
# CLAUDE.md, and available memory tools before diving into work.
# ─────────────────────────────────────────────────────────────────

# No-op outside Loom — detect via .loom marker file instead of env var
LOOM_DIR="${PWD}/.loom"
[ -f "$LOOM_DIR/.pid" ] || LOOM_DIR="${CLAUDE_PROJECT_DIR:-.}/.loom"
[ -f "$LOOM_DIR/.pid" ] || exit 0

# No enforcement in preview
[ "$LOOM_PREVIEW" = "1" ] && exit 0
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [subagent-recall] injecting context" >> "$LOOM_DIR/logs/debug.log" 2>/dev/null || true

jq -n '{
  hookSpecificOutput: {
    hookEventName: "SubagentStart",
    additionalContext: "Before starting work, check for existing knowledge that may help:\n  - Read any .docs/ directories and CLAUDE.md files in the feature areas you are about to modify — they contain design notes, conventions, and gotchas from previous iterations.\n  - Use any available memory storage or tools to recall patterns, decisions, and warnings relevant to this task.\nDo not skip this step — previous iterations may have documented critical constraints or pitfalls."
  }
}'
