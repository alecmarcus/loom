---
name: status
description: Show the current Loom run summary — iteration count, story progress, active subagents, and recent activity.
argument-hint: ""
disable-model-invocation: true
allowed-tools: Bash, Read
---

# /loom:status

Show the current Loom run summary.

All scripts are located via the plugin root path stored in `.loom/.plugin_root`. Read it first:

```bash
LOOM="$(cat .loom/.plugin_root)"
```

Then run the status reporter:

```bash
LOOM="$(cat .loom/.plugin_root)" && "$LOOM/scripts/loom-status.sh"
```

Display the output to the user as-is.
