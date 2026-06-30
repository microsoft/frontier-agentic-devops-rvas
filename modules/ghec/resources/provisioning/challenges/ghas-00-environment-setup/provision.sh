# shellcheck shell=bash
#
# ghas-00 imports OWASP Juice Shop into the participant/organizer-owned org,
# seeds the GHAS config files used by the module, and enables repo-level
# security features where the authenticated user and org license allow it.

GHAS_REPO="${REPO:-wth-${CHID}-juice-shop}"
GHAS_RESOURCES_DIR="$(cd "$SCRIPT_DIR/../../../../.." && pwd)/modules/ghas/resources/github"

_ghas_full() { printf '%s/%s' "$ORG" "$GHAS_REPO"; }

_ghas_read_resource() {
  local rel="$1" file
  file="$GHAS_RESOURCES_DIR/$rel"
  [[ -f "$file" ]] || die "missing GHAS resource fixture: $file"
  cat "$file"
}

_ghas_dependabot_for_imported_repo() {
  # The curriculum repo uses app/ as a lazy Juice Shop symlink. The provisioned
  # GHAS target is a fresh Juice Shop import, so npm manifests live at repo root.
  _ghas_read_resource "dependabot.yml" | sed 's#directory: "/app"#directory: "/"#'
}

_ghas_mutation_soft() {
  local desc="$1"; shift
  if run_mutation "$@"; then
    [[ "${DRY_RUN:-false}" == "true" ]] || log_ok "$desc"
  else
    log_warn "$desc failed — check org/repo permissions or enable it manually in Settings → Code security and analysis"
  fi
}

_ghas_enable_features() {
  log_step "enabling GHAS repository features where available"

  _ghas_mutation_soft "Actions enabled" \
    gh api -X PUT "repos/$ORG/$GHAS_REPO/actions/permissions" \
      -F enabled=true -f allowed_actions=all

  _ghas_mutation_soft "advanced security, secret scanning, and push protection enabled" \
    gh api -X PATCH "repos/$ORG/$GHAS_REPO" \
      -F 'security_and_analysis[advanced_security][status]=enabled' \
      -F 'security_and_analysis[secret_scanning][status]=enabled' \
      -F 'security_and_analysis[secret_scanning_push_protection][status]=enabled'

  _ghas_mutation_soft "Dependabot alerts enabled" \
    gh api -X PUT "repos/$ORG/$GHAS_REPO/vulnerability-alerts"

  _ghas_mutation_soft "Dependabot security updates enabled" \
    gh api -X PUT "repos/$ORG/$GHAS_REPO/automated-security-fixes"
}

_ghas_seed_configs() {
  log_step "seeding GHAS config files"
  gh_put_file "$ORG" "$GHAS_REPO" ".github/workflows/codeql.yml" \
    "Add GHAS CodeQL workflow" \
    "$(_ghas_read_resource "workflows/codeql.yml")"
  gh_put_file "$ORG" "$GHAS_REPO" ".github/codeql/codeql-config.yml" \
    "Add GHAS CodeQL configuration" \
    "$(_ghas_read_resource "codeql/codeql-config.yml")"
  gh_put_file "$ORG" "$GHAS_REPO" ".github/dependabot.yml" \
    "Add Dependabot configuration" \
    "$(_ghas_dependabot_for_imported_repo)"
}

_ghas_trigger_codeql() {
  log_step "triggering first CodeQL scan"
  _ghas_mutation_soft "CodeQL workflow dispatch queued" \
    gh workflow run codeql.yml --repo "$ORG/$GHAS_REPO" --ref main
}

# ===========================================================================
wth_provision() {
  juice_shop_import "$ORG" "$GHAS_REPO" "$JUICE_SHOP_REF"
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$GHAS_REPO"; then
    die "repo $(_ghas_full) missing after import — aborting GHAS setup"
  fi

  _ghas_enable_features
  _ghas_seed_configs
  _ghas_trigger_codeql

  echo >&2
  log_info "Next steps:"
  log_info "  - open https://github.com/$ORG/$GHAS_REPO/settings/security_analysis and confirm all requested GHAS features are enabled"
  log_info "  - manually add any participants or teams that need access to $(_ghas_full)"
  log_info "  - have each participant clone $(_ghas_full) and push a personal/team branch"
}

wth_teardown() {
  guard_prefix "$GHAS_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$GHAS_REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$GHAS_REPO"; then
    local codeql config dependabot visibility security
    codeql="present"; gh_file_exists "$ORG" "$GHAS_REPO" ".github/workflows/codeql.yml" || codeql="MISSING"
    config="present"; gh_file_exists "$ORG" "$GHAS_REPO" ".github/codeql/codeql-config.yml" || config="MISSING"
    dependabot="present"; gh_file_exists "$ORG" "$GHAS_REPO" ".github/dependabot.yml" || dependabot="MISSING"
    visibility="$(gh repo view "$ORG/$GHAS_REPO" --json visibility --jq '.visibility' 2>/dev/null || echo unknown)"
    security="$(gh api "repos/$ORG/$GHAS_REPO" --jq '.security_and_analysis // {}' 2>/dev/null || echo '{}')"
    log_ok "repo $(_ghas_full) present ($visibility) — codeql.yml $codeql, codeql config $config, dependabot.yml $dependabot"
    log_info "security_and_analysis: $security"
  else
    log_info "repo $(_ghas_full) not provisioned"
  fi
}
