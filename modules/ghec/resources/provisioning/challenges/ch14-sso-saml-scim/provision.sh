# shellcheck shell=bash
#
# challenges/ch14-sso-saml-scim/provision.sh
#
# ch14 has NO Juice Shop and does NOT touch live identity settings. It seeds a
# wth-ch14-identity-runbook repo (SAML app runbook, SCIM rollout checklist,
# join/leave test script) and prints a staged reference to the org-scoped
# identity settings. SSO/SCIM are NOT auto-enabled — wiring them is the learning,
# so the provisioner only emits clear manual-step guidance.

RUNBOOK_REPO="wth-${CHID}-identity-runbook"

_ch14_repo_full() { printf '%s/%s' "$ORG" "$RUNBOOK_REPO"; }

_ch14_seed_runbook() {
  log_step "seeding identity runbook content"

  gh_put_file "$ORG" "$RUNBOOK_REPO" "README.md" \
    "Add identity runbook overview" \
"$(cat <<EOF
# wth-ch14 — Identity Runbook

Working notes for wiring **SAML SSO** and **SCIM** provisioning for the
\`$ORG\` organization. Nothing here changes live settings; it is the plan you
execute by hand in the org's identity settings.

- \`SAML-RUNBOOK.md\` — IdP SAML app settings + GitHub SSO configuration order
- \`SCIM-CHECKLIST.md\` — SCIM rollout checklist
- \`scripts/join-leave-test.sh\` — manual join/leave provisioning test

> SSO is intentionally NOT enabled by setup — enabling it is the exercise.
EOF
)"

  gh_put_file "$ORG" "$RUNBOOK_REPO" "SAML-RUNBOOK.md" \
    "Add SAML configuration runbook" \
"$(cat <<EOF
# SAML SSO Runbook — $ORG

## IdP side (Entra ID / Okta / etc.)
1. Create a new SAML application.
2. Set the **Entity ID** to \`https://github.com/orgs/$ORG\`.
3. Set the **ACS URL** to \`https://github.com/orgs/$ORG/saml/consume\`.
4. Map \`NameID\` to the user's primary email.

## GitHub side
1. Open the org **Authentication security** page:
   \`https://github.com/organizations/$ORG/settings/security\`
2. Enable SAML SSO, paste the IdP **Sign-on URL**, **Issuer**, and **certificate**.
3. **Test** the configuration before requiring it.
4. Require SAML SSO only after a successful test.
EOF
)"

  gh_put_file "$ORG" "$RUNBOOK_REPO" "SCIM-CHECKLIST.md" \
    "Add SCIM rollout checklist" \
"$(cat <<EOF
# SCIM Rollout Checklist — $ORG

- [ ] SAML SSO enabled and tested first (SCIM rides on top of SAML).
- [ ] Generate a SCIM provisioning token for the IdP.
- [ ] SCIM API base: \`https://api.github.com/scim/v2/organizations/$ORG\`
- [ ] Configure provisioning in the IdP and assign a pilot group.
- [ ] Verify a provisioned user appears under org members.
- [ ] Verify de-provisioning (leave) removes access.
- [ ] Expand from pilot group to all users.
EOF
)"

  gh_put_file "$ORG" "$RUNBOOK_REPO" "scripts/join-leave-test.sh" \
    "Add join/leave provisioning test script" \
"$(cat <<'EOF'
#!/usr/bin/env bash
# wth-ch14 — manual join/leave provisioning test (read-only helper).
# Run AFTER SCIM is configured. Replace USER with a pilot account login.
set -euo pipefail
ORG="${1:?usage: join-leave-test.sh <org> <user>}"
USER="${2:?usage: join-leave-test.sh <org> <user>}"
echo "Checking SCIM-provisioned identity for $USER in $ORG ..."
gh api "scim/v2/organizations/$ORG/Users?filter=userName eq \"$USER\"" \
  --jq '.Resources[] | {id, userName, active}'
echo "De-provision the user in your IdP, then re-run to confirm 'active: false'."
EOF
)"
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$RUNBOOK_REPO" public
  _ch14_seed_runbook
  echo >&2
  log_info "Staged identity settings reference (act on these by hand):"
  log_info "  - Authentication security page: https://github.com/organizations/$ORG/settings/security"
  log_info "  - SCIM API base: https://api.github.com/scim/v2/organizations/$ORG"
  log_warn "manual: SSO/SAML and SCIM are NOT auto-enabled — configuring them is the challenge."
}

wth_teardown() {
  guard_prefix "$RUNBOOK_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$RUNBOOK_REPO"
  log_warn "manual: if you enabled SSO/SCIM in org settings, disable them by hand — teardown does not touch identity settings."
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$RUNBOOK_REPO"; then
    local runbook checklist
    runbook="present"; gh_file_exists "$ORG" "$RUNBOOK_REPO" "SAML-RUNBOOK.md" || runbook="MISSING"
    checklist="present"; gh_file_exists "$ORG" "$RUNBOOK_REPO" "SCIM-CHECKLIST.md" || checklist="MISSING"
    log_ok "repo $(_ch14_repo_full) present — SAML-RUNBOOK.md $runbook, SCIM-CHECKLIST.md $checklist"
  else
    log_info "repo $(_ch14_repo_full) not provisioned"
  fi
}
