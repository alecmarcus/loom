#!/usr/bin/env bash
# ─── Loom Subagent Recall Nudge ───────────────────────────────
# Injects context at subagent start reminding it to check .docs,
# CLAUDE.md, and available memory tools before diving into work.
# ─────────────────────────────────────────────────────────────────

# No-op outside Loom
[ "$LOOM_ACTIVE" != "1" ] && exit 0

# No enforcement in preview
[ "$LOOM_PREVIEW" = "1" ] && exit 0

LOOM_DIR="${CLAUDE_PROJECT_DIR:-.}/.loom"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [subagent-recall] injecting context" >> "$LOOM_DIR/logs/debug.log" 2>/dev/null || true

jq -n '{
  hookSpecificOutput: {
    hookEventName: "SubagentStart",
    additionalContext: "Before starting work, check for existing knowledge that may help:\n  - Read any .docs/ directories and CLAUDE.md files in the feature areas you are about to modify — they contain design notes, conventions, and gotchas from previous iterations.\n  - Use any available memory storage or tools to recall patterns, decisions, and warnings relevant to this task.\nDo not skip this step — previous iterations may have documented critical constraints or pitfalls."
  }
}'
