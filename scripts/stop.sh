#!/usr/bin/env bash
# Graceful stop — signals the loop to halt after the current iteration.
# If inside a worktree, stops that run. Otherwise, stops all runs.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOOM_DIR="$PROJECT_DIR/.loom"

# Check if we're inside a worktree (worktree .loom/ has its own .pid)
if [ -f "$LOOM_DIR/.pid" ]; then
  touch "$LOOM_DIR/.stop"
  echo "Stop signaled for this Loom run."
else
  # Source project — find worktrees and stop them
  WT_BASE="$HOME/.claude-worktrees/$(basename "$PROJECT_DIR")"
  stopped=0
  if [ -d "$WT_BASE" ]; then
    for wt in "$WT_BASE"/loom/*/; do
      if [ -d "$wt/.loom" ]; then
        touch "$wt/.loom/.stop"
        stopped=$((stopped + 1))
      fi
    done
  fi
  # Also signal the source project in case of a non-worktree run
  touch "$LOOM_DIR/.stop"
  if [ "$stopped" -gt 0 ]; then
    echo "Stop signaled for $stopped worktree run(s) + source."
  else
    echo "Stop signaled."
  fi
fi
