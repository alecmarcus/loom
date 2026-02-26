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
DEBUG_LOG="$LOOM_DIR/logs/debug.log"

_dbg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [iter-watcher] $1" >> "$DEBUG_LOG" 2>/dev/null || true; }

# Baseline: current line count at launch
BASELINE=$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)
_dbg "started. session=$SESSION logfile=$LOGFILE baseline=$BASELINE"

POLL=0
while true; do
  POLL=$((POLL + 1))

  # Check for new iteration entries
  CURRENT=$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)
  if [ "$CURRENT" -gt "$BASELINE" ]; then
    NEW_LINES=$((CURRENT - BASELINE))
    _dbg "poll=$POLL: NEW LINES detected ($BASELINE→$CURRENT, +$NEW_LINES). Exiting with iteration data."
    tail -n "$NEW_LINES" "$LOGFILE"
    exit 0
  fi

  # Check if loop is still running
  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    _dbg "poll=$POLL: tmux session '$SESSION' is GONE. Outputting LOOP_TERMINATED."
    echo "LOOP_TERMINATED"
    [ -f "$LOGFILE" ] && tail -3 "$LOGFILE"
    exit 0
  fi

  # Log every 20th poll (~60s) to avoid flooding
  if [ $((POLL % 20)) -eq 0 ]; then
    _dbg "poll=$POLL: still waiting (baseline=$BASELINE current=$CURRENT session=$SESSION)"
  fi

  sleep 3
done
