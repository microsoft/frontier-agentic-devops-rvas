# shellcheck shell=bash
#
# challenges/ch15-security-campaigns-overview/provision.sh
#
# ch15 imports a PUBLIC OWASP Juice Shop copy and seeds a deliberately RICH,
# MULTI-TOOL alert corpus so a security campaign has cross-tool material to
# organise: a CodeQL workflow (code scanning), a Dependabot config (Dependabot
# alerts), and one planted non-live secret + manifest (secret scanning). The
# repo stands alone so its alert volume is independent of ch11–ch13.

JS_REPO="ghec-${CHID}-juice-shop"

_AWS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
_AWS_SECRET="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

_ch15_js_full() { printf '%s/%s' "$ORG" "$JS_REPO"; }

_ch15_seed_codeql() {
  log_step "seeding CodeQL workflow (code scanning corpus)"
  gh_put_file "$ORG" "$JS_REPO" ".github/workflows/codeql.yml" \
    "Add CodeQL advanced setup (javascript-typescript)" \
"$(cat <<'EOF'
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
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3
EOF
)"
}

_ch15_seed_dependabot() {
  log_step "seeding Dependabot config (Dependabot alert corpus)"
  gh_put_file "$ORG" "$JS_REPO" ".github/dependabot.yml" \
    "Add Dependabot config" \
"$(cat <<'EOF'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
EOF
)"
}

_ch15_seed_secret() {
  log_step "planting one non-live secret (secret scanning corpus)"
  gh_put_file "$ORG" "$JS_REPO" "config/aws-credentials.ini" \
    "Add legacy AWS uploader credentials (seed)" \
"$(cat <<EOF
; ghec-ch15 planted NON-LIVE test secret — see SECURITY-CORPUS.md
[default]
aws_access_key_id = ${_AWS_KEY_ID}
aws_secret_access_key = ${_AWS_SECRET}
EOF
)"
  gh_put_file "$ORG" "$JS_REPO" "SECURITY-CORPUS.md" \
    "Add multi-tool alert corpus manifest" \
"$(cat <<'EOF'
# SECURITY-CORPUS — ghec-ch15

This repo deliberately produces alerts across THREE tools so you can build and
manage a security campaign end to end:

| Tool | Source | What to expect |
|------|--------|----------------|
| Code scanning (CodeQL) | `.github/workflows/codeql.yml` + Juice Shop source | SQLi, XSS, and more |
| Dependabot | `.github/dependabot.yml` + Juice Shop `package.json` | vulnerable npm deps |
| Secret scanning | `config/aws-credentials.ini` | one planted NON-LIVE AWS key |

Use these to scope a campaign, assign owners, and track burn-down.
EOF
)"
}

# ===========================================================================
ghec_provision() {
  juice_shop_import "$ORG" "$JS_REPO" "$JUICE_SHOP_REF"
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$JS_REPO"; then
    die "repo $(_ch15_js_full) missing after import — aborting seed"
  fi
  _ch15_seed_codeql
  _ch15_seed_dependabot
  _ch15_seed_secret
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - enable code scanning, Dependabot, and secret scanning in Security settings"
  log_info "  - create a security campaign and scope it across the three alert sources"
  log_warn "manual: enabling the three scanners is the learning — not auto-enabled."
}

ghec_teardown() {
  guard_prefix "$JS_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$JS_REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$JS_REPO"; then
    local codeql dependabot secret
    codeql="present"; gh_file_exists "$ORG" "$JS_REPO" ".github/workflows/codeql.yml" || codeql="MISSING"
    dependabot="present"; gh_file_exists "$ORG" "$JS_REPO" ".github/dependabot.yml" || dependabot="MISSING"
    secret="present"; gh_file_exists "$ORG" "$JS_REPO" "config/aws-credentials.ini" || secret="MISSING"
    log_ok "repo $(_ch15_js_full) present — codeql $codeql, dependabot $dependabot, secret $secret"
  else
    log_info "repo $(_ch15_js_full) not provisioned"
  fi
}
