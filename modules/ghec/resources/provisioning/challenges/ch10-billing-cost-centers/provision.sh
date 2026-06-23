# shellcheck shell=bash
#
# challenges/ch10-billing-cost-centers/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: wth_provision / wth_teardown / wth_status.
#
# ORG-SCOPED. ch10 builds a usage-generator repo (a tiny workflow_dispatch
# Action you can run to burn Actions minutes) and a cost-report repo (a small
# reconciliation script + REPORT.md). It prints a current usage snapshot.
# Creating/assigning cost centers is not fully API-automatable — manual step.

R_GEN="wth-${CHID}-usage-generator"
R_RPT="wth-${CHID}-cost-report"

_ch10_seed_generator() {
  gh_put_file "$ORG" "$R_GEN" "README.md" "seed README (wth-${CHID})" \
"# ${R_GEN}

Seeded by wth-${CHID} (Billing & Cost Centers). Run the 'usage' workflow
(Actions → Run workflow) a few times to generate Actions minutes, then watch
them show up in billing and your cost-report reconciliation."
  gh_put_file "$ORG" "$R_GEN" ".github/workflows/usage.yml" "seed usage workflow (wth-${CHID})" \
"name: usage
# wth-${CHID} — manually triggered to burn a little Actions usage.
on:
  workflow_dispatch:
    inputs:
      seconds:
        description: 'How long to sleep (sim work)'
        default: '5'
jobs:
  burn:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo \"Generating usage for wth-${CHID}...\"
          sleep \"\${{ inputs.seconds }}\"
          echo 'done'
"
}

_ch10_seed_report() {
  gh_put_file "$ORG" "$R_RPT" "README.md" "seed README (wth-${CHID})" \
"# ${R_RPT}

Seeded by wth-${CHID}. A starting point for reconciling Actions/usage against
cost centers. Flesh out \`reconcile.js\` to pull billing data and group spend."
  gh_put_file "$ORG" "$R_RPT" "reconcile.js" "seed reconciliation script (wth-${CHID})" \
"#!/usr/bin/env node
// wth-${CHID} starter reconciliation. Replace the sample with real billing data
// from: gh api orgs/<org>/settings/billing/actions
const sample = { included_minutes: 3000, total_minutes_used: 0, cost_centers: {} };
console.log('wth-${CHID} usage reconciliation');
console.table(sample);
"
  gh_put_file "$ORG" "$R_RPT" "REPORT.md" "seed REPORT.md (wth-${CHID})" \
"# Cost Report (wth-${CHID})

| Cost center | Repos | Actions minutes | Notes |
|-------------|-------|-----------------|-------|
| _unassigned_ | ${R_GEN}, ${R_RPT} | TBD | fill in after running usage |

> Update this after assigning repos to cost centers and running the generator."
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$R_GEN" private
  gh_create_repo "$ORG" "$R_RPT" private

  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_GEN" && _ch10_seed_generator
    gh_repo_exists "$ORG" "$R_RPT" && _ch10_seed_report
  else
    log_plan "would seed usage workflow into $R_GEN and reconcile.js + REPORT.md into $R_RPT"
  fi

  log_step "current Actions usage snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api orgs/$ORG/settings/billing/actions"
  else
    if gh api "orgs/$ORG/settings/billing/actions" \
        --jq '{total_minutes_used, included_minutes, total_paid_minutes_used}' 2>/dev/null; then
      :
    else
      log_warn "could not read billing — needs a token with 'read:org' / billing access (GHEC org billing manager)."
    fi
  fi

  echo >&2
  log_warn "MANUAL STEP: creating cost centers and assigning repos/users to them is done in Enterprise billing settings (and the Billing Platform API where available) — it is not fully automatable here."
}

wth_teardown() {
  local r
  for r in "$R_GEN" "$R_RPT"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  local r
  for r in "$R_GEN" "$R_RPT"; do
    if gh_repo_exists "$ORG" "$r"; then log_ok "repo $ORG/$r present"; else log_info "repo $ORG/$r absent"; fi
  done
}
