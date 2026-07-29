# shellcheck shell=bash
# challenges/ch50-license-compliance-workflow/provision.sh

_ch50_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch50_seed_scaffold() {
  log_step "seeding license compliance scaffold"
  gh_put_file "$ORG" "$REPO" "README.md" "Add license compliance target overview" "$(cat <<'EOF'
# ghec-ch50 — License Compliance Workflow Target

Use this repository to practice dependency inventory, dependency review, and
license exception intake. Setup seeds manifests and workflow materials only; it
does not change enterprise or organization license policies.
EOF
)"
  gh_put_file "$ORG" "$REPO" "package.json" "Add sample npm manifest" "$(cat <<'EOF'
{
  "name": "ghec-ch50-license-compliance-workflow",
  "version": "0.1.0",
  "private": true,
  "license": "MIT",
  "dependencies": {
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.7.0"
  }
}
EOF
)"
  gh_put_file "$ORG" "$REPO" "requirements.txt" "Add sample Python manifest" "$(cat <<'EOF'
requests==2.32.3
PyYAML==6.0.2
EOF
)"
  gh_put_file "$ORG" "$REPO" "docs/license-compliance-policy.md" "Add license compliance policy template" "$(cat <<'EOF'
# License compliance policy

- Compliance owner:
- Legal/security approver:
- Allowed license families:
- Review-required license families:
- Prohibited license families:
- Exception path:
- Exception expiry rules:
- Remediation owner:
- Review cadence:
- High-impact policies requiring explicit approval:
EOF
)"
  gh_put_file "$ORG" "$REPO" ".github/dependabot.yml" "Add Dependabot scaffold" "$(cat <<'EOF'
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
EOF
)"
  gh_put_file "$ORG" "$REPO" ".github/ISSUE_TEMPLATE/license-exception.yml" "Add license exception issue form" "$(cat <<'EOF'
name: License exception
description: Request a time-bound exception for a dependency license
title: "License exception: <package>"
labels: ["license: review"]
body:
  - type: input
    id: package
    attributes:
      label: Package and version
    validations:
      required: true
  - type: input
    id: license
    attributes:
      label: Detected license
    validations:
      required: true
  - type: textarea
    id: usage
    attributes:
      label: Usage and distribution context
    validations:
      required: true
  - type: input
    id: owner
    attributes:
      label: Business owner
    validations:
      required: true
  - type: input
    id: expiry
    attributes:
      label: Exception expiry date
    validations:
      required: true
  - type: textarea
    id: remediation
    attributes:
      label: Remediation or replacement plan
    validations:
      required: true
EOF
)"
}

_ch50_seed_labels() {
  log_step "seeding license labels"
  local existing entry name color desc
  existing="$(gh label list --repo "$(_ch50_repo_full)" --limit 200 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "license: review|fbca04|Dependency license requires review"
    "license: approved|0e8a16|License use approved"
    "license: exception|1d76db|Time-bound license exception approved"
    "license: blocked|b60205|Dependency license is blocked"
  )
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s
' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch50_repo_full)" --color "$color" --description "$desc"
    existing="${existing}"$'
'"${name}"
  done
}

_ch50_seed_issue() {
  log_step "seeding sample license exception issue"
  local title="License exception: sample-transitive-package" existing
  existing="$(gh issue list --repo "$(_ch50_repo_full)" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s
' "$existing" | grep -qxF "$title"; then log_ok "issue '$title' exists (skip)"; return 0; fi
  run_mutation gh issue create --repo "$(_ch50_repo_full)" --title "$title" --label "license: review" --body "Seeded by ghec-ch50. Replace with package, license, usage, owner, legal/security decision, expiry, and remediation path."
}

ghec_provision() {
  gh_create_repo "$ORG" "$REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then die "repo $(_ch50_repo_full) missing after create — aborting seed"; fi
  _ch50_seed_scaffold
  _ch50_seed_labels
  _ch50_seed_issue
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - gh api repos/$(_ch50_repo_full)/dependency-graph/sbom --jq '.sbom.packages[]? | {name,versionInfo,licenseConcluded}'"
  log_info "  - gh api repos/$(_ch50_repo_full)/contents/package.json --jq '.download_url'"
  log_info "  - capture dependency inventory from dependency graph, manifests, or SBOM"
  log_info "  - classify allowed, review-required, and prohibited license families"
  log_info "  - record policy enforcement changes as explicit owner-approved steps"
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local issues labels
    issues="$(gh issue list --repo "$(_ch50_repo_full)" --state all --limit 200 --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch50_repo_full)" --limit 200 --json name --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch50_repo_full) present — $issues issues, $labels labels"
  else
    log_info "repo $(_ch50_repo_full) not provisioned"
  fi
}
