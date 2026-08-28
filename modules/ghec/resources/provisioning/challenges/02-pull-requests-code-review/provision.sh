# shellcheck shell=bash
#
# challenges/ch02-pull-requests-code-review/provision.sh
#
# Sourced by scripts/setup.sh, which exports:
#   ORG CHID SLUG APP JUICE_SHOP_REF DRY_RUN ASSUME_YES NAMESPACE REPO META
# and provides lib helpers: log_*, run_mutation, gh_*, guard_prefix, meta_*.
#
# CONTRACT — defines exactly: ghec_provision / ghec_teardown / ghec_status.
#
# ch02 builds: a seeded multi-file app on main, a PR template placeholder, a
# directory layout that maps cleanly to CODEOWNERS paths (src/, docs/), and TWO
# open PRs from feature branches — one clean, one engineered to conflict on
# main. No branch protection yet (the participant adds review + CODEOWNERS).

BR_CLEAN="ghec-${CHID}-clean-feature"
BR_CONFLICT="ghec-${CHID}-conflict-feature"

_ch02_full() { printf '%s/%s' "$ORG" "$REPO"; }

# ---------------------------------------------------------------------------
# main: seed the multi-file app
# ---------------------------------------------------------------------------
_ch02_seed_main() {
  log_step "seeding app on main"
  local full; full="$(_ch02_full)"

  # First file initialises the default branch (main) on the empty repo.
  gh_put_file "$ORG" "$REPO" "README.md" "seed README (ghec-${CHID})" \
"# ghec-${CHID} — Pull Requests & Code Review

A deliberately small multi-file app. Use it to practise branches, pull
requests, reviews, CODEOWNERS, and resolving a merge conflict.

Layout (maps cleanly to CODEOWNERS paths):
- \`src/\`  — application code
- \`docs/\` — documentation

Two PRs are already open: one is clean, one will conflict on \`main\`."

  gh_put_file "$ORG" "$REPO" "src/app.js" "seed src/app.js (ghec-${CHID})" \
"const { greeting } = require('./util');

function main() {
  console.log(greeting('world'));
}

main();
"

  gh_put_file "$ORG" "$REPO" "src/util.js" "seed src/util.js (ghec-${CHID})" \
"function greeting(name) {
  return 'Hello, ' + name + '!';
}

module.exports = { greeting };
"

  gh_put_file "$ORG" "$REPO" "package.json" "seed package.json (ghec-${CHID})" \
"{
  \"name\": \"ghec-${CHID}-app\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"scripts\": { \"start\": \"node src/app.js\" }
}
"

  # The shared file that both main and the conflict branch will edit.
  gh_put_file "$ORG" "$REPO" "docs/config.md" "seed docs/config.md (ghec-${CHID})" \
"# Configuration

release-channel: ORIGINAL
"

  gh_put_file "$ORG" "$REPO" ".github/pull_request_template.md" \
    "seed PR template placeholder (ghec-${CHID})" \
"<!-- ghec-${CHID} placeholder PR template — flesh this out as part of the challenge. -->

## What & why

## How to test

## Checklist
- [ ] Tests pass
- [ ] Reviewed by a code owner
"
}

# ---------------------------------------------------------------------------
# clean PR — a brand-new file, no overlap with main
# ---------------------------------------------------------------------------
_ch02_clean_pr() {
  log_step "opening CLEAN pr from $BR_CLEAN"
  gh_create_branch "$ORG" "$REPO" "$BR_CLEAN" main
  gh_put_file "$ORG" "$REPO" "src/feature.js" "add feature module (ghec-${CHID})" \
"// New, self-contained feature — merges cleanly.
function shout(name) {
  return 'HELLO, ' + String(name).toUpperCase() + '!';
}

module.exports = { shout };
" "$BR_CLEAN"
  gh_open_pr "$ORG" "$REPO" "$BR_CLEAN" main \
    "Add shout() helper (clean)" \
    "Seeded by ghec-${CHID}. A clean PR: adds \`src/feature.js\` with no overlap on main. Practise review + merge."
}

# ---------------------------------------------------------------------------
# conflict PR — branch and main both edit docs/config.md
# ---------------------------------------------------------------------------
_ch02_conflict_pr() {
  log_step "opening CONFLICT pr from $BR_CONFLICT"
  gh_create_branch "$ORG" "$REPO" "$BR_CONFLICT" main

  # branch side: change the shared line
  gh_upsert_file "$ORG" "$REPO" "docs/config.md" "branch: switch channel to beta (ghec-${CHID})" \
"# Configuration

release-channel: BETA
" "$BR_CONFLICT"

  gh_open_pr "$ORG" "$REPO" "$BR_CONFLICT" main \
    "Switch release channel to beta (will conflict)" \
    "Seeded by ghec-${CHID}. This PR edits the same line in \`docs/config.md\` that main also changed — resolve the merge conflict."

  # main side: change the SAME line so the PR conflicts (gated for idempotency).
  if gh_file_contains "$ORG" "$REPO" "docs/config.md" "release-channel: STABLE" main; then
    log_ok "main already diverged (skip conflict edit)"
  else
    log_step "diverging main to force the conflict"
    gh_upsert_file "$ORG" "$REPO" "docs/config.md" "main: switch channel to stable (ghec-${CHID})" \
"# Configuration

release-channel: STABLE
" main
  fi
}

# ===========================================================================
# CONTRACT FUNCTIONS
# ===========================================================================

ghec_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch02_full) missing after create — aborting seed"
  fi
  _ch02_seed_main
  _ch02_clean_pr
  _ch02_conflict_pr
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - add a CODEOWNERS file mapping src/ and docs/ to reviewers"
  log_info "  - review and merge the clean PR ($BR_CLEAN)"
  log_info "  - resolve the merge conflict on the conflict PR ($BR_CONFLICT)"
  log_info "  - turn on branch protection / required reviews on main"
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local prs
    prs="$(gh pr list --repo "$(_ch02_full)" --state open --json number --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch02_full) present — $prs open PR(s)"
    gh_branch_exists "$ORG" "$REPO" "$BR_CLEAN"    && log_ok "branch '$BR_CLEAN' present"    || log_info "branch '$BR_CLEAN' absent"
    gh_branch_exists "$ORG" "$REPO" "$BR_CONFLICT" && log_ok "branch '$BR_CONFLICT' present" || log_info "branch '$BR_CONFLICT' absent"
  else
    log_info "repo $(_ch02_full) not provisioned"
  fi
}
