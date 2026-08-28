# shellcheck shell=bash
#
# challenges/ch19-copilot-coding-agent/provision.sh
#
# ch19 seeds a SMALL buggy repo (NOT Juice Shop) sized for the Copilot cloud
# agent: a tiny app with one clear bug, a failing test that pins the bug, a CI
# workflow, and a well-framed issue (repro + acceptance criteria) ready to
# assign to Copilot. The repo is created even though this challenge is not
# EMU-compatible; enabling Copilot is a manual prerequisite.

ISSUE_TITLE="Fix sum() so it adds instead of subtracting"

_ch19_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch19_seed_repo() {
  log_step "seeding tiny buggy app + failing test + CI"

  gh_put_file "$ORG" "$REPO" "README.md" \
    "Add Copilot cloud agent task overview" \
"$(cat <<EOF
# ghec-ch19 — Copilot Cloud Agent Task

A deliberately tiny repo with ONE clear bug. The failing test pins it; the
seeded issue describes the fix with acceptance criteria — ready to hand to the
Copilot cloud agent.

- \`src/math.js\` — contains the bug
- \`test/math.test.js\` — failing test that pins the bug
- \`.github/workflows/ci.yml\` — runs the test on every push/PR

> Copilot cloud agent must be enabled for your org/account (manual prerequisite).
EOF
)"

  gh_put_file "$ORG" "$REPO" "package.json" \
    "Add minimal package.json" \
"$(cat <<'EOF'
{
  "name": "ghec-ch19-coding-agent",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node test/math.test.js"
  }
}
EOF
)"

  gh_put_file "$ORG" "$REPO" "src/math.js" \
    "Add math module (with deliberate bug)" \
"$(cat <<'EOF'
// ghec-ch19 — BUG: sum() subtracts instead of adding. Fix me.
function sum (a, b) {
  return a - b
}
module.exports = { sum }
EOF
)"

  gh_put_file "$ORG" "$REPO" "test/math.test.js" \
    "Add failing test that pins the bug" \
"$(cat <<'EOF'
// ghec-ch19 — fails until sum() is fixed to add.
const assert = require('assert')
const { sum } = require('../src/math')

assert.strictEqual(sum(2, 3), 5, 'sum(2, 3) should be 5')
assert.strictEqual(sum(10, 5), 15, 'sum(10, 5) should be 15')
console.log('all tests passed')
EOF
)"

  gh_put_file "$ORG" "$REPO" ".github/workflows/ci.yml" \
    "Add CI workflow" \
"$(cat <<'EOF'
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
permissions:
  contents: read
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm test
EOF
)"
}

_ch19_seed_issue() {
  log_step "seeding the Copilot-ready issue"
  local existing
  existing="$(gh issue list --repo "$(_ch19_repo_full)" --state all --limit 100 \
    --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$ISSUE_TITLE"; then
    log_ok "issue '$ISSUE_TITLE' exists (skip)"
    return 0
  fi
  run_mutation gh issue create --repo "$(_ch19_repo_full)" \
    --title "$ISSUE_TITLE" \
    --body "$(cat <<'EOF'
## Problem
`src/math.js` exports `sum(a, b)` but it currently returns `a - b`, so addition
is wrong and the test suite fails.

## Repro
```
npm test
```
You'll see `sum(2, 3) should be 5` fail.

## Acceptance criteria
- [ ] `sum(2, 3)` returns `5`
- [ ] `sum(10, 5)` returns `15`
- [ ] `npm test` passes
- [ ] No unrelated changes

Hand this issue to the Copilot cloud agent and review its PR.
EOF
)"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch19_repo_full) missing after create — aborting seed"
  fi
  _ch19_seed_repo
  _ch19_seed_issue
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - assign the seeded issue to the Copilot cloud agent"
  log_info "  - review the agent's PR and confirm CI goes green"
  log_warn "manual: enable the Copilot cloud agent for your org/account first (EMU-incompatible challenge)."
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local test_present issues
    test_present="present"; gh_file_exists "$ORG" "$REPO" "test/math.test.js" || test_present="MISSING"
    issues="$(gh issue list --repo "$(_ch19_repo_full)" --state all --limit 100 \
      --json number --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch19_repo_full) present — failing test $test_present, $issues issue(s)"
  else
    log_info "repo $(_ch19_repo_full) not provisioned"
  fi
}
