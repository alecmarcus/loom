#!/usr/bin/env bash
# ─── Loom Steering Watcher ──────────────────────────────────────
# Background poller that watches for .loom/.steering and exits
# with the content when found. Designed to be launched by the
# orchestrator via `run_in_background: true` — when the file
# appears, this script exits and the result is delivered to the
# orchestrator automatically.
# ─────────────────────────────────────────────────────────────────

LOOM_DIR="${1:-.loom}"
STEERING_FILE="$LOOM_DIR/.steering"
POLL_INTERVAL="${2:-1}"

while true; do
  if [ -f "$STEERING_FILE" ]; then
    CONTENT=$(cat "$STEERING_FILE" 2>/dev/null) || continue
    [ -z "$CONTENT" ] && continue

    # Archive
    ARCHIVE="$LOOM_DIR/logs/steering-$(date '+%Y%m%d-%H%M%S').md"
    mkdir -p "$LOOM_DIR/logs"
    mv "$STEERING_FILE" "$ARCHIVE" 2>/dev/null || continue

    # Output steering to the orchestrator
    cat <<EOF

OPERATOR STEERING (injected mid-iteration):

$CONTENT

Apply these instructions immediately. They take priority over your current plan.
Acknowledge receipt by briefly noting the steering in your next output.
Then restart the steering watcher so you can receive further steering.

EOF

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [steering-watcher] Delivered ${#CONTENT} chars, archived to $ARCHIVE" >> "$LOOM_DIR/logs/debug.log" 2>/dev/null || true
    exit 0
  fi
  sleep "$POLL_INTERVAL"
done
