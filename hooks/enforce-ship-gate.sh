#!/usr/bin/env bash
# PreToolUse hook (Bash): Hard enforcement of shipping rules.
# Blocks: --admin flag, force push, auto-merge.
# Before merge: verifies CI green + no unresolved comments.
# Only active when the orchestrator is running (marker file exists).

HASH=$(echo "${CLAUDE_PROJECT_DIR:-$PWD}" | shasum -a 256 | cut -c1-16)
MARKER="/tmp/loom-orchestrating-${HASH}"

if [ ! -f "$MARKER" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# ── UNCONDITIONAL BLOCKS ──

# Block --admin on ANY gh command. There is never a legitimate reason.
if echo "$COMMAND" | grep -qE '\-\-admin'; then
  echo '{"decision":"block","reason":"BLOCKED: --admin flag is forbidden. It bypasses branch protection rules. You do not have authority to override branch protection under any circumstances. Remove --admin and retry."}'
  exit 0
fi

# Block force push
if echo "$COMMAND" | grep -qE 'git push.*(--force|--force-with-lease|\s-f\s|-f$)'; then
  echo '{"decision":"block","reason":"BLOCKED: Force push is forbidden. Never use --force, --force-with-lease, or -f with git push."}'
  exit 0
fi

# Block auto-merge
if echo "$COMMAND" | grep -qE '(--auto-merge|gh pr merge.*--auto)'; then
  echo '{"decision":"block","reason":"BLOCKED: Auto-merge is forbidden. Merge explicitly after verifying all six conditions in §7.4."}'
  exit 0
fi

# ── PRE-MERGE VERIFICATION ──

if echo "$COMMAND" | grep -qE 'gh pr merge'; then
  # Extract PR number
  PR=$(echo "$COMMAND" | grep -oE 'gh pr merge [0-9]+' | grep -oE '[0-9]+')
  if [ -z "$PR" ]; then
    # Try current branch PR
    PR=$(gh pr view --json number -q .number 2>/dev/null)
  fi

  if [ -n "$PR" ]; then
    # Check CI status
    FAILING=$(gh pr checks "$PR" --json name,state --jq '.[] | select(.state == "FAILURE" or .state == "ERROR") | .name' 2>/dev/null)
    PENDING=$(gh pr checks "$PR" --json name,state --jq '.[] | select(.state == "PENDING") | .name' 2>/dev/null)

    if [ -n "$FAILING" ]; then
      echo "{\"decision\":\"block\",\"reason\":\"BLOCKED: CI checks are FAILING on PR #$PR. You may NOT merge with failing CI. Fix the failures first. Do NOT rationalize them as 'pre-existing' — if CI is red on your branch, it is your problem.\\n\\nFailing checks:\\n$FAILING\"}"
      exit 0
    fi

    if [ -n "$PENDING" ]; then
      echo "{\"decision\":\"block\",\"reason\":\"BLOCKED: CI checks are still PENDING on PR #$PR. Wait for CI to complete before merging.\\n\\nPending checks:\\n$PENDING\"}"
      exit 0
    fi

    # Check for unresolved PR comments
    OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    if [ -n "$OWNER_REPO" ]; then
      UNRESOLVED=$(gh api "repos/$OWNER_REPO/pulls/$PR/comments" --jq '[.[] | select(.in_reply_to_id == null) | select(.body != null)] | map(select(has("minimized_comment") | not) // select(.minimized_comment.isMinimized != true)) | length' 2>/dev/null)

      if [ -n "$UNRESOLVED" ] && [ "$UNRESOLVED" -gt 0 ]; then
        echo "{\"decision\":\"block\",\"reason\":\"BLOCKED: PR #$PR has $UNRESOLVED unresolved review comment(s). Every comment must be addressed (reviewer → arbiter loop, respond in-thread, resolve/hide) before merging. See §5 STEP 4.\"}"
        exit 0
      fi
    fi
  fi
fi

echo '{"decision":"allow"}'
