#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
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
  local required="${2:-required}"
  if command -v "$name" >/dev/null 2>&1; then
    pass "$name is installed"
  elif [[ "$required" == "required" ]]; then
    fail "$name is not installed"
  else
    warn "$name is not installed"
  fi
}

printf 'Azure SRE Agent track doctor\n'
printf 'Repository: %s\n\n' "$REPO_ROOT"

check_command git
check_command az
check_command azd

if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
  pass "Python is installed"
else
  fail "Python 3.10+ is not installed"
fi

if command -v az >/dev/null 2>&1; then
  if az account show >/dev/null 2>&1; then
    pass "Azure CLI has an active subscription"
  else
    warn "Azure CLI is not logged in or no subscription is selected; run az login --use-device-code"
  fi

  provider_state="$(az provider show -n Microsoft.App --query registrationState -o tsv 2>/dev/null || true)"
  if [[ "$provider_state" == "Registered" ]]; then
    pass "Microsoft.App provider is registered"
  else
    warn "Microsoft.App provider is not registered; run az provider register -n Microsoft.App --wait"
  fi
fi

if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  pass "running inside a Git repository"
else
  fail "not inside a Git repository"
fi

cat <<'EOF'

Official lab source:
  https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab

Recommended live setup:
  LAB_DIR="$(bash modules/sre-agent/resources/scripts/ensure-starter-lab.sh)"
  cd "$LAB_DIR"
  bash scripts/setup.sh

If Azure access is blocked, use the coach fallback packet instead of troubleshooting subscription policy during the workshop.
EOF

if [[ "$FAILURES" -gt 0 ]]; then
  printf '\nDoctor found %s blocking issue(s).\n' "$FAILURES" >&2
  exit 1
fi

printf '\nAzure SRE Agent track preflight is ready. Resolve warnings before live deployment or use the fallback packet.\n'
