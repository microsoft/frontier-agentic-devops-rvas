# shellcheck shell=bash
#
# challenges/ch08-rulesets-repo-properties/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: ghec_provision / ghec_teardown / ghec_status.
#
# ORG-SCOPED. ch08 builds four populated repos (each with a working CI workflow
# that emits a 'build' check) and prints an inventory. Defining custom repo
# properties and org rulesets that target these repos is the challenge — none
# exist yet.

R1="ghec-${CHID}-prod-payments"
R2="ghec-${CHID}-prod-identity"
R3="ghec-${CHID}-internal-tools"
R4="ghec-${CHID}-sandbox"

_ch08_seed_repo() {
  local repo="$1"
  gh_put_file "$ORG" "$repo" "README.md" "seed README (ghec-${CHID})" \
"# ${repo}

Seeded by ghec-${CHID} (Rulesets & Repo Properties). CI publishes a \`build\`
check on every push/PR. No custom properties or rulesets are set yet."
  gh_put_file "$ORG" "$repo" "package.json" "seed package.json (ghec-${CHID})" \
"{
  \"name\": \"${repo}\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"scripts\": { \"test\": \"node test/app.test.js\" }
}
"
  gh_put_file "$ORG" "$repo" "src/index.js" "seed src (ghec-${CHID})" \
"module.exports = { ok: true };
"
  gh_put_file "$ORG" "$repo" "test/app.test.js" "seed test (ghec-${CHID})" \
"const assert = require('assert');
assert.strictEqual(require('../src/index').ok, true);
console.log('ok - build check passed');
"
  gh_put_file "$ORG" "$repo" ".github/workflows/ci.yml" "seed build-check CI (ghec-${CHID})" \
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
}

# ===========================================================================
ghec_provision() {
  local r
  for r in "$R1" "$R2" "$R3" "$R4"; do
    gh_create_repo "$ORG" "$r" private
  done

  if [[ "$DRY_RUN" != "true" ]]; then
    for r in "$R1" "$R2" "$R3" "$R4"; do
      gh_repo_exists "$ORG" "$r" && _ch08_seed_repo "$r"
    done
  else
    log_plan "would seed app + build-check CI into $R1, $R2, $R3, $R4"
  fi

  log_step "repo inventory for '$ORG' (ghec-${CHID})"
  for r in "$R1" "$R2" "$R3" "$R4"; do
    if [[ "$DRY_RUN" == "true" ]]; then
      log_plan "would read: gh api repos/$ORG/$r (visibility, default_branch)"
    elif gh_repo_exists "$ORG" "$r"; then
      gh api "repos/$ORG/$r" --jq '"\(.full_name)\tvisibility=\(.visibility)\tdefault_branch=\(.default_branch)"' \
        2>/dev/null || log_warn "could not read $ORG/$r"
    fi
  done
}

ghec_teardown() {
  local r
  for r in "$R1" "$R2" "$R3" "$R4"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r
  for r in "$R1" "$R2" "$R3" "$R4"; do
    if gh_repo_exists "$ORG" "$r"; then log_ok "repo $ORG/$r present"; else log_info "repo $ORG/$r absent"; fi
  done
}
