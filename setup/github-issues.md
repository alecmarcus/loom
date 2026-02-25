# GitHub Issues

Implement GitHub issues autonomously — fetch the issue, build it, close it.

## Prerequisites

1. Install and authenticate the GitHub CLI:
   ```bash
   brew install gh
   gh auth login
   ```

2. Verify authentication:
   ```bash
   gh auth status
   ```

3. Verify you can access the repo's issues:
   ```bash
   gh issue list --limit 5
   ```

## Single Issue

### By number

```bash
# From Claude Code
/loom:start github 42
/loom:start issue 42

# From bash
/loom:start github 42
```

### By URL

```bash
/loom:start github https://github.com/org/repo/issues/42
/loom:start github "https://github.com/org/repo/issues/42"
```

### What happens

1. Loom fetches the issue using `gh issue view 42 --json title,body,comments,labels,state`
2. Creates a worktree (isolated branch)
3. Reads the issue title, description, comments, and labels
4. Implements what's described in the issue
5. Runs tests and commits green code
6. Comments on the issue with a summary of changes
7. Closes the issue
8. Pushes the branch and creates a PR

## Multiple Issues (Search)

### By search query

```bash
# Find and fix issues matching a query
/loom:start github "fix: authentication"
/loom:start github "TypeError in checkout flow"

# Natural language
/loom:start github "all open bugs labeled critical"
```

Under the hood, Loom runs:

```bash
gh issue list --search "<query>" --json number,title,body,state --limit 10
```

It reviews matching issues, implements the most relevant open ones, and closes them after implementation.

## With Extra Instructions

Combine a GitHub issue with additional directives:

```bash
# Implement the issue AND do extra work
/loom:start github 42 --prompt "Also fix the related lint warnings"

# Implement the issue with specific constraints
/loom:start github 42 --prompt "Use the existing auth middleware, don't create a new one"
```

The issue content and your prompt are merged into a single directive.

## Without Worktree or PR

For quick fixes you want to apply directly:

```bash
/loom:start github 42 --worktree false --pr false
```

## Writing Good GitHub Issues for Loom

Loom reads the issue body as a spec. Issues that work well with Loom:

- **Clear title** describing the desired outcome
- **Requirements as bullet lists** — each bullet is treated as a concrete requirement
- **Acceptance criteria** — "the function should return X when given Y"
- **File hints** — "the bug is in `src/auth/middleware.ts`" helps the subagent find context
- **Error messages** — for bug fixes, include the actual error and steps to reproduce

### Example: Good issue for Loom

```markdown
Title: Add rate limiting to authentication endpoints

The login and signup endpoints have no rate limiting, allowing brute force attacks.

Requirements:
- POST /auth/login rate limited to 5 requests per 10 minutes per IP
- POST /auth/signup rate limited to 3 requests per hour per IP
- Return 429 status with Retry-After header when limited
- Rate limit state stored in Redis (use existing Redis connection from src/lib/redis.ts)
- Add rate limit headers to all auth responses: X-RateLimit-Remaining, X-RateLimit-Reset

Files likely affected:
- src/auth/middleware.ts
- src/auth/router.ts
- tests/auth.test.ts
```

### Example: Poor issue for Loom

```markdown
Title: Fix auth

The auth is broken. Please fix.
```

## Troubleshooting

**"gh: command not found"**
- Install the GitHub CLI: `brew install gh`

**"gh: not logged in"**
- Run `gh auth login` and follow the prompts

**Issue not found**
- Check the issue number exists: `gh issue view <number>`
- For URLs, ensure the repo matches your current project

**Issue closed without full implementation**
- Check `status.md` for details on what was and wasn't completed
- The Loom agent closes the issue after attempting implementation — review the PR to verify
