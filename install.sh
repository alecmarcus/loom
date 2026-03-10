#!/usr/bin/env bash
set -euo pipefail

# ─── Loom Local Installer ─────────────────────────────────
# curl -fsSL https://raw.githubusercontent.com/alecmarcus/loom/main/install.sh | bash
#
# Installs Loom into the current project — templates and skill.
# Self-contained: no external dependencies beyond Claude Code and gh.
# ──────────────────────────────────────────────────────────────

TARGET_DIR="${1:-$(pwd)}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || { echo "Error: directory does not exist: $1" >&2; exit 1; }
REPO_URL="https://github.com/alecmarcus/loom.git"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

die() { echo -e "${RED}Error: $1${NC}" >&2; exit 1; }

echo ""
echo -e "  ${BOLD}${CYAN}Loom Installer${NC}"
echo -e "  ${DIM}Target: $TARGET_DIR${NC}"
echo ""

# ─── Check prerequisites ────────────────────────────────────
MISSING=()
command -v git &>/dev/null    || MISSING+=("git")
command -v claude &>/dev/null || MISSING+=("claude (Claude Code CLI)")
command -v gh &>/dev/null     || MISSING+=("gh (GitHub CLI)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${RED}Missing required dependencies:${NC}"
  for dep in "${MISSING[@]}"; do echo -e "  - $dep"; done
  echo ""
  command -v claude &>/dev/null || echo -e "  Install Claude Code: ${DIM}https://docs.anthropic.com/en/docs/claude-code/overview${NC}"
  command -v gh &>/dev/null     || echo -e "  Install GitHub CLI: ${DIM}brew install gh${NC} or ${DIM}https://cli.github.com${NC}"
  die "Install missing dependencies and try again."
fi

# ─── Clean up v1 artifacts if present ────────────────────────
if [ -d "$TARGET_DIR/.loom/scripts" ]; then
  echo -e "  ${YELLOW}Detected v1 installation — cleaning up...${NC}"
  rm -rf "$TARGET_DIR/.loom/scripts"
  rm -rf "$TARGET_DIR/.loom/templates"
  rm -f  "$TARGET_DIR/.loom/prd.json"
  rm -f  "$TARGET_DIR/.loom/status.md"
  rm -f  "$TARGET_DIR/.loom/.plugin_root"

  # Remove v1 skills
  for skill in start stop kill status preview prd setup init; do
    rm -rf "$TARGET_DIR/.claude/skills/loom:$skill"
  done

  # Remove v1 hooks from settings.json
  if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
    if command -v jq &>/dev/null; then
      # Remove hook entries that reference .loom/scripts/
      jq 'if .hooks then .hooks |= with_entries(
        .value |= map(
          if .hooks then
            .hooks |= map(select(.command | test("\\.loom/scripts/") | not))
          else . end
          | select(.hooks == null or (.hooks | length > 0))
        )
        | select(length > 0)
      ) else . end' "$TARGET_DIR/.claude/settings.json" > "$TARGET_DIR/.claude/settings.json.tmp" \
        && mv "$TARGET_DIR/.claude/settings.json.tmp" "$TARGET_DIR/.claude/settings.json"
      echo -e "  ${GREEN}✓${NC} Removed v1 hooks from settings.json"
    else
      echo -e "  ${YELLOW}Warning:${NC} jq not found — manually remove .loom/scripts hook entries from .claude/settings.json"
    fi
  fi

  echo -e "  ${GREEN}✓${NC} v1 artifacts cleaned"
fi

# ─── Clone source to temp dir ────────────────────────────────
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo -e "  ${DIM}Fetching Loom...${NC}"
git clone --depth 1 "$REPO_URL" "$TMPDIR" 2>/dev/null
echo -e "  ${GREEN}✓${NC} Fetched"

SRC="$TMPDIR"

# ─── Install templates ───────────────────────────────────────
echo -e "  ${DIM}Installing templates...${NC}"
mkdir -p "$TARGET_DIR/.loom/templates"

for tmpl in orchestrator.md coder.md reviewer.md arbiter.md validator.md; do
  cp "$SRC/templates/$tmpl" "$TARGET_DIR/.loom/templates/"
done

echo -e "  ${GREEN}✓${NC} Templates (orchestrator, coder, reviewer, arbiter, validator)"

# ─── Write version file ──────────────────────────────────────
VERSION=$(jq -r '.version' "$SRC/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
echo "$VERSION" > "$TARGET_DIR/.loom/.version"
echo -e "  ${GREEN}✓${NC} Version $VERSION"

# ─── Install skill ───────────────────────────────────────────
echo -e "  ${DIM}Installing skill...${NC}"
DEST_SKILL="$TARGET_DIR/.claude/skills/loom:start"
mkdir -p "$DEST_SKILL"
sed "s/^name: start$/name: loom:start/" "$SRC/skills/start/SKILL.md" > "$DEST_SKILL/SKILL.md"
echo -e "  ${GREEN}✓${NC} Skill: /loom:start"

# ─── Project files (don't overwrite existing) ────────────────
echo -e "  ${DIM}Setting up project files...${NC}"
mkdir -p "$TARGET_DIR/.loom/logs"

# .gitignore
if [ ! -f "$TARGET_DIR/.loom/.gitignore" ]; then
  cp "$SRC/templates/gitignore" "$TARGET_DIR/.loom/.gitignore"
  echo -e "  ${GREEN}✓${NC} .loom/.gitignore"
fi

# ─── Done ─────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}Loom installed!${NC}"
echo ""
echo -e "  Installed to:        ${BOLD}$TARGET_DIR/.loom/${NC}"
echo -e "  Skill:               ${BOLD}$TARGET_DIR/.claude/skills/loom:start${NC}"
echo -e "  Templates:           ${BOLD}$TARGET_DIR/.loom/templates/${NC}"
echo ""
echo -e "  ${CYAN}Usage:${NC}"
echo -e "    ${BOLD}/loom:start${NC}                           Work on all loom:ready issues"
echo -e "    ${BOLD}/loom:start issue #42${NC}                 Work on a specific issue"
echo -e "    ${BOLD}/loom:start all auth issues${NC}           Scope by topic"
echo ""
echo -e "  ${CYAN}Prerequisites:${NC}"
echo -e "    Label GitHub issues with ${BOLD}loom:ready${NC} to queue them for execution."
echo ""
echo -e "  ${DIM}Update: re-run this script in the project directory${NC}"
echo ""
