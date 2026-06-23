# shellcheck shell=bash
#
# challenges/ch12-codeql-code-scanning/provision.sh
#
# ch12 imports a PUBLIC OWASP Juice Shop copy (real OWASP Top 10 vulns ship with
# the app — CodeQL detects them) and adds an advanced-setup CodeQL workflow plus
# a feature/insecure-endpoint branch carrying a deliberately vulnerable change to
# open as a PR for required-check gating.

JS_REPO="wth-${CHID}-juice-shop"

_ch12_js_full() { printf '%s/%s' "$ORG" "$JS_REPO"; }

_ch12_codeql_workflow() {
  cat <<'EOF'
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 6 * * 1"
permissions:
  contents: read
  security-events: write
jobs:
  analyze:
    name: Analyze (javascript-typescript)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
EOF
}

_ch12_seed_workflow() {
  log_step "seeding advanced-setup CodeQL workflow"
  gh_put_file "$ORG" "$JS_REPO" ".github/workflows/codeql.yml" \
    "Add CodeQL advanced setup (javascript-typescript)" \
    "$(_ch12_codeql_workflow)"
}

_ch12_seed_insecure_branch() {
  log_step "seeding feature/insecure-endpoint (deliberately vulnerable change)"
  gh_create_branch "$ORG" "$JS_REPO" "feature/insecure-endpoint" main
  gh_put_file "$ORG" "$JS_REPO" "routes/wthInsecureLookup.js" \
    "Add insecure lookup endpoint (seed, for CodeQL PR gating)" \
"$(cat <<'EOF'
// wth-ch12 SEED — deliberately vulnerable. Do NOT ship.
// Open as a PR against main so CodeQL flags it on the diff (SQLi + XSS).
const sqlite3 = require('sqlite3')
module.exports = function wthInsecureLookup () {
  return (req, res) => {
    const db = new sqlite3.Database(':memory:')
    // SQL injection: untrusted input concatenated straight into the query.
    const q = "SELECT * FROM Products WHERE name = '" + req.query.name + "'"
    db.all(q, (err, rows) => {
      // Reflected XSS: untrusted input echoed into the HTML response.
      res.send('<h1>Results for ' + req.query.name + '</h1>' + JSON.stringify(rows || err))
    })
  }
}
EOF
)" \
    "feature/insecure-endpoint"
}

# ===========================================================================
wth_provision() {
  juice_shop_import "$ORG" "$JS_REPO" "$JUICE_SHOP_REF"
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$JS_REPO"; then
    die "repo $(_ch12_js_full) missing after import — aborting seed"
  fi
  _ch12_seed_workflow
  _ch12_seed_insecure_branch
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - confirm code scanning runs (default or the seeded advanced workflow)"
  log_info "  - open a PR from feature/insecure-endpoint and watch CodeQL gate it"
  log_info "  - triage alerts and try Copilot Autofix on a finding"
}

wth_teardown() {
  guard_prefix "$JS_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$JS_REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$JS_REPO"; then
    local wf branch
    wf="present"; gh_file_exists "$ORG" "$JS_REPO" ".github/workflows/codeql.yml" || wf="MISSING"
    branch="present"; gh_branch_exists "$ORG" "$JS_REPO" "feature/insecure-endpoint" || branch="MISSING"
    log_ok "repo $(_ch12_js_full) present — codeql.yml $wf, feature/insecure-endpoint $branch"
  else
    log_info "repo $(_ch12_js_full) not provisioned"
  fi
}
