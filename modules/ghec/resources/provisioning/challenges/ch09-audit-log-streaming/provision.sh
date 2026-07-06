# shellcheck shell=bash
#
# challenges/ch09-audit-log-streaming/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: ghec_provision / ghec_teardown / ghec_status.
#
# ORG-SCOPED. ch09 builds a populated target repo (so audit events have a
# subject), an auditors team, and prints a sample of recent org audit events.
# Configuring an actual audit-log STREAM (to Azure/S3/Splunk/etc.) cannot be
# fully automated via the API — that part is a documented manual step.

R_TARGET="ghec-${CHID}-audit-target"
TEAM="ghec-${CHID}-auditors"

_ch09_seed_target() {
  gh_put_file "$ORG" "$R_TARGET" "README.md" "seed README (ghec-${CHID})" \
"# ${R_TARGET}

Seeded by ghec-${CHID} (Audit Log Streaming). Activity here (pushes, team
changes, settings edits) shows up in the org audit log. Set up streaming and
verify these events land in your sink."
  gh_put_file "$ORG" "$R_TARGET" "src/index.js" "seed src (ghec-${CHID})" \
"console.log('audit target — ghec-${CHID}');
"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$R_TARGET" private
  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_TARGET" && _ch09_seed_target
  else
    log_plan "would seed README + src into $R_TARGET"
  fi

  gh_create_team "$ORG" "$TEAM" "ghec-${CHID} auditors team"

  log_step "recent org audit events sample for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api orgs/$ORG/audit-log (first few events)"
  else
    if gh api "orgs/$ORG/audit-log?per_page=5" --jq '.[] | {action, actor, created_at}' 2>/dev/null; then
      :
    else
      log_warn "could not read the audit log — this API is GHEC-only and needs a token with 'read:audit_log' (admin:org)."
    fi
  fi

  echo >&2
  log_warn "MANUAL STEP: configuring an audit-log STREAM endpoint (Azure Blob, S3, Splunk, Datadog, etc.) is not API-automatable — set it up under Org Settings → Audit log → Log streaming."
}

ghec_teardown() {
  guard_prefix "$R_TARGET" "$CHID" || return 1
  gh_delete_repo "$ORG" "$R_TARGET"
  guard_prefix "$TEAM" "$CHID" || return 1
  gh_delete_team "$ORG" "$TEAM"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$R_TARGET"; then log_ok "repo $ORG/$R_TARGET present"; else log_info "repo $ORG/$R_TARGET absent"; fi
  if gh_team_exists "$ORG" "$TEAM"; then log_ok "team $TEAM present"; else log_info "team $TEAM absent"; fi
}
