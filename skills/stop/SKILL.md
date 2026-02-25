---
name: stop
description: Gracefully stop the Loom loop. Signals the loop to finish the current iteration and then halt.
argument-hint: ""
disable-model-invocation: true
allowed-tools: Bash, Read
---

# /loom:stop

Graceful stop — signals the loop to finish the current iteration, then halt.

All scripts are located via the plugin root path stored in `.loom/.plugin_root`. Read it first:

```bash
LOOM="$(cat .loom/.plugin_root)"
```

Then run the stop script:

```bash
LOOM="$(cat .loom/.plugin_root)" && "$LOOM/scripts/stop.sh" && echo "Loom will stop after the current iteration." || echo "Failed to signal stop."
```
