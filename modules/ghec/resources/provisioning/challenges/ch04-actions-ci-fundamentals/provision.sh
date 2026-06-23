# shellcheck shell=bash
#
# challenges/ch04-actions-ci-fundamentals/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: wth_provision / wth_teardown / wth_status.
#
# ch04 builds: a seeded Node app, a passing test suite plus ONE flag-gated
# failing test (set WTH_FAIL=1 to make CI go red — for practising red/green
# gating), a package.json exposing test/build/lint, and a minimal echo-only
# starter workflow the participant replaces with a real CI pipeline.

_ch04_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch04_seed() {
  log_step "seeding Node app + tests + starter workflow"

  gh_put_file "$ORG" "$REPO" "README.md" "seed README (wth-${CHID})" \
"# wth-${CHID} — GitHub Actions CI Fundamentals

A small Node app with a test suite. The starter workflow only echoes — replace
it with a real CI pipeline (install, lint, test, build, matrix, cache, artifacts).

## Scripts
- \`npm test\`  — runs the suite (one test is gated on WTH_FAIL=1 to demo red/green)
- \`npm run build\` — trivial build step
- \`npm run lint\`  — trivial lint step

Set the repo/Actions variable \`WTH_FAIL=1\` to make the suite fail on purpose."

  gh_put_file "$ORG" "$REPO" "package.json" "seed package.json (wth-${CHID})" \
"{
  \"name\": \"wth-${CHID}-app\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"scripts\": {
    \"test\": \"node test/app.test.js\",
    \"build\": \"node -e \\\"console.log('build ok')\\\"\",
    \"lint\": \"node -e \\\"console.log('lint ok')\\\"\"
  }
}
"

  gh_put_file "$ORG" "$REPO" "src/math.js" "seed src/math.js (wth-${CHID})" \
"function add(a, b) { return a + b; }
function mul(a, b) { return a * b; }
module.exports = { add, mul };
"

  gh_put_file "$ORG" "$REPO" "test/app.test.js" "seed test suite (wth-${CHID})" \
"const assert = require('assert');
const { add, mul } = require('../src/math');

// Always-passing tests.
assert.strictEqual(add(2, 3), 5, 'add(2,3) should be 5');
assert.strictEqual(mul(2, 3), 6, 'mul(2,3) should be 6');
console.log('ok - core tests passed');

// Flag-gated failing test: flip CI red by setting WTH_FAIL=1.
if (process.env.WTH_FAIL === '1') {
  assert.strictEqual(add(2, 2), 5, 'intentional failure (WTH_FAIL=1)');
} else {
  console.log('ok - skipping the flag-gated failure (set WTH_FAIL=1 to enable)');
}
"

  gh_put_file "$ORG" "$REPO" ".github/workflows/ci.yml" "seed echo-only starter workflow (wth-${CHID})" \
"name: ci
# wth-${CHID} STARTER — echo only. Replace with a real pipeline:
# checkout -> setup-node -> npm ci -> lint -> test -> build (+ matrix, cache, artifacts).
on:
  push:
    branches: [ main ]
  pull_request:
  workflow_dispatch:
jobs:
  placeholder:
    runs-on: ubuntu-latest
    steps:
      - run: echo 'Replace me with real CI. See README.'
"

  gh_put_file "$ORG" "$REPO" ".gitignore" "seed .gitignore (wth-${CHID})" \
"node_modules/
"
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch04_full) missing after create — aborting seed"
  fi
  _ch04_seed
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - replace .github/workflows/ci.yml with install/lint/test/build"
  log_info "  - add a matrix (Node versions), dependency caching, and an artifact upload"
  log_info "  - flip WTH_FAIL=1 to watch the gate go red, then green again"
}

wth_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local runs
    runs="$(gh run list --repo "$(_ch04_full)" --limit 100 --json status --jq 'length' 2>/dev/null || echo '0')"
    log_ok "repo $(_ch04_full) present — $runs workflow run(s) recorded"
  else
    log_info "repo $(_ch04_full) not provisioned"
  fi
}
