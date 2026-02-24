# Quick Task

Run a focused task without a PRD — give Loom a directive and let it execute.

## When to Use

- You have a clear, bounded task: "fix all lint errors", "refactor callbacks to async/await", "add input validation to all forms"
- The work doesn't need decomposition into stories — it's one logical unit
- You want worktree isolation and auto-PR without PRD overhead

## From Claude Code

```bash
# Plain text directive
/loom Fix all TypeScript strict mode errors

# Refactoring
/loom Refactor all callback-based functions to async/await

# Code quality
/loom Add error handling to all API route handlers

# Testing
/loom Write unit tests for all functions in src/utils/
```

## From Bash

```bash
# Inline directive
.loom/start.sh --prompt "Fix all lint errors"

# Directive from a file
echo "Migrate all useState hooks to useReducer where state is complex" > task.md
.loom/start.sh --prompt task.md

# Piped input
echo "Add JSDoc comments to all exported functions" | .loom/start.sh
```

## What Happens

1. Loom creates a worktree (isolated branch)
2. Launches tmux with monitoring panes
3. Reads your directive and the project's memory (status.md + Vestige)
4. Dispatches subagents to parallelize independent pieces of work
5. Runs tests, fixes failures (up to 3 attempts)
6. Commits only green code
7. Pushes branch and creates a PR
8. Repeats until the directive is fully complete (`LOOM_RESULT:DONE`)

## Options

### Skip worktree and PR (work in current branch)

For quick changes you want to review before committing to a branch:

```bash
.loom/start.sh --prompt "Fix the typo in README.md" --worktree false --pr false
```

### Combine with external sources

Pull context from GitHub, Linear, or other sources alongside your directive:

```bash
# Fix the issue AND clean up related code
.loom/start.sh --github 42 --prompt "Also fix the related lint warnings"

# Implement a Linear ticket with extra instructions
.loom/start.sh --linear TEAM-42 --prompt "Use the existing auth middleware, don't create a new one"
```

### Limit iterations

For tasks that should complete in one pass:

```bash
.loom/start.sh --prompt "Fix the failing test in tests/auth.spec.ts" --max-iterations 3
```

### Dry run

Preview what Loom will do without making changes:

```bash
/loom dry-run
# Note: dry-run only works for PRD mode from the slash command
# For directive dry runs, use the bash script:
.loom/start.sh --prompt "Fix all lint errors" --dry-run
```

## Monitoring

```bash
# Attach to tmux
tmux attach -t loom-<project>

# Check status
/loom status
```

## Stopping

```bash
# Graceful — finishes current iteration
touch .loom/.stop

# Immediate
tmux kill-session -t loom-<project>

# From Claude Code
/loom stop
```

## Tips

- **Be specific.** "Fix all TypeScript errors" is better than "fix the code". "Add input validation to all POST handlers in src/api/" is better than "add validation".
- **Scope it.** If the task is large and multi-faceted, consider using PRD mode instead (see [Large Feature](large-feature.md)).
- **Combine sources** when you want external context plus custom instructions. The directive and external source are merged into a single prompt for the agent.
- **One logical unit.** Directive mode treats the entire task as one unit. If you need dependency ordering or gate prioritization, use PRD mode.
