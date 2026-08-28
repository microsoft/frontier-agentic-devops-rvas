# shellcheck shell=bash
#
# challenges/41-required-reusable-workflows/provision.sh
#
# Seeds reusable workflow library and consumer repositories. Required workflows
# or org rulesets are participant-owned governance changes, not setup mutations.

CH41_LIBRARY="ghec-${CHID}-workflow-library"
CH41_CONSUMER="ghec-${CHID}-consumer-service"

_ch41_full() { printf '%s/%s' "$ORG" "$1"; }

_ch41_library_readme() {
  cat <<'EOF_README'
# Required Workflow Library

This repository owns reusable workflows for organization baseline checks. Treat changes as platform releases: review, version, communicate, and support rollback.
EOF_README
}

_ch41_baseline_workflow() {
  cat <<'EOF_WORKFLOW'
name: Baseline required checks

on:
  workflow_call:
    inputs:
      service-name:
        required: true
        type: string

permissions:
  contents: read

jobs:
  baseline:
    runs-on: ubuntu-latest
    steps:
      - name: Validate service metadata
        run: |
          test -n "${{ inputs.service-name }}"
          echo "Baseline checks passed for ${{ inputs.service-name }}"
      - name: Check required files
        run: |
          echo "Reusable workflow library owns this check. Extend with approved organization gates."
EOF_WORKFLOW
}

_ch41_consumer_readme() {
  cat <<'EOF_README'
# Consumer Service

Use this repository to prove the reusable baseline workflow can be called and then required by an approved ruleset or required-workflow control.
EOF_README
}

_ch41_consumer_workflow() {
  cat <<EOF_WORKFLOW
name: Consumer baseline

on:
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  required-baseline:
    uses: ${ORG}/${CH41_LIBRARY}/.github/workflows/baseline.yml@main
    with:
      service-name: ${CH41_CONSUMER}
EOF_WORKFLOW
}

_ch41_governance() {
  cat <<'EOF_GOV'
# Required Reusable Workflow Governance

| Decision | Value |
|---|---|
| Library owner | TBD |
| Required check | Baseline required checks |
| Versioning model | TBD |
| Authorized repository cohort | TBD |
| Exception approver | TBD |
| Next review | TBD |

Required workflows or rulesets must be configured manually by the participant after approval.
EOF_GOV
}

_ch41_seed_library() {
  log_step "seeding reusable workflow library"
  gh_put_file "$ORG" "$CH41_LIBRARY" "README.md" "Add reusable workflow library README" "$(_ch41_library_readme)"
  gh_put_file "$ORG" "$CH41_LIBRARY" ".github/workflows/baseline.yml" "Add reusable baseline workflow" "$(_ch41_baseline_workflow)"
  gh_put_file "$ORG" "$CH41_LIBRARY" "governance/required-workflow-register.md" "Add required workflow register" "$(_ch41_governance)"
}

_ch41_seed_consumer() {
  log_step "seeding consumer repository"
  gh_put_file "$ORG" "$CH41_CONSUMER" "README.md" "Add consumer README" "$(_ch41_consumer_readme)"
  gh_put_file "$ORG" "$CH41_CONSUMER" ".github/workflows/consumer-baseline.yml" "Add consumer baseline caller" "$(_ch41_consumer_workflow)"
  gh_put_file "$ORG" "$CH41_CONSUMER" "src/service.txt" "Add sample service file" "sample service content for ghec-${CHID}"
}

_ch41_print_snapshot() {
  log_step "repository workflow and ruleset snapshot"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would list workflows and rulesets for $CH41_LIBRARY and $CH41_CONSUMER"
    return 0
  fi
  gh workflow list --repo "$(_ch41_full "$CH41_LIBRARY")" || log_warn "could not list library workflows"
  gh workflow list --repo "$(_ch41_full "$CH41_CONSUMER")" || log_warn "could not list consumer workflows"
  gh api "repos/$(_ch41_full "$CH41_CONSUMER")/rulesets" --jq '.[]? | {name, enforcement, target}' \
    || log_warn "could not read repository rulesets"
}

ghec_provision() {
  gh_create_repo "$ORG" "$CH41_LIBRARY" private
  gh_create_repo "$ORG" "$CH41_CONSUMER" private
  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$CH41_LIBRARY" || die "repo $(_ch41_full "$CH41_LIBRARY") missing after create"
    gh_repo_exists "$ORG" "$CH41_CONSUMER" || die "repo $(_ch41_full "$CH41_CONSUMER") missing after create"
  fi
  _ch41_seed_library
  _ch41_seed_consumer
  _ch41_print_snapshot
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - review and version the reusable workflow"
  log_info "  - allow approved org repositories to call workflows from $CH41_LIBRARY in Settings > Actions > General > Access"
  log_info "  - validate the consumer caller workflow"
  log_info "  - configure required workflow or ruleset manually for the approved cohort"
}

ghec_teardown() {
  local r
  for r in "$CH41_LIBRARY" "$CH41_CONSUMER"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r workflows
  for r in "$CH41_LIBRARY" "$CH41_CONSUMER"; do
    if gh_repo_exists "$ORG" "$r"; then
      workflows="$(gh workflow list --repo "$(_ch41_full "$r")" 2>/dev/null | wc -l | tr -d ' ' || echo '?')"
      log_ok "repo $(_ch41_full "$r") present — $workflows workflows"
    else
      log_info "repo $(_ch41_full "$r") not provisioned"
    fi
  done
}
