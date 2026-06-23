# shellcheck shell=bash
#
# challenges/ch13-dependabot-dependency-review/provision.sh
#
# ch13 imports a PUBLIC OWASP Juice Shop copy (its npm tree is intentionally
# vulnerable — genuine Dependabot alerts + security-update PRs) and adds a
# Dependabot config plus a feature/add-risky-dep branch that adds a known-
# vulnerable dependency to open as a PR for dependency-review gating.

JS_REPO="wth-${CHID}-juice-shop"

_ch13_js_full() { printf '%s/%s' "$ORG" "$JS_REPO"; }

_ch13_dependabot_config() {
  cat <<'EOF'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
EOF
}

_ch13_seed_config() {
  log_step "seeding .github/dependabot.yml"
  gh_put_file "$ORG" "$JS_REPO" ".github/dependabot.yml" \
    "Add Dependabot version + security update config" \
    "$(_ch13_dependabot_config)"
}

_ch13_seed_risky_branch() {
  log_step "seeding feature/add-risky-dep (known-vulnerable dependency)"
  gh_create_branch "$ORG" "$JS_REPO" "feature/add-risky-dep" main
  gh_put_file "$ORG" "$JS_REPO" "wth-risky-dep/package.json" \
    "Add a known-vulnerable dependency (seed, for dependency-review)" \
"$(cat <<'EOF'
{
  "name": "wth-ch13-risky-dep",
  "version": "1.0.0",
  "private": true,
  "description": "wth-ch13 SEED — pins known-vulnerable versions so dependency review flags the PR diff.",
  "dependencies": {
    "lodash": "4.17.4",
    "minimist": "1.2.0",
    "marked": "0.3.6"
  }
}
EOF
)" \
    "feature/add-risky-dep"
}

# ===========================================================================
wth_provision() {
  juice_shop_import "$ORG" "$JS_REPO" "$JUICE_SHOP_REF"
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$JS_REPO"; then
    die "repo $(_ch13_js_full) missing after import — aborting seed"
  fi
  _ch13_seed_config
  _ch13_seed_risky_branch
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - enable Dependabot alerts + security updates in Security settings"
  log_info "  - review the dependency graph and triage the alerts"
  log_info "  - open a PR from feature/add-risky-dep and read the dependency-review result"
  log_warn "manual: Dependabot alerts/security updates are toggled in repo Security settings."
}

wth_teardown() {
  guard_prefix "$JS_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$JS_REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$JS_REPO"; then
    local cfg branch
    cfg="present"; gh_file_exists "$ORG" "$JS_REPO" ".github/dependabot.yml" || cfg="MISSING"
    branch="present"; gh_branch_exists "$ORG" "$JS_REPO" "feature/add-risky-dep" || branch="MISSING"
    log_ok "repo $(_ch13_js_full) present — dependabot.yml $cfg, feature/add-risky-dep $branch"
  else
    log_info "repo $(_ch13_js_full) not provisioned"
  fi
}
