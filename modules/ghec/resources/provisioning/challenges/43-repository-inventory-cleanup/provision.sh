# shellcheck shell=bash
# challenges/43-repository-inventory-cleanup/provision.sh
# Seeds inventory cleanup sample repositories. Archive, transfer, delete,
# visibility, and organization settings are participant-approved actions only.

R_OWNED="ghec-${CHID}-owned-service"
R_ORPHAN="ghec-${CHID}-orphan-tool"
R_DUP="ghec-${CHID}-duplicate-api"

_ch43_repo_full() { printf '%s/%s' "$ORG" "$1"; }

_ch43_readme() {
  local purpose="$1" owner="$2"
  cat <<EOT
# Inventory Sample

- Purpose: ${purpose}
- Owner: ${owner}
- Cleanup decision: pending participant review
EOT
}

_ch43_seed_labels() {
  local repo="$1"
  log_step "seeding inventory labels in $repo"
  local existing
  existing="$(gh label list --repo "$(_ch43_repo_full "$repo")" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "inventory: owner-needed|d73a4a|Repository needs an accountable owner"
    "inventory: duplicate-review|fbca04|Repository may duplicate another purpose"
    "inventory: keep|0e8a16|Repository should remain active"
    "governance: cleanup-decision|5319e7|Cleanup decision required"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists in $repo (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch43_repo_full "$repo")" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch43_seed_issue() {
  local repo="$1" title="$2" label="$3" body="$4"
  log_step "seeding inventory review issue in $repo"
  local existing
  existing="$(gh issue list --repo "$(_ch43_repo_full "$repo")" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$title"; then log_ok "issue '$title' exists (skip)"; return 0; fi
  run_mutation gh issue create --repo "$(_ch43_repo_full "$repo")" --title "$title" --label "$label" --body "$body"
}

_ch43_seed_topics() {
  local repo="$1" topics="$2"
  log_step "seeding topics for $repo"
  if [[ "$DRY_RUN" == "true" ]]; then log_plan "would set topics on $repo: $topics"; return 0; fi
  local args=(-X PUT "repos/$ORG/$repo/topics" -H "Accept: application/vnd.github+json")
  local topic
  IFS=',' read -ra _topics <<< "$topics"
  for topic in "${_topics[@]}"; do args+=(-f "names[]=$topic"); done
  gh api "${args[@]}" >/dev/null \
    || log_warn "could not set topics for $repo"
}

_ch43_seed_repo() {
  local repo="$1" purpose="$2" owner="$3" title="$4" label="$5" body="$6" topics="$7"
  gh_put_file "$ORG" "$repo" "README.md" "Add inventory sample README" "$(_ch43_readme "$purpose" "$owner")"
  _ch43_seed_labels "$repo"
  _ch43_seed_issue "$repo" "$title" "$label" "$body"
  _ch43_seed_topics "$repo" "$topics"
}

ghec_provision() {
  gh_create_repo "$ORG" "$R_OWNED" private
  gh_create_repo "$ORG" "$R_ORPHAN" private
  gh_create_repo "$ORG" "$R_DUP" private
  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_OWNED" && _ch43_seed_repo "$R_OWNED" "Healthy owned service" "payments-team" "Inventory decision: keep" "inventory: keep" "Owner and purpose are known. Confirm review cadence." "inventory-sample,owner-known"
    gh_repo_exists "$ORG" "$R_ORPHAN" && _ch43_seed_repo "$R_ORPHAN" "Unclear legacy tool" "owner-needed" "Inventory decision: owner needed" "inventory: owner-needed" "Find owner or queue lifecycle decision with approval." "inventory-sample,owner-needed"
    gh_repo_exists "$ORG" "$R_DUP" && _ch43_seed_repo "$R_DUP" "Possible duplicate API" "platform-governance" "Inventory decision: duplicate review" "inventory: duplicate-review" "Compare purpose with existing APIs before merge/archive decisions." "inventory-sample,duplicate-review"
  else
    log_plan "would seed README, labels, topics, and inventory review issues into ch43 sample repos"
  fi
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - export repository inventory and classify cleanup decisions"
  log_info "  - apply safe metadata updates; archive/transfer/delete only with explicit approval"
}

ghec_teardown() {
  local r
  for r in "$R_OWNED" "$R_ORPHAN" "$R_DUP"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r issues labels
  for r in "$R_OWNED" "$R_ORPHAN" "$R_DUP"; do
    if gh_repo_exists "$ORG" "$r"; then
      issues="$(gh issue list --repo "$(_ch43_repo_full "$r")" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"
      labels="$(gh label list --repo "$(_ch43_repo_full "$r")" --limit 100 --json name --jq 'length' 2>/dev/null || echo '?')"
      log_ok "repo $ORG/$r present — $issues issues, $labels labels"
    else
      log_info "repo $ORG/$r absent"
    fi
  done
}
