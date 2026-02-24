# Worktrees & PRs

Control how Loom isolates work and delivers results — worktree branches, PRs, or direct commits.

## Default Behavior

By default, Loom:
1. Creates a git worktree — an isolated branch so your main tree stays clean
2. Does all work in the worktree
3. Pushes the branch when the loop completes
4. Creates a PR automatically

This is the safest mode: your working directory is never modified, and all changes arrive as a reviewable PR.

## Worktree Isolation

### How it works

Loom creates worktrees in `.claude/worktrees/` with a generated branch name. The worktree is a full copy of your repo on a separate branch — changes in the worktree don't affect your main branch.

Key behaviors:
- `.mcp.json` is automatically copied into the worktree so MCP servers work
- `.loom/status.md` and `.loom/prd.json` are shared (read from the worktree copy)
- Commits happen on the worktree branch, not your current branch

### Disable worktree (work in current branch)

```bash
.loom/start.sh --worktree false
```

Use this when:
- You want changes applied directly to your current branch
- You're already on a feature branch and don't need another
- You're doing a quick fix that doesn't need isolation

**Warning:** Without worktree isolation, Loom commits directly to your current branch. If something goes wrong, you'll need to revert manually.

## PR Creation

### Default: auto-PR

When the loop completes (all stories done, or stopped gracefully):
1. The worktree branch is pushed to the remote
2. A PR is created with a summary of all changes
3. The PR links back to the stories/issues that were implemented

PRs are only created if at least one iteration completed work (prevents empty PRs on `--resume` with no changes).

### Disable PR

```bash
.loom/start.sh --pr false
```

Use this when:
- You want to review changes locally before pushing
- You're working without worktree isolation (changes are on your current branch)
- You'll push and create the PR manually

### Combine: no worktree, no PR

```bash
.loom/start.sh --worktree false --pr false
```

This is the most "direct" mode — Loom commits to your current branch and doesn't push or create a PR. Useful for:
- Local development where you want Loom to do work but you'll handle git workflow yourself
- Quick fixes: `/loom "Fix the typo in README.md"` with `--worktree false --pr false`

## Resuming

### Resume the most recent worktree

```bash
.loom/start.sh --resume
```

This resumes the worktree at the current directory (or the most recently used worktree).

### Resume a specific worktree

```bash
# By path
.loom/start.sh --resume /path/to/.claude/worktrees/loom/abc123-myproject

# By branch name
.loom/start.sh --resume loom/abc123-myproject
```

### When to resume

- Loom stopped due to a circuit breaker (consecutive failures, timeout) and you've fixed the underlying issue
- You ran `touch .loom/.stop` to pause work and want to continue
- You killed the tmux session but want to continue from where it left off
- The machine restarted mid-run

### What resume preserves

- The worktree branch and all its commits
- `.loom/status.md` (short-term memory from the last iteration)
- `.loom/prd.json` story statuses (completed stories stay `done`)
- Vestige long-term memory

## Common Patterns

### Feature branch workflow

```bash
# Start a feature with full isolation
.loom/start.sh --prompt "Implement user authentication"
# → creates worktree, works, pushes, creates PR

# Review the PR, merge it
# Worktree remains for reference, clean up with:
# rm -rf .claude/worktrees/loom/<branch>
```

### Iterate on current branch

```bash
# Work directly on your current branch, no PR
.loom/start.sh --worktree false --pr false --prompt "Fix all lint errors"
# → commits directly to your current branch
# Review with git log, push when ready
```

### Long-running feature with checkpoints

```bash
# Start the feature
.loom/start.sh

# After some iterations, stop gracefully
touch .loom/.stop
# Loom finishes current iteration, stops

# Review progress
/loom status
git log --oneline -20  # in the worktree

# Resume
.loom/start.sh --resume
```

### Multiple concurrent features

```bash
# Feature A on one worktree
.loom/start.sh --prompt "Add authentication"
# → creates worktree A

# Feature B on another worktree (from a different terminal)
.loom/start.sh --prompt "Add payment processing"
# → creates worktree B

# Both run concurrently in separate tmux sessions
tmux list-sessions  # shows loom-myproject-1, loom-myproject-2
```

## Troubleshooting

**"worktree already exists"**
- A previous worktree for this project wasn't cleaned up
- Use `--resume` to continue it, or remove it: `git worktree remove <path>`

**PR not created after loop**
- Check that `--pr` wasn't set to `false`
- PRs are only created if at least one iteration did work
- Check that the remote is accessible: `git remote -v`
- Check push permissions: `git push --dry-run`

**Can't find the worktree**
- Worktrees are in `.claude/worktrees/loom/`
- List all: `git worktree list`

**Changes on wrong branch**
- If you used `--worktree false`, changes are on your current branch
- Use `git stash` or `git reset` to undo if needed
- Default mode (with worktree) prevents this issue
