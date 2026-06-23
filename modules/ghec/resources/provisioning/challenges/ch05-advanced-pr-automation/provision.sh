# shellcheck shell=bash
#
# challenges/ch05-advanced-pr-automation/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: wth_provision / wth_teardown / wth_status.
#
# ch05 builds: a seeded app with a WORKING CI workflow that emits a 'build'
# check on every PR, a starter .github/CODEOWNERS, a placeholder PR template,
# and FOUR open PRs in mixed states:
#   - clean            : passes CI, no overlap
#   - failing-ci       : breaks the test so the build check goes red
#   - draft            : opened as a draft PR
#   - needs-owner      : touches a CODEOWNERS path, awaiting owner review
# No rulesets yet — wiring required checks + review automation is the challenge.

BR_CLEAN="wth-${CHID}-clean"
BR_FAIL="wth-${CHID}-failing-ci"
BR_DRAFT="wth-${CHID}-draft"
BR_OWNER="wth-${CHID}-needs-owner"

_ch05_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch05_seed_main() {
  log_step "seeding app + working CI on main"

  gh_put_file "$ORG" "$REPO" "README.md" "seed README (wth-${CHID})" \
"# wth-${CHID} — Advanced PR Automation

A seeded app with a working CI workflow that publishes a \`build\` check on
every pull request. Four PRs are already open in different states. Your job is
to add automation: required status checks, required reviews from code owners,
auto-labelling, and a ruleset — without merging the broken ones by accident."

  gh_put_file "$ORG" "$REPO" "package.json" "seed package.json (wth-${CHID})" \
"{
  \"name\": \"wth-${CHID}-app\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"scripts\": { \"test\": \"node test/app.test.js\" }
}
"

  gh_put_file "$ORG" "$REPO" "src/math.js" "seed src/math.js (wth-${CHID})" \
"function add(a, b) { return a + b; }
module.exports = { add };
"

  gh_put_file "$ORG" "$REPO" "test/app.test.js" "seed test (wth-${CHID})" \
"const assert = require('assert');
const { add } = require('../src/math');
assert.strictEqual(add(2, 3), 5, 'add(2,3) should be 5');
console.log('ok - build check passed');
"

  gh_put_file "$ORG" "$REPO" ".github/workflows/ci.yml" "seed working build-check CI (wth-${CHID})" \
"name: build
on:
  pull_request:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm test
"

  gh_put_file "$ORG" "$REPO" ".github/CODEOWNERS" "seed starter CODEOWNERS (wth-${CHID})" \
"# wth-${CHID} starter CODEOWNERS — replace the placeholder owner with a real
# team/user (e.g. @${ORG}/maintainers) and wire required reviews via a ruleset.
/src/   @${ORG}/PLACEHOLDER-OWNERS
"

  gh_put_file "$ORG" "$REPO" ".github/pull_request_template.md" "seed PR template placeholder (wth-${CHID})" \
"<!-- wth-${CHID} placeholder PR template -->

## Summary

## Risk / rollout

## Checklist
- [ ] build check green
- [ ] code owner review
"
}

_ch05_pr_clean() {
  log_step "PR (clean) from $BR_CLEAN"
  gh_create_branch "$ORG" "$REPO" "$BR_CLEAN" main
  gh_put_file "$ORG" "$REPO" "docs/notes.md" "add notes (wth-${CHID})" \
"# Notes

Clean change — no code touched, build stays green.
" "$BR_CLEAN"
  gh_open_pr "$ORG" "$REPO" "$BR_CLEAN" main "Add docs notes (clean)" \
    "Seeded by wth-${CHID}. Clean PR — build check should pass."
}

_ch05_pr_failing() {
  log_step "PR (failing-ci) from $BR_FAIL"
  gh_create_branch "$ORG" "$REPO" "$BR_FAIL" main
  # Break the function so 'npm test' (the build check) fails.
  gh_upsert_file "$ORG" "$REPO" "src/math.js" "break add() to fail CI (wth-${CHID})" \
"function add(a, b) { return a - b; } // BUG: should be a + b
module.exports = { add };
" "$BR_FAIL"
  gh_open_pr "$ORG" "$REPO" "$BR_FAIL" main "Refactor add() (FAILS build)" \
    "Seeded by wth-${CHID}. This PR breaks the test — the build check should go red. Do not merge."
}

_ch05_pr_draft() {
  log_step "PR (draft) from $BR_DRAFT"
  gh_create_branch "$ORG" "$REPO" "$BR_DRAFT" main
  gh_put_file "$ORG" "$REPO" "docs/wip.md" "wip notes (wth-${CHID})" \
"# WIP

Work in progress — opened as a draft on purpose.
" "$BR_DRAFT"
  gh_open_pr "$ORG" "$REPO" "$BR_DRAFT" main "WIP feature (draft)" \
    "Seeded by wth-${CHID}. Opened as a draft — should be excluded from auto-merge." --draft
}

_ch05_pr_owner() {
  log_step "PR (needs-owner) from $BR_OWNER"
  gh_create_branch "$ORG" "$REPO" "$BR_OWNER" main
  # Touches /src — a CODEOWNERS path — so it needs owner review once wired.
  gh_upsert_file "$ORG" "$REPO" "src/math.js" "add mul() under CODEOWNERS path (wth-${CHID})" \
"function add(a, b) { return a + b; }
function mul(a, b) { return a * b; }
module.exports = { add, mul };
" "$BR_OWNER"
  gh_open_pr "$ORG" "$REPO" "$BR_OWNER" main "Add mul() (needs code owner)" \
    "Seeded by wth-${CHID}. Touches /src (a CODEOWNERS path) — should require owner review once you wire it."
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch05_full) missing after create — aborting seed"
  fi
  _ch05_seed_main
  _ch05_pr_clean
  _ch05_pr_failing
  _ch05_pr_draft
  _ch05_pr_owner
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - require the 'build' status check on main"
  log_info "  - require code owner review (fix CODEOWNERS placeholder first)"
  log_info "  - add auto-labelling / auto-merge that respects draft + failing states"
}

wth_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local prs
    prs="$(gh pr list --repo "$(_ch05_full)" --state open --json number --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch05_full) present — $prs open PR(s)"
  else
    log_info "repo $(_ch05_full) not provisioned"
  fi
}
