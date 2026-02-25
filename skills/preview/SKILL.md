---
name: preview
description: Run one Loom iteration in preview mode — analyzes tasks and plans execution without making any changes.
argument-hint: ""
disable-model-invocation: true
allowed-tools: Bash, Read, Write
---

# /loom:preview

Preview — analyze one iteration without executing changes. You must `unset CLAUDECODE` before running the script so nested `claude` invocations work.

All scripts are located via the plugin root path stored in `.loom/.plugin_root`. Read it first:

```bash
LOOM="$(cat .loom/.plugin_root)"
```

Then run:

```bash
LOOM="$(cat .loom/.plugin_root)" && unset CLAUDECODE && "$LOOM/scripts/start.sh" --preview
```

## After launching

Report back to the user (substitute the actual project directory name):
- Attach to monitor: `tmux attach -t loom-<project>`
- Kill the loop: `tmux kill-session -t loom-<project>`
