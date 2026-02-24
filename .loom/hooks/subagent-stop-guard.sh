#!/usr/bin/env bash
# ─── Loom Subagent Stop Guard ───────────────────────────────────
# Validates that a subagent produced meaningful output before
# the orchestrator accepts its result. Only active in Loom loops.
# ─────────────────────────────────────────────────────────────────

# No-op outside Loom
[ "$LOOM_ACTIVE" != "1" ] && exit 0

# No enforcement in dry-run
[ "$LOOM_DRY_RUN" = "1" ] && exit 0

INPUT=$(cat)

MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

# If the subagent produced no output at all, block so the
# orchestrator knows something went wrong.
if [ -z "$MESSAGE" ] || [ ${#MESSAGE} -lt 10 ]; then
  jq -n --arg reason "Subagent returned no meaningful output. Log this failure in status.md and continue with remaining work." '{
    decision: "block",
    reason: $reason
  }'
  exit 0
fi

# ─── Check: documentation updated ──────────────────────────────
# Nudge subagents to maintain .docs artifacts alongside code changes.
# This is advisory (block + continue), not a hard gate.

NUDGES=""

# Check if the subagent touched code but didn't mention .docs updates
if echo "$MESSAGE" | grep -qiE '(created|added|implemented|built|wrote)' && \
   ! echo "$MESSAGE" | grep -qiE '(\.docs|CLAUDE\.md|documentation|ADR|adr|lessons)'; then
  NUDGES="Documentation reminder: If your changes introduce new patterns, architectural decisions, or lessons learned, update the relevant .docs/ artifacts and/or CLAUDE.md:
  - Root .docs/ and CLAUDE.md for project-wide knowledge (ADRs, specs, lessons, architecture)
  - Feature-scoped .docs/ and CLAUDE.md (e.g. src/auth/.docs/) for feature-specific design notes, API decisions, and internal conventions
  Create feature-scoped .docs/ directories when a feature area has design context worth preserving close to the code."
fi

# Check if the subagent discovered patterns/gotchas but didn't mention Vestige
if echo "$MESSAGE" | grep -qiE '(pattern|gotcha|workaround|discovered|learned|tricky|edge case|caveat)' && \
   ! echo "$MESSAGE" | grep -qiE '(vestige|mcp__vestige|smart_ingest|remember_pattern|remember_decision|memory)'; then
  NUDGES="${NUDGES:+$NUDGES

}Memory reminder: If you discovered patterns, gotchas, or architectural decisions worth preserving, store them in Vestige so future iterations can benefit:
  - Code patterns: mcp__vestige__codebase(action: \"remember_pattern\", ...)
  - Architectural decisions: mcp__vestige__codebase(action: \"remember_decision\", ...)
  - Gotchas/warnings: mcp__vestige__smart_ingest(content: \"...\", tags: [\"<project>\", \"gotcha\"])"
fi

if [ -n "$NUDGES" ]; then
  jq -n --arg reason "$NUDGES" '{
    decision: "block",
    reason: $reason
  }'
  exit 0
fi

exit 0
