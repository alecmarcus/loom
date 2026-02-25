#!/usr/bin/env bash
# Graceful stop — signals the loop to halt after the current iteration.
# Uses CWD-relative .loom/ (per-project state), not script-relative.
LOOM_DIR="${CLAUDE_PROJECT_DIR:-.}/.loom"
touch "$LOOM_DIR/.stop"
