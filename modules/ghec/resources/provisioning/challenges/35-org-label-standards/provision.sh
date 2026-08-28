# shellcheck shell=bash
#
# challenges/35-org-label-standards/provision.sh
#
# Seeds a brownfield repo with inconsistent labels and a clean repo for
# organization default-label validation. Organization default labels themselves
# are a participant-controlled governance change, not a setup mutation.

R_EXISTING="ghec-${CHID}-existing-service"
R_NEW="ghec-${CHID}-new-service"

_ch35_repo_full() { printf '%s/%s' "$ORG" "$1"; }

_ch35_seed_readme() {
  local repo="$1" purpose="$2"
  gh_put_file "$ORG" "$repo" "README.md" "Add label governance sample README" \
"# ${repo}

${purpose}

Seeded by ghec-${CHID}. Use this repository only for the organization label standards activity."
}

_ch35_seed_inconsistent_labels() {
  log_step "seeding inconsistent labels in $R_EXISTING"
  local existing
  existing="$(gh label list --repo "$(_ch35_repo_full "$R_EXISTING")" --limit 200 \
    --json name --jq '.[].name' 2>/dev/null || true)"

  local labels=(
    "bug|d73a4a|Something is broken"
    "Bug|b60205|Duplicate casing of bug"
    "urgent|e11d21|Drop everything"
    "sev1|fbca04|High severity, unclear mapping"
    "backend|0e8a16|Backend area"
    "needs review|d876e3|Needs review with non-standard spacing"
    "enhancement|a2eeef|New feature or request"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    if printf '%s\n' "$existing" | grep -qxiF "$name"; then
      log_ok "label '$name' exists with different casing (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch35_repo_full "$R_EXISTING")" \
      --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch35_seed_issues() {
  log_step "seeding issues that need label reconciliation"
  local existing
  existing="$(gh issue list --repo "$(_ch35_repo_full "$R_EXISTING")" --state all --limit 100 \
    --json title --jq '.[].title' 2>/dev/null || true)"

  local issues=(
    "Checkout API intermittently returns 500::bug,urgent,backend"
    "Docs typo in onboarding guide::enhancement,needs review"
    "Login outage for pilot users::Bug,sev1"
    "Add platform health endpoint::enhancement,backend"
  )
  local entry title labels
  for entry in "${issues[@]}"; do
    title="${entry%%::*}"
    labels="${entry#*::}"
    if printf '%s\n' "$existing" | grep -qxF "$title"; then
      log_ok "issue '$title' exists (skip)"
      continue
    fi
    local args=(gh issue create --repo "$(_ch35_repo_full "$R_EXISTING")" \
      --title "$title" \
      --body "Seeded by ghec-ch35. Reconcile this issue from local labels to the approved organization taxonomy.")
    local l
    IFS=',' read -ra _ls <<< "$labels"
    for l in "${_ls[@]}"; do args+=(--label "$l"); done
    run_mutation "${args[@]}"
  done
}

_ch35_print_org_labels() {
  log_step "organization default-label snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api /orgs/$ORG/labels"
    return 0
  fi
  gh api "/orgs/$ORG/labels" --paginate \
    --jq '.[] | {name, color, description}' 2>/dev/null \
    || log_warn "could not read organization default labels (needs org owner/admin scope)"
}

ghec_provision() {
  gh_create_repo "$ORG" "$R_EXISTING" private
  gh_create_repo "$ORG" "$R_NEW" private

  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_EXISTING" && _ch35_seed_readme "$R_EXISTING" "Brownfield service with inconsistent repository-local labels."
    gh_repo_exists "$ORG" "$R_NEW" && _ch35_seed_readme "$R_NEW" "Clean validation target for organization default-label inheritance."
  else
    log_plan "would seed README files into $R_EXISTING and $R_NEW"
  fi

  _ch35_seed_inconsistent_labels
  _ch35_seed_issues
  _ch35_print_org_labels

  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - approve an organization label taxonomy"
  log_info "  - configure organization default labels"
  log_info "  - verify a new repo inherits them and reconcile $R_EXISTING"
}

ghec_teardown() {
  local r
  for r in "$R_EXISTING" "$R_NEW"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r labels issues
  for r in "$R_EXISTING" "$R_NEW"; do
    if gh_repo_exists "$ORG" "$r"; then
      labels="$(gh label list --repo "$(_ch35_repo_full "$r")" --limit 200 \
        --json name --jq 'length' 2>/dev/null || echo '?')"
      issues="$(gh issue list --repo "$(_ch35_repo_full "$r")" --state all --limit 200 \
        --json number --jq 'length' 2>/dev/null || echo '?')"
      log_ok "repo $ORG/$r present — $labels labels, $issues issues"
    else
      log_info "repo $ORG/$r absent"
    fi
  done
}
