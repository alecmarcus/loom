#!/usr/bin/env bash
# Immediate kill — terminates the tmux session without waiting.
PROJECT_NAME="$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"
tmux kill-session -t "loom-${PROJECT_NAME}" 2>/dev/null && echo "Loom killed." || echo "Loom is not running."
