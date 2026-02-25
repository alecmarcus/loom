# Linear Tickets

Implement Linear tickets autonomously — fetch the ticket, build it, update the status.

## Prerequisites

1. Install the Linear MCP server:

   ```bash
   claude mcp add --transport http linear https://mcp.linear.app/mcp
   ```

   Or add to your project's `.mcp.json`:

   ```json
   {
     "mcpServers": {
       "linear": {
         "type": "http",
         "url": "https://mcp.linear.app/mcp"
       }
     }
   }
   ```

2. Complete OAuth authentication. Start Claude Code and trigger the Linear MCP — a browser window opens for authorization:

   ```bash
   claude
   # Ask: "List my Linear issues"
   # Complete OAuth in the browser when prompted
   ```

   This is a one-time step. The token is cached for future sessions.

3. Verify the MCP is working:
   ```bash
   claude mcp list
   ```

## Single Ticket

### By ticket ID

```bash
# From Claude Code
/loom:start linear TEAM-42

# From bash
/loom:start linear "TEAM-42"
```

### By URL

```bash
/loom:start linear https://linear.app/team/issue/TEAM-42
/loom:start linear "https://linear.app/team/issue/TEAM-42"
```

### What happens

1. Loom fetches the ticket using Linear MCP tools
2. Creates a worktree (isolated branch)
3. Reads the ticket title, description, acceptance criteria, and comments
4. Implements what's described in the ticket
5. Runs tests and commits green code
6. Updates the Linear ticket status to reflect completion
7. Pushes the branch and creates a PR

## Search Queries

Linear mode accepts natural language queries to find and implement tickets:

```bash
# Find tickets by description
/loom:start linear "fix authentication bug"

# Find tickets by label or state
/loom:start linear "all in-progress bugs on the API team"

# SLA-based queries
/loom:start linear "fix all tickets with less than 24h left in the SLA"

# Priority-based
/loom:start linear "all urgent tickets assigned to me"
```

Loom uses Linear MCP tools to search for matching issues, then implements the most relevant ones.

## With Extra Instructions

```bash
# Implement the ticket with constraints
/loom:start linear "TEAM-42" --prompt "Use the existing auth middleware, don't create a new one"

# Combine Linear with GitHub
/loom:start linear "TEAM-42" --github 13 --prompt "Also fix lint"
```

## Writing Good Linear Tickets for Loom

Loom reads the ticket body as a spec. Tickets that work well with Loom:

- **Clear title** describing the outcome
- **Description with requirements** as bullet lists
- **Acceptance criteria** — concrete, testable assertions
- **File hints** — "affects `src/auth/`" helps Loom find context
- **Comments with context** — Loom reads all comments for additional requirements

### Example: Good ticket

```
Title: Add email verification to signup flow

When a user signs up, send a verification email with a 6-digit code.
The user must verify their email before accessing the app.

Acceptance criteria:
- POST /auth/signup sends a verification email to the provided address
- Email contains a 6-digit numeric code valid for 15 minutes
- POST /auth/verify accepts email + code and activates the account
- Unverified accounts cannot access protected routes (return 403)
- Resend endpoint: POST /auth/resend-verification (rate limited to 3 per hour)
- Expired codes return a clear error message

Technical notes:
- Use the existing email service in src/services/email.ts
- Store verification codes in Redis with TTL
- Verification status tracked in the users table (email_verified_at column)
```

## Troubleshooting

**"No Linear MCP tools available"**
- Verify Linear MCP is configured: `claude mcp list`
- Check `.mcp.json` has a `linear` entry with `type: "http"`
- Re-authenticate if the OAuth token expired: start Claude Code and trigger a Linear tool

**Ticket not found**
- Verify the ticket ID format matches your team prefix (e.g., TEAM-42, not just 42)
- Check that the authenticated account has access to the team/project

**Ticket status not updated**
- The Linear OAuth scope needs write permissions. Re-authorize if needed
- Loom attempts to update status after implementation — check `status.md` for errors

**Search returns no results**
- Try simpler queries first: `/loom:start linear "TEAM"` to verify connectivity
- Check that the MCP can list issues: start Claude Code and ask to list issues
