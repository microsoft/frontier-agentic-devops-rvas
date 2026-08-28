#!/usr/bin/env bash
# shellcheck shell=bash
#
# Safe, standalone fallback provisioner for Ch31. It creates only a small
# ghec-ch31-* repository; it never enables Copilot, provisions runners/services,
# or creates secrets. Customer-target work remains the default.
set -euo pipefail

ORG=""
REPO="ghec-ch31-copilot-environment-instructions"
TEARDOWN="false"

usage() {
  cat <<'EOF'
Usage: provision.sh --org <org> [--teardown]

Creates or updates the safe Ch31 fallback repository. The caller needs GitHub
repository administration in the target organization. No Copilot policy, runner,
service, or secret is created.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="${2:-}"; shift 2 ;;
    --teardown) TEARDOWN="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$ORG" ]] || { printf '%s\n' '--org is required' >&2; exit 1; }
command -v gh >/dev/null || { printf '%s\n' 'gh is required' >&2; exit 1; }

repo_full="$ORG/$REPO"
if [[ "$TEARDOWN" == "true" ]]; then
  [[ "$REPO" == ghec-ch31-* ]] || { printf '%s\n' 'Refusing to delete a non-ch31 repository' >&2; exit 1; }
  gh repo delete "$repo_full" --yes
  printf 'Deleted %s\n' "$repo_full"
  exit 0
fi

if ! gh repo view "$repo_full" >/dev/null 2>&1; then
  gh repo create "$repo_full" --public --description "Safe fallback for GHEC Ch31 Copilot environment instructions"
fi

put_file() {
  local path="$1" message="$2" content="$3"
  local sha=""
  sha="$(gh api "repos/$repo_full/contents/$path" --jq .sha 2>/dev/null || true)"
  if [[ -n "$sha" ]]; then
    gh api --method PUT "repos/$repo_full/contents/$path" \
      -f message="$message" -f content="$(printf '%s' "$content" | base64 | tr -d '\n')" -f sha="$sha" >/dev/null
  else
    gh api --method PUT "repos/$repo_full/contents/$path" \
      -f message="$message" -f content="$(printf '%s' "$content" | base64 | tr -d '\n')" >/dev/null
  fi
}

put_file "README.md" "Add Ch31 fallback overview" "$(cat <<'EOF'
# GHEC Ch31 — Copilot Environment & Instructions

Safe fallback repository for validating a Copilot setup workflow and instruction
layout. It contains no customer data, secret, service, internal endpoint, runner,
or Copilot policy change.

Run `npm ci && npm test`. The default-branch setup workflow is the common
environment baseline for Copilot cloud agent and Copilot code review.
EOF
)"

put_file "package.json" "Add minimal Node.js fixture" "$(cat <<'EOF'
{
  "name": "ghec-ch31-copilot-environment-instructions",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node test/greeting.test.js"
  }
}
EOF
)"

put_file "package-lock.json" "Add npm lockfile" "$(cat <<'EOF'
{
  "name": "ghec-ch31-copilot-environment-instructions",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "ghec-ch31-copilot-environment-instructions",
      "version": "1.0.0"
    }
  }
}
EOF
)"

put_file "src/greeting.js" "Add greeting fixture" "$(cat <<'EOF'
function formatGreeting (name) {
  return `Hello, ${name}!`
}

module.exports = { formatGreeting }
EOF
)"

put_file "test/greeting.test.js" "Add fixture test" "$(cat <<'EOF'
const assert = require('assert')
const { formatGreeting } = require('../src/greeting')

assert.strictEqual(formatGreeting('Ada'), 'Hello, Ada!')
console.log('greeting test passed')
EOF
)"

put_file ".github/copilot-instructions.md" "Add repository Copilot instructions" "$(cat <<'EOF'
# Repository instructions

Use Node.js 20. Run `npm ci` and `npm test` before proposing a change. Keep
changes small, avoid adding secrets or network access, and explain validation in
the pull request. Human review and CI remain required.
EOF
)"

put_file ".github/instructions/source.instructions.md" "Add path-specific Copilot instructions" "$(cat <<'EOF'
---
applyTo: "src/**/*.js"
---
Use CommonJS exports. Update the matching test under `test/` for behavior
changes and run `npm test`.
EOF
)"

put_file ".github/workflows/copilot-setup-steps.yml" "Add Copilot setup steps" "$(cat <<'EOF'
name: Copilot setup steps

on:
  workflow_dispatch:
  push:
    paths: [.github/workflows/copilot-setup-steps.yml]
  pull_request:
    paths: [.github/workflows/copilot-setup-steps.yml]

jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm
      - run: npm ci
      - run: npm test
EOF
)"

issue_title="Validate the Copilot environment and instructions"
if ! gh issue list --repo "$repo_full" --state all --limit 100 --json title --jq '.[].title' | grep -qxF "$issue_title"; then
  gh issue create --repo "$repo_full" --title "$issue_title" --body "$(cat <<'EOF'
Validate the default-branch Copilot setup workflow and instruction layout.

Acceptance criteria:
- Run the setup workflow from Actions and retain its successful URL.
- Make a small, reviewed pull request that changes `src/greeting.js`.
- Confirm the repository and matching path-specific instructions are on the PR head branch.
- Request approved Copilot code review and/or assign an approved cloud-agent task.
- Record observed evidence and any unavailable-feature limitation.

Do not add a secret, service, self-hosted runner, or policy change to this seed.
EOF
)" >/dev/null
fi

printf '%s\n' "Safe fallback ready: $repo_full"
printf '%s\n' "Next: confirm the setup workflow is on the repository default branch, run it from Actions, then use the bounded issue only if the applicable Copilot feature is approved."
