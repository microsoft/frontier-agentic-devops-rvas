#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/../../.." && pwd)"
APP_DIR="$MODULE_DIR/resources/sample-app"
FAILURES=0

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    pass "$name is installed"
  else
    fail "$name is not installed"
  fi
}

printf 'SRE Agent track doctor\n'
printf 'Repository: %s\n\n' "$REPO_ROOT"

check_command git
check_command node
check_command npm
check_command gh

if command -v az >/dev/null 2>&1; then
  pass "az is installed"
else
  warn "az is not installed; Azure deployment can use the coach fallback packet until access is ready"
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    pass "GitHub CLI is authenticated"
  else
    fail "GitHub CLI is not authenticated; run gh auth login"
  fi
fi

if command -v az >/dev/null 2>&1; then
  if az account show >/dev/null 2>&1; then
    pass "Azure CLI has an active subscription"
  else
    warn "Azure CLI is not logged in or no subscription is selected; run az login and az account set before Challenge 04"
  fi
fi

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$REPO_ROOT" branch --show-current)"
  if [[ -n "$branch" && "$branch" != "main" ]]; then
    pass "working on branch $branch"
  else
    warn "create a personal/team branch before making challenge changes"
  fi
else
  fail "not inside a Git repository"
fi

npm --prefix "$APP_DIR" install --silent
npm --prefix "$APP_DIR" test
pass "sample app dependencies install and tests pass"

bash "$MODULE_DIR/resources/scripts/validate-agentic-workflow-specs.sh"
pass "agentic workflow specs validate"

if [[ "$FAILURES" -gt 0 ]]; then
  printf '\nDoctor found %s blocking issue(s).\n' "$FAILURES" >&2
  exit 1
fi

printf '\nSRE Agent track setup is ready. Azure warnings can be resolved before Challenge 04 or handled with coach fallback evidence.\n'
