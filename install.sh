#!/usr/bin/env bash
set -euo pipefail

# ─── Loom Installer ─────────────────────────────────────────────
# curl -fsSL https://raw.githubusercontent.com/alecmarcus/loom/main/install.sh | bash
#
# Alternative to the plugin marketplace install. Clones the repo
# and registers it as a local plugin directory.
# ─────────────────────────────────────────────────────────────────

INSTALL_DIR="${LOOM_INSTALL_DIR:-$HOME/.loom}"
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
echo ""

# ─── Check prerequisites ────────────────────────────────────────
MISSING=()
command -v git &>/dev/null    || MISSING+=("git")
command -v claude &>/dev/null || MISSING+=("claude (Claude Code CLI)")
command -v jq &>/dev/null     || MISSING+=("jq")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${RED}Missing required dependencies:${NC}"
  for dep in "${MISSING[@]}"; do
    echo -e "  - $dep"
  done
  echo ""
  [ ! -x "$(command -v claude 2>/dev/null)" ] && echo -e "  Install Claude Code: ${DIM}https://docs.anthropic.com/en/docs/claude-code/overview${NC}"
  [ ! -x "$(command -v jq 2>/dev/null)" ] && echo -e "  Install jq: ${DIM}brew install jq${NC} or ${DIM}apt install jq${NC}"
  die "Install missing dependencies and try again."
fi

if ! command -v tmux &>/dev/null; then
  echo -e "  ${YELLOW}Warning:${NC} tmux not found. Loom uses tmux for its monitoring UI."
  echo -e "  Install: ${DIM}brew install tmux${NC} or ${DIM}apt install tmux${NC}"
  echo ""
fi

# ─── Clone or update ────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  echo -e "  ${DIM}Updating existing install at $INSTALL_DIR...${NC}"
  git -C "$INSTALL_DIR" pull --ff-only origin main 2>/dev/null || {
    echo -e "  ${YELLOW}Pull failed — re-cloning...${NC}"
    rm -rf "$INSTALL_DIR"
    git clone "$REPO_URL" "$INSTALL_DIR"
  }
  echo -e "  ${GREEN}✓${NC} Updated"
else
  if [ -d "$INSTALL_DIR" ]; then
    die "$INSTALL_DIR already exists but is not a git repo. Remove it or set LOOM_INSTALL_DIR."
  fi
  echo -e "  ${DIM}Cloning to $INSTALL_DIR...${NC}"
  git clone "$REPO_URL" "$INSTALL_DIR"
  echo -e "  ${GREEN}✓${NC} Cloned"
fi

# ─── Make scripts executable ────────────────────────────────────
chmod +x "$INSTALL_DIR/scripts/"*.sh
chmod +x "$INSTALL_DIR/scripts/hooks/"*.sh 2>/dev/null || true

# ─── Done ────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}Loom installed to $INSTALL_DIR${NC}"
echo ""
echo -e "  ${CYAN}Usage:${NC}"
echo ""
echo -e "  Load Loom when starting Claude Code:"
echo -e "    ${BOLD}claude --plugin-dir $INSTALL_DIR${NC}"
echo ""
echo -e "  Or add a shell alias for permanent use:"
echo -e "    ${DIM}echo 'alias claude-loom=\"claude --plugin-dir $INSTALL_DIR\"' >> ~/.zshrc${NC}"
echo ""
echo -e "  Then initialize your project:"
echo -e "    ${BOLD}/loom:init${NC}"
echo ""
echo -e "  ${CYAN}Update:${NC}"
echo -e "    Re-run this script, or: ${DIM}git -C $INSTALL_DIR pull${NC}"
echo ""
