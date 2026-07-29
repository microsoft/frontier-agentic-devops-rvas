# shellcheck shell=bash
# challenges/ch44-policy-drift-detection/provision.sh
# Seeds a baseline repo and an intentionally drifted repo. Organization rules,
# default permissions, and high-impact controls are participant-approved only.

R_BASE="ghec-${CHID}-policy-baseline"
R_DRIFT="ghec-${CHID}-drifted-service"

_ch44_repo_full() { printf '%s/%s' "$ORG" "$1"; }

_ch44_readme() { cat <<'EOT'
# Policy Baseline Sample

This repository represents a sample repository policy contract.

Required baseline:

- README exists
- CODEOWNERS exists
- Pull request template exists
- Issue template exists
- Labels: status: needs-triage, type: bug, priority: p2
- Topics: policy-baseline, owner-known
EOT
}

_ch44_codeowners() { cat <<'EOT'
* @octo-org/platform-governance
EOT
}

_ch44_issue_form() { cat <<'EOT'
name: Policy exception

description: Request a time-bound exception to repository policy.
title: "Policy exception: <control>"
labels:
  - "policy: exception"
body:
  - type: input
    id: control
    attributes:
      label: Control
    validations:
      required: true
  - type: textarea
    id: reason
    attributes:
      label: Reason and compensating control
    validations:
      required: true
EOT
}

_ch44_pr_template() { cat <<'EOT'
## Policy baseline checklist

- [ ] Owner evidence remains current
- [ ] Required files are present
- [ ] Required labels/topics remain present
- [ ] Drift exceptions are linked and time-bound
EOT
}

_ch44_drift_readme() { cat <<'EOT'
# Drifted Service

This repository intentionally misses parts of the baseline. Use it to test drift detection.
EOT
}

_ch44_seed_labels() {
  local repo="$1" mode="$2"
  log_step "seeding policy labels in $repo"
  local existing
  existing="$(gh label list --repo "$(_ch44_repo_full "$repo")" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=("status: needs-triage|fbca04|Needs initial triage" "type: bug|b60205|Defect in existing behavior" "priority: p2|cfd3d7|Normal priority" "policy: exception|d73a4a|Approved policy exception")
  [[ "$mode" == "drifted" ]] && labels=("type: bug|b60205|Defect in existing behavior")
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists in $repo (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch44_repo_full "$repo")" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch44_seed_topics() {
  local repo="$1" first="$2" second="$3"
  log_step "seeding topics for $repo"
  if [[ "$DRY_RUN" == "true" ]]; then log_plan "would set topics on $repo: $first,$second"; return 0; fi
  gh api -X PUT "repos/$ORG/$repo/topics" -H "Accept: application/vnd.github+json" -f names[]="$first" -f names[]="$second" >/dev/null \
    || log_warn "could not set topics for $repo"
}

_ch44_seed_baseline_files() {
  log_step "seeding baseline policy files"
  gh_put_file "$ORG" "$R_BASE" "README.md" "Add policy baseline README" "$(_ch44_readme)"
  gh_put_file "$ORG" "$R_BASE" ".github/CODEOWNERS" "Add baseline CODEOWNERS" "$(_ch44_codeowners)"
  gh_put_file "$ORG" "$R_BASE" ".github/ISSUE_TEMPLATE/policy-exception.yml" "Add policy exception issue form" "$(_ch44_issue_form)"
  gh_put_file "$ORG" "$R_BASE" ".github/pull_request_template.md" "Add policy pull request template" "$(_ch44_pr_template)"
}

_ch44_seed_drift_files() {
  log_step "seeding intentionally drifted files"
  gh_put_file "$ORG" "$R_DRIFT" "README.md" "Add drifted service README" "$(_ch44_drift_readme)"
}

_ch44_seed_drift_issue() {
  log_step "seeding drift review issue"
  local title="Policy drift review: missing baseline controls"
  local existing
  existing="$(gh issue list --repo "$(_ch44_repo_full "$R_DRIFT")" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$title"; then log_ok "issue '$title' exists (skip)"; return 0; fi
  run_mutation gh issue create --repo "$(_ch44_repo_full "$R_DRIFT")" --title "$title" --body "Detect missing CODEOWNERS, PR template, labels, and required topics. Record remediation or exception."
}

ghec_provision() {
  gh_create_repo "$ORG" "$R_BASE" private
  gh_create_repo "$ORG" "$R_DRIFT" private
  if [[ "$DRY_RUN" != "true" ]]; then
    if gh_repo_exists "$ORG" "$R_BASE"; then
      _ch44_seed_baseline_files
      _ch44_seed_labels "$R_BASE" baseline
      _ch44_seed_topics "$R_BASE" policy-baseline owner-known
    fi
    if gh_repo_exists "$ORG" "$R_DRIFT"; then
      _ch44_seed_drift_files
      _ch44_seed_labels "$R_DRIFT" drifted
      _ch44_seed_topics "$R_DRIFT" drift-sample owner-needed
      _ch44_seed_drift_issue
    fi
  else
    log_plan "would seed baseline and intentionally drifted repository content"
  fi
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - define the policy baseline and drift severities"
  log_info "  - compare $R_DRIFT against $R_BASE"
  log_info "  - remediate safely or record approved exceptions"
}

ghec_teardown() {
  local r
  for r in "$R_BASE" "$R_DRIFT"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r issues labels
  for r in "$R_BASE" "$R_DRIFT"; do
    if gh_repo_exists "$ORG" "$r"; then
      issues="$(gh issue list --repo "$(_ch44_repo_full "$r")" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"
      labels="$(gh label list --repo "$(_ch44_repo_full "$r")" --limit 100 --json name --jq 'length' 2>/dev/null || echo '?')"
      log_ok "repo $ORG/$r present — $issues issues, $labels labels"
    else
      log_info "repo $ORG/$r absent"
    fi
  done
}
