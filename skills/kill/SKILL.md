---
name: kill
description: Immediately kill a Loom run by terminating its tmux session. With no argument, kills the only running session or lists sessions if multiple are active.
argument-hint: "[slug | --all]"
disable-model-invocation: true
allowed-tools: Bash
---

# /loom:kill

Immediately kill a Loom run by terminating its tmux session.

All scripts are located via the plugin root path stored in `.loom/.plugin_root`. Read it first:

```bash
LOOM="$(cat .loom/.plugin_root)"
```

Then run the kill script, forwarding any argument the user provided:

```bash
LOOM="$(cat .loom/.plugin_root)" && "$LOOM/scripts/kill.sh" $ARGUMENTS
```

- No argument: kills the only session, or lists sessions if multiple are running.
- `<slug>`: kills the session for that specific run slug (e.g., `fix-login-bug`).
- `--all`: kills all Loom sessions for this project.
