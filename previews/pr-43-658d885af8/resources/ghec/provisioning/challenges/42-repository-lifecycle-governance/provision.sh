# shellcheck shell=bash
# challenges/42-repository-lifecycle-governance/provision.sh
# Seeds lifecycle sample repositories. Archive, transfer, delete, visibility, and
# organization-wide settings remain explicit participant-approved steps.

R_ACTIVE="ghec-${CHID}-active-service"
R_DEPRECATED="ghec-${CHID}-deprecated-service"
R_ARCHIVE="ghec-${CHID}-archive-candidate"

_ch42_repo_full() { printf '%s/%s' "$ORG" "$1"; }

_ch42_readme() {
  local state="$1" owner="$2"
  cat <<EOT
# ${state}

Lifecycle sample for ghec-${CHID}.

- Lifecycle state: ${state}
- Proposed owner: ${owner}
- Review required before archive, transfer, or delete actions.
EOT
}

_ch42_seed_labels() {
  local repo="$1"
  log_step "seeding lifecycle labels in $repo"
  local existing
  existing="$(gh label list --repo "$(_ch42_repo_full "$repo")" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "lifecycle: active|0e8a16|Repository is active"
    "lifecycle: deprecated|fbca04|Repository is deprecated or replaced"
    "lifecycle: archive-candidate|d73a4a|Repository needs archive approval"
    "governance: decision-needed|5319e7|Owner decision required"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists in $repo (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch42_repo_full "$repo")" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch42_seed_issue() {
  local repo="$1" state="$2" body="$3" label="$4" title="Lifecycle review: ${state}"
  log_step "seeding lifecycle review issue in $repo"
  local existing
  existing="$(gh issue list --repo "$(_ch42_repo_full "$repo")" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$title"; then log_ok "issue '$title' exists (skip)"; return 0; fi
  run_mutation gh issue create --repo "$(_ch42_repo_full "$repo")" --title "$title" --label "$label" --body "$body"
}

_ch42_seed_repo() {
  local repo="$1" state="$2" owner="$3" label="$4" body="$5"
  gh_put_file "$ORG" "$repo" "README.md" "Add lifecycle sample README" "$(_ch42_readme "$state" "$owner")"
  _ch42_seed_labels "$repo"
  _ch42_seed_issue "$repo" "$state" "$body" "$label"
}

ghec_provision() {
  gh_create_repo "$ORG" "$R_ACTIVE" private
  gh_create_repo "$ORG" "$R_DEPRECATED" private
  gh_create_repo "$ORG" "$R_ARCHIVE" private
  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_ACTIVE" && _ch42_seed_repo "$R_ACTIVE" "active" "payments-team" "lifecycle: active" "Keep active. Confirm owner, purpose, and next review date."
    gh_repo_exists "$ORG" "$R_DEPRECATED" && _ch42_seed_repo "$R_DEPRECATED" "deprecated" "platform-governance" "lifecycle: deprecated" "Replacement exists. Confirm retention needs and deprecation notice."
    gh_repo_exists "$ORG" "$R_ARCHIVE" && _ch42_seed_repo "$R_ARCHIVE" "archive candidate" "owner-needed" "lifecycle: archive-candidate" "Archive only after explicit approval and retention review."
  else
    log_plan "would seed README, labels, and lifecycle review issues into ch42 sample repos"
  fi
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - define lifecycle states, criteria, and approvers"
  log_info "  - apply safe markers first; archive/transfer/delete only with explicit approval"
}

ghec_teardown() {
  local r
  for r in "$R_ACTIVE" "$R_DEPRECATED" "$R_ARCHIVE"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r issues labels
  for r in "$R_ACTIVE" "$R_DEPRECATED" "$R_ARCHIVE"; do
    if gh_repo_exists "$ORG" "$r"; then
      issues="$(gh issue list --repo "$(_ch42_repo_full "$r")" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"
      labels="$(gh label list --repo "$(_ch42_repo_full "$r")" --limit 100 --json name --jq 'length' 2>/dev/null || echo '?')"
      log_ok "repo $ORG/$r present — $issues issues, $labels labels"
    else
      log_info "repo $ORG/$r absent"
    fi
  done
}
