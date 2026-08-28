# shellcheck shell=bash
# challenges/38-golden-path-repo-bootstrap/provision.sh
# Seeds a template candidate and bootstrap validation repo. Organization-wide
# defaults and repository-creation controls are participant-approved steps only.

TEMPLATE_REPO="ghec-${CHID}-golden-path-template"
CANDIDATE_REPO="ghec-${CHID}-bootstrap-candidate"

_ch38_repo_full() { printf '%s/%s' "$ORG" "$1"; }

_ch38_readme() { cat <<'EOT'
# Golden-Path Repository Template

This repository is a governed starter template candidate. Replace sample owners,
controls, and escalation paths with customer-approved values before production use.

## Baseline

- README with owner and purpose
- CODEOWNERS for review ownership
- Issue form for support and exceptions
- Pull request checklist
- Workflow guidance placeholder
EOT
}

_ch38_codeowners() { cat <<'EOT'
# Replace with the approved owning team before production rollout.
* @octo-org/platform-governance
EOT
}

_ch38_issue_form() { cat <<'EOT'
name: Bootstrap exception

description: Request an exception to the golden-path repository baseline.
title: "Bootstrap exception: <repository>"
labels:
  - "bootstrap: exception"
body:
  - type: input
    id: repository
    attributes:
      label: Repository
      placeholder: ghec-ch38-example-service
    validations:
      required: true
  - type: textarea
    id: exception
    attributes:
      label: Exception requested
      description: Describe the baseline control that cannot be met and the compensating control.
    validations:
      required: true
  - type: input
    id: owner
    attributes:
      label: Approving owner
      placeholder: platform-governance
    validations:
      required: true
EOT
}

_ch38_pr_template() { cat <<'EOT'
## Repository bootstrap checklist

- [ ] Owner and purpose are documented
- [ ] CODEOWNERS has the approved owner
- [ ] Required labels/topics are present
- [ ] Secrets and Actions permissions are reviewed
- [ ] Exceptions are linked
EOT
}

_ch38_workflow() { cat <<'EOT'
name: Bootstrap guidance

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  guidance:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Replace this placeholder with approved bootstrap validation."
EOT
}

_ch38_seed_labels() {
  log_step "seeding bootstrap labels"
  local existing
  existing="$(gh label list --repo "$(_ch38_repo_full "$TEMPLATE_REPO")" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "bootstrap: exception|d73a4a|Approved or requested bootstrap exception"
    "bootstrap: ready|0e8a16|Repository baseline is ready for validation"
    "governance: review|fbca04|Governance review required"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch38_repo_full "$TEMPLATE_REPO")" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch38_seed_template_files() {
  log_step "seeding golden-path template files"
  gh_put_file "$ORG" "$TEMPLATE_REPO" "README.md" "Add golden-path template README" "$(_ch38_readme)"
  gh_put_file "$ORG" "$TEMPLATE_REPO" ".github/CODEOWNERS" "Add CODEOWNERS baseline" "$(_ch38_codeowners)"
  gh_put_file "$ORG" "$TEMPLATE_REPO" ".github/ISSUE_TEMPLATE/bootstrap-exception.yml" "Add bootstrap exception issue form" "$(_ch38_issue_form)"
  gh_put_file "$ORG" "$TEMPLATE_REPO" ".github/pull_request_template.md" "Add bootstrap pull request template" "$(_ch38_pr_template)"
  gh_put_file "$ORG" "$TEMPLATE_REPO" ".github/workflows/bootstrap-guidance.yml" "Add bootstrap workflow guidance" "$(_ch38_workflow)"
}

_ch38_seed_candidate() {
  log_step "seeding bootstrap candidate README"
  gh_put_file "$ORG" "$CANDIDATE_REPO" "README.md" "Add bootstrap candidate README" \
"# ${CANDIDATE_REPO}

Validation target for ghec-${CHID}. Use this repository to compare against the approved golden path."
}

_ch38_print_next_steps() {
  log_info "Next steps for the participant:"
  log_info "  - approve the golden-path baseline and owner"
  log_info "  - mark $TEMPLATE_REPO as a template only after approval"
  log_info "  - create or reconcile a repository from the template and record validation evidence"
}

ghec_provision() {
  gh_create_repo "$ORG" "$TEMPLATE_REPO" private
  gh_create_repo "$ORG" "$CANDIDATE_REPO" private
  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$TEMPLATE_REPO" && _ch38_seed_template_files
    gh_repo_exists "$ORG" "$CANDIDATE_REPO" && _ch38_seed_candidate
  else
    log_plan "would seed baseline files into $TEMPLATE_REPO and README into $CANDIDATE_REPO"
  fi
  _ch38_seed_labels
  echo >&2
  _ch38_print_next_steps
}

ghec_teardown() {
  local r
  for r in "$TEMPLATE_REPO" "$CANDIDATE_REPO"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  local r labels
  for r in "$TEMPLATE_REPO" "$CANDIDATE_REPO"; do
    if gh_repo_exists "$ORG" "$r"; then
      labels="$(gh label list --repo "$(_ch38_repo_full "$r")" --limit 100 --json name --jq 'length' 2>/dev/null || echo '?')"
      log_ok "repo $ORG/$r present — $labels labels"
    else
      log_info "repo $ORG/$r absent"
    fi
  done
}
