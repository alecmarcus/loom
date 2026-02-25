#!/usr/bin/env bash
# Kill a specific Loom run or list running Looms for this project.
PROJECT_NAME="$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"

if [ "${1:-}" = "--all" ]; then
  # Kill all Loom sessions for this project
  sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^loom-${PROJECT_NAME}" || true)
  if [ -z "$sessions" ]; then
    echo "No Loom sessions running."
  else
    echo "$sessions" | while read -r s; do
      tmux kill-session -t "$s" 2>/dev/null && echo "Killed $s"
    done
  fi
elif [ -n "${1:-}" ]; then
  # Kill specific session by slug
  tmux kill-session -t "loom-${PROJECT_NAME}-${1}" 2>/dev/null && \
    echo "Killed loom/${1}." || echo "No Loom '${1}' running."
else
  # List and kill all Loom sessions for this project
  sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^loom-${PROJECT_NAME}" || true)
  if [ -z "$sessions" ]; then
    echo "No Loom sessions running."
  elif [ "$(echo "$sessions" | wc -l | tr -d ' ')" -eq 1 ]; then
    tmux kill-session -t "$sessions" && echo "Loom killed."
  else
    echo "Multiple Loom sessions running:"
    echo "$sessions" | sed 's/^/  /'
    echo ""
    echo "Kill a specific one: loom:kill <slug>"
    echo "Kill all: loom:kill --all"
  fi
fi
