---
name: kill
description: Immediately kill the Loom loop by terminating the tmux session without waiting for the current iteration to finish.
argument-hint: ""
disable-model-invocation: true
allowed-tools: Bash
---

# /loom:kill

Immediately kill the Loom loop by terminating the tmux session.

```bash
tmux kill-session -t "loom-$(basename "$PWD")" 2>/dev/null && echo "Loom killed." || echo "Loom is not running."
```
