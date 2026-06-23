# shellcheck shell=bash
#
# challenges/ch11-secret-scanning-push-protection/provision.sh
#
# Sourced by scripts/setup.sh (exports ORG CHID SLUG APP JUICE_SHOP_REF DRY_RUN
# ASSUME_YES NAMESPACE REPO META; provides log_*, run_mutation, gh_*,
# guard_prefix, juice_shop_import, meta_*).
#
# ch11 builds a PUBLIC OWASP Juice Shop import (own copy, pinned v20.0.0) and
# PLANTS high-confidence, NON-LIVE partner-pattern secrets so secret scanning
# has detectable material (Juice Shop's own secrets are app-internal, not
# partner-pattern). A SECRETS-MANIFEST.md documents every plant; a
# feature/leaky-config branch carries a fresh secret to exercise push protection.

JS_REPO="wth-${CHID}-juice-shop"

# Non-live / synthetic secrets. The AWS pair is AWS's own published EXAMPLE
# documentation key (not a live credential); the GitHub-style token is padded
# filler. They are pattern-shaped ONLY to trip detection — they grant nothing.
_AWS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
_AWS_SECRET="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
_GH_TOKEN="ghp_000000000000000000000000000000WTHch11"
_AWS_KEY_ID_FRESH="AKIAIOSFODNN7WTHFRESH"

_ch11_js_full() { printf '%s/%s' "$ORG" "$JS_REPO"; }

# ---------------------------------------------------------------------------
# planted secrets (committed onto main as separate commits == "across history")
# ---------------------------------------------------------------------------
_ch11_plant_secrets() {
  log_step "planting non-live partner-pattern secrets"

  gh_put_file "$ORG" "$JS_REPO" "config/aws-credentials.ini" \
    "Add legacy AWS uploader credentials (seed)" \
"$(cat <<EOF
; wth-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
[default]
aws_access_key_id = ${_AWS_KEY_ID}
aws_secret_access_key = ${_AWS_SECRET}
region = us-east-1
EOF
)"

  gh_put_file "$ORG" "$JS_REPO" "scripts/deploy.sh" \
    "Add deploy helper with embedded token (seed)" \
"$(cat <<EOF
#!/usr/bin/env bash
# wth-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
set -e
GITHUB_TOKEN="${_GH_TOKEN}"
echo "deploying with \$GITHUB_TOKEN" >/dev/null
EOF
)"
}

_ch11_seed_manifest() {
  log_step "writing SECRETS-MANIFEST.md"
  gh_put_file "$ORG" "$JS_REPO" "SECRETS-MANIFEST.md" \
    "Add SECRETS-MANIFEST for wth-ch11" \
"$(cat <<EOF
# SECRETS-MANIFEST — wth-ch11

Every secret below is **synthetic / non-live** and exists only so secret
scanning + push protection have partner-pattern material to detect. None
grant any access. Reconcile each row against the secret-scanning alert list.

| # | Location | Secret type | Pattern | Branch |
|---|----------|-------------|---------|--------|
| 1 | \`config/aws-credentials.ini\` | AWS access key id + secret | \`AKIA…\` | main |
| 2 | \`scripts/deploy.sh\` | GitHub-style token | \`ghp_…\` | main |
| 3 | \`config/extra-uploader.ini\` | AWS access key id (fresh) | \`AKIA…\` | feature/leaky-config |

All values are documented EXAMPLE / padded-filler credentials. Safe to
resolve as "used in tests" once you have reviewed each alert.
EOF
)"
}

# ---------------------------------------------------------------------------
# fresh secret on a branch (push-protection exercise)
# ---------------------------------------------------------------------------
_ch11_seed_leaky_branch() {
  log_step "seeding feature/leaky-config with a fresh planted secret"
  gh_create_branch "$ORG" "$JS_REPO" "feature/leaky-config" main
  gh_put_file "$ORG" "$JS_REPO" "config/extra-uploader.ini" \
    "Add second uploader credential (seed)" \
"$(cat <<EOF
; wth-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
[uploader]
aws_access_key_id = ${_AWS_KEY_ID_FRESH}
aws_secret_access_key = ${_AWS_SECRET}
EOF
)" \
    "feature/leaky-config"
}

# ===========================================================================
# CONTRACT FUNCTIONS
# ===========================================================================

wth_provision() {
  juice_shop_import "$ORG" "$JS_REPO" "$JUICE_SHOP_REF"
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$JS_REPO"; then
    die "repo $(_ch11_js_full) missing after import — aborting seed"
  fi
  _ch11_plant_secrets
  _ch11_seed_manifest
  _ch11_seed_leaky_branch
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - enable secret scanning + push protection in the repo's Security settings"
  log_info "  - reconcile each SECRETS-MANIFEST.md row against the alert list"
  log_info "  - try pushing the fresh secret to confirm push protection blocks it"
  log_warn "manual: enabling secret scanning/push protection is the learning — not auto-enabled."
}

wth_teardown() {
  guard_prefix "$JS_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$JS_REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$JS_REPO"; then
    local manifest branch
    manifest="present"; gh_file_exists "$ORG" "$JS_REPO" "SECRETS-MANIFEST.md" || manifest="MISSING"
    branch="present"; gh_branch_exists "$ORG" "$JS_REPO" "feature/leaky-config" || branch="MISSING"
    log_ok "repo $(_ch11_js_full) present — SECRETS-MANIFEST.md $manifest, feature/leaky-config $branch"
  else
    log_info "repo $(_ch11_js_full) not provisioned"
  fi
}
