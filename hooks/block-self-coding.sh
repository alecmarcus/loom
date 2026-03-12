#!/usr/bin/env bash
# PreToolUse hook: Block the orchestrator from writing code directly.
# The orchestrator must ALWAYS dispatch coder subagents — never edit files itself.
echo '{"decision":"block","reason":"BLOCKED: The orchestrator must NEVER write code directly. Dispatch a coder subagent instead. See orchestrator.md Rules."}'
