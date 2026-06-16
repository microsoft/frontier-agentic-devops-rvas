#!/usr/bin/env bash
# doctor.sh — verify the unified hackathon toolchain is present.
# Prints a status table and exits non-zero if any REQUIRED tool is missing.
# Safe to run on the host or inside the dev container.
set -uo pipefail

GREEN="\033[32m"; RED="\033[31m"; YELLOW="\033[33m"; BOLD="\033[1m"; RESET="\033[0m"

missing=0

# check <label> <required|optional> <version-command...>
check() {
  local label="$1"; local req="$2"; shift 2
  local ver
  if ver="$("$@" 2>/dev/null | head -n1)"; then
    [ -z "$ver" ] && ver="(installed)"
    printf "  ${GREEN}✓${RESET} %-12s %s\n" "$label" "$ver"
  elif [ "$req" = "required" ]; then
    printf "  ${RED}✗${RESET} %-12s ${RED}MISSING (required)${RESET}\n" "$label"
    missing=$((missing + 1))
  else
    printf "  ${YELLOW}–${RESET} %-12s ${YELLOW}not found (optional)${RESET}\n" "$label"
  fi
}

# check_sub <label> <required|optional> <cmd> <args...>  (for sub-commands like "gh aw")
check_sub() {
  local label="$1"; local req="$2"; shift 2
  local ver
  if ver="$("$@" 2>/dev/null | head -n1)"; then
    [ -z "$ver" ] && ver="(installed)"
    printf "  ${GREEN}✓${RESET} %-12s %s\n" "$label" "$ver"
  elif [ "$req" = "required" ]; then
    printf "  ${RED}✗${RESET} %-12s ${RED}MISSING (required)${RESET}\n" "$label"
    missing=$((missing + 1))
  else
    printf "  ${YELLOW}–${RESET} %-12s ${YELLOW}not found (optional)${RESET}\n" "$label"
  fi
}

echo -e "${BOLD}Environment doctor — Frontier GitHub Platform Hackathon${RESET}"
echo

echo -e "${BOLD}Core${RESET}"
check    "git"     required git --version
check    "gh"      required gh --version
check_sub "gh aw"  required gh aw --version
check    "jq"      required jq --version

echo
echo -e "${BOLD}Runtimes${RESET}"
check "node"    required node --version
check "npm"     required npm --version
check "python"  required python3 --version

echo
echo -e "${BOLD}Cloud / containers${RESET}"
check     "az"     required az version --query "\"azure-cli\"" -o tsv
check_sub "bicep"  required az bicep version
check     "docker" required docker --version

echo
if [ "$missing" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}All required tools present.${RESET}"
  echo -e "Reminder: run ${BOLD}gh auth login${RESET} (and ${BOLD}az login${RESET} for the SRE module) before challenge work."
  exit 0
else
  echo -e "${RED}${BOLD}${missing} required tool(s) missing.${RESET} See above."
  exit 1
fi
