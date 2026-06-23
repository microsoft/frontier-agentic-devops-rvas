#!/usr/bin/env bash
# postCreate.sh — runs once after the dev container is created.
# Installs the tools that aren't covered by Dev Container Features (gh-aw, Bicep),
# then runs the environment doctor so a fresh container self-reports its status.
set -uo pipefail

BOLD="\033[1m"; CYAN="\033[36m"; GREEN="\033[32m"; YELLOW="\033[33m"; RESET="\033[0m"

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Frontier GitHub Platform Hackathon — Dev Container ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# ── 1. Install jq (not included in the slim base image) ───────────────────────
echo -e "${BOLD}[1/4] Installing jq...${RESET}"
if command -v jq >/dev/null 2>&1; then
  echo -e "      ${GREEN}✓ jq already installed — skipping${RESET}"
else
  sudo apt-get update -qq >/dev/null 2>&1 \
    && sudo apt-get install -y -qq jq >/dev/null 2>&1 \
    && echo -e "      ${GREEN}✓ jq installed${RESET}" \
    || echo -e "      ${YELLOW}! jq install failed — run 'sudo apt-get install -y jq' manually${RESET}"
fi

# ── 2. Install the gh-aw CLI extension (GitHub Agentic Workflows) ──────────────
echo -e "${BOLD}[2/4] Installing gh-aw (GitHub Agentic Workflows)...${RESET}"
if gh aw --version >/dev/null 2>&1; then
  echo -e "      ${GREEN}✓ gh aw already installed — skipping${RESET}"
else
  curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash \
    && echo -e "      ${GREEN}✓ gh aw installed${RESET}" \
    || echo -e "      ${YELLOW}! gh aw install failed — run the curl command again after 'gh auth login'${RESET}"
fi

# ── 3. Install Bicep on top of the Azure CLI (SRE Agent module) ────────────────
echo -e "${BOLD}[3/4] Installing Bicep...${RESET}"
if az bicep version >/dev/null 2>&1; then
  echo -e "      ${GREEN}✓ Bicep already installed — skipping${RESET}"
else
  az bicep install >/dev/null 2>&1 \
    && echo -e "      ${GREEN}✓ Bicep installed${RESET}" \
    || echo -e "      ${YELLOW}! Bicep install failed — run 'az bicep install' manually${RESET}"
fi

# ── 4. Verify the environment ─────────────────────────────────────────────────
echo -e "${BOLD}[4/4] Verifying tools...${RESET}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "${REPO_ROOT}/scripts/doctor.sh" || true

echo
echo -e "${BOLD}Next steps:${RESET}"
echo -e "  • Authenticate GitHub:  ${CYAN}gh auth login${RESET}"
echo -e "  • (SRE module) Azure:   ${CYAN}az login${RESET}"
echo -e "  • Open the catalog:     ${CYAN}docs/index.html${RESET} (or your published Pages site)"
echo
echo -e "${YELLOW}Note: module sample apps (Contoso Claims) are cloned on demand from their source repos —${RESET}"
echo -e "${YELLOW}      this container ships the toolchain, not the apps.${RESET}"
echo -e "${YELLOW}Tip:  GHAS participants → run ${BOLD}npm run setup:juice-shop${RESET}${YELLOW} to fetch + link Juice Shop locally.${RESET}"
