# shellcheck shell=bash
# challenges/ch49-release-governance/provision.sh

_ch49_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch49_seed_scaffold() {
  log_step "seeding release governance scaffold"
  gh_put_file "$ORG" "$REPO" "README.md" "Add release governance target overview" "$(cat <<'EOF'
# ghec-ch49 — Release Governance Target

Use this repository to practice release governance without changing production
organization settings. The sample contains release notes, a readiness issue
form, and a manual evidence workflow.
EOF
)"
  gh_put_file "$ORG" "$REPO" "CHANGELOG.md" "Add sample changelog" "$(cat <<'EOF'
# Changelog

## v0.1.0 — Candidate

- Seeded release governance sample.
- Replace this section with customer-approved release notes before publishing.
EOF
)"
  gh_put_file "$ORG" "$REPO" "docs/release-governance.md" "Add release governance policy template" "$(cat <<'EOF'
# Release governance policy

- Release owner:
- Approver group:
- Tag naming pattern:
- Required release note sections:
- Validation evidence required:
- Rollback owner:
- Exception path:
- Review cadence:
- High-impact controls requiring explicit approval:
EOF
)"
  gh_put_file "$ORG" "$REPO" ".github/ISSUE_TEMPLATE/release-readiness.yml" "Add release readiness issue form" "$(cat <<'EOF'
name: Release readiness
about: Capture approval and evidence for a release candidate
title: "Release candidate: <tag>"
labels: ["release: candidate"]
body:
  - type: input
    id: tag
    attributes:
      label: Release tag
      placeholder: v0.1.0
    validations:
      required: true
  - type: textarea
    id: scope
    attributes:
      label: Scope and change summary
    validations:
      required: true
  - type: textarea
    id: validation
    attributes:
      label: Validation evidence
      description: Link workflow runs, test reports, or approval records.
    validations:
      required: true
  - type: input
    id: approver
    attributes:
      label: Approver
    validations:
      required: true
  - type: textarea
    id: rollback
    attributes:
      label: Rollback plan and owner
    validations:
      required: true
EOF
)"
  gh_put_file "$ORG" "$REPO" ".github/workflows/release-evidence.yml" "Add release evidence workflow scaffold" "$(cat <<'EOF'
name: Release evidence

on:
  workflow_dispatch:
    inputs:
      release_tag:
        description: Release tag under review
        required: true
      evidence_url:
        description: Evidence URL or record identifier
        required: true

permissions:
  contents: read

jobs:
  record:
    runs-on: ubuntu-latest
    steps:
      - name: Print evidence summary
        run: |
          echo "Release tag: ${{ inputs.release_tag }}"
          echo "Evidence: ${{ inputs.evidence_url }}"
EOF
)"
}

_ch49_seed_labels() {
  log_step "seeding release labels"
  local existing entry name color desc
  existing="$(gh label list --repo "$(_ch49_repo_full)" --limit 200 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "release: candidate|1d76db|Release candidate awaiting evidence and approval"
    "release: approved|0e8a16|Release approved for publication"
    "release: blocked|b60205|Release blocked pending remediation"
    "release: rollback-ready|fbca04|Rollback plan and owner confirmed"
  )
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s
' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch49_repo_full)" --color "$color" --description "$desc"
    existing="${existing}"$'
'"${name}"
  done
}

_ch49_seed_issue() {
  log_step "seeding sample release candidate issue"
  local title="Release candidate: v0.1.0" existing
  existing="$(gh issue list --repo "$(_ch49_repo_full)" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s
' "$existing" | grep -qxF "$title"; then log_ok "issue '$title' exists (skip)"; return 0; fi
  run_mutation gh issue create --repo "$(_ch49_repo_full)" --title "$title" --label "release: candidate" --body "Seeded by ghec-ch49. Replace this with customer release scope, validation evidence, approver, and rollback owner."
}

ghec_provision() {
  gh_create_repo "$ORG" "$REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then die "repo $(_ch49_repo_full) missing after create — aborting seed"; fi
  _ch49_seed_scaffold
  _ch49_seed_labels
  _ch49_seed_issue
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - gh release list --repo $(_ch49_repo_full) --limit 20"
  log_info "  - gh api repos/$(_ch49_repo_full)/rulesets --jq '.[]? | {name,target,enforcement}'"
  log_info "  - gh api repos/$(_ch49_repo_full)/environments --jq '.environments[]? | {name,protection_rules}'"
  log_info "  - inspect release, ruleset, and environment settings before changing anything"
  log_info "  - complete docs/release-governance.md with owners and approval boundaries"
  log_info "  - use the release candidate issue to capture approval evidence"
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local issues labels releases
    issues="$(gh issue list --repo "$(_ch49_repo_full)" --state all --limit 200 --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch49_repo_full)" --limit 200 --json name --jq 'length' 2>/dev/null || echo '?')"
    releases="$(gh release list --repo "$(_ch49_repo_full)" --limit 100 --json tagName --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch49_repo_full) present — $issues issues, $labels labels, $releases releases"
  else
    log_info "repo $(_ch49_repo_full) not provisioned"
  fi
}
