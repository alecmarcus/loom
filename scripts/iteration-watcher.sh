#!/usr/bin/env bash
# ─── Loom Iteration Watcher ──────────────────────────────────────
# Watches iterations.log for the next new entry or loop termination.
# Designed to run as a background Task in the interactive Claude
# session. Exits when:
#   1. A new iteration completes (outputs the new log line(s))
#   2. The tmux session dies (outputs LOOP_TERMINATED + final lines)
#
# Usage: iteration-watcher.sh <session-name> [loom-dir]
# ─────────────────────────────────────────────────────────────────

SESSION="${1:?Usage: iteration-watcher.sh <session-name> [loom-dir]}"
LOOM_DIR="${2:-.loom}"
LOGFILE="$LOOM_DIR/logs/iterations.log"

# Baseline: current line count at launch
BASELINE=$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)

while true; do
  # Check for new iteration entries
  CURRENT=$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)
  if [ "$CURRENT" -gt "$BASELINE" ]; then
    tail -n $((CURRENT - BASELINE)) "$LOGFILE"
    exit 0
  fi

  # Check if loop is still running
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "LOOP_TERMINATED"
    [ -f "$LOGFILE" ] && tail -3 "$LOGFILE"
    exit 0
  fi

  sleep 3
done
