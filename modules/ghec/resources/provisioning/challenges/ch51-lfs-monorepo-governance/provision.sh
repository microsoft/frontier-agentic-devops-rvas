# shellcheck shell=bash
# challenges/ch51-lfs-monorepo-governance/provision.sh

_ch51_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch51_seed_scaffold() {
  log_step "seeding LFS and monorepo governance scaffold"
  gh_put_file "$ORG" "$REPO" "README.md" "Add monorepo governance target overview" "$(cat <<'EOF'
# ghec-ch51 — LFS and Monorepo Governance Target

Use this repository to practice monorepo ownership boundaries and Git LFS
governance. The sample uses small placeholder files only; setup does not commit
large binaries, rewrite history, or change storage quotas.
EOF
)"
  gh_put_file "$ORG" "$REPO" ".gitattributes" "Add LFS tracking policy sample" "$(cat <<'EOF'
# Approved LFS patterns. Review before production rollout.
*.psd filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
EOF
)"
  gh_put_file "$ORG" "$REPO" ".github/CODEOWNERS" "Add monorepo CODEOWNERS sample" "$(cat <<'EOF'
# Replace sample owners with customer teams before enforcement.
/packages/web/ @octo-org/web-owners
/packages/api/ @octo-org/api-owners
/packages/shared/ @octo-org/platform-owners
/docs/ @octo-org/docs-owners
.gitattributes @octo-org/platform-owners
EOF
)"
  gh_put_file "$ORG" "$REPO" "packages/web/README.md" "Add web package placeholder" "# Web package

Owner and review boundary for the web package.
"
  gh_put_file "$ORG" "$REPO" "packages/api/README.md" "Add api package placeholder" "# API package

Owner and review boundary for the API package.
"
  gh_put_file "$ORG" "$REPO" "packages/shared/README.md" "Add shared package placeholder" "# Shared package

Owner and review boundary for shared code.
"
  gh_put_file "$ORG" "$REPO" "docs/lfs-monorepo-governance.md" "Add LFS monorepo governance template" "$(cat <<'EOF'
# LFS and monorepo governance

- Monorepo governance owner:
- Storage/quota owner:
- Package owner map:
- Approved LFS patterns:
- Prohibited direct-binary patterns:
- Large-file exception path:
- Exception expiry rules:
- History rewrite or migration approver:
- Review cadence:
- High-impact decisions requiring explicit approval:
EOF
)"
  gh_put_file "$ORG" "$REPO" ".github/ISSUE_TEMPLATE/large-file-intake.yml" "Add large-file intake issue form" "$(cat <<'EOF'
name: Large-file intake
description: Request approval for a large file pattern or LFS tracking change
title: "Large-file intake: <pattern>"
labels: ["lfs: review"]
body:
  - type: input
    id: pattern
    attributes:
      label: File pattern
      placeholder: "*.onnx"
    validations:
      required: true
  - type: input
    id: size
    attributes:
      label: Expected size and growth
    validations:
      required: true
  - type: textarea
    id: usage
    attributes:
      label: Usage, retention need, and consumers
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
    validations:
      required: true
  - type: input
    id: owner
    attributes:
      label: Owning team
    validations:
      required: true
EOF
)"
}

_ch51_seed_labels() {
  log_step "seeding LFS and monorepo labels"
  local existing entry name color desc
  existing="$(gh label list --repo "$(_ch51_repo_full)" --limit 200 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "monorepo: ownership|1d76db|Ownership boundary or CODEOWNERS work"
    "lfs: review|fbca04|Large-file or LFS pattern requires review"
    "lfs: approved|0e8a16|Large-file or LFS pattern approved"
    "lfs: blocked|b60205|Large-file or LFS pattern blocked"
  )
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s
' "$existing" | grep -qxF "$name"; then log_ok "label '$name' exists (skip)"; continue; fi
    run_mutation gh label create "$name" --repo "$(_ch51_repo_full)" --color "$color" --description "$desc"
    existing="${existing}"$'
'"${name}"
  done
}

_ch51_seed_issue() {
  log_step "seeding sample large-file intake issue"
  local title="Large-file intake: sample-model-artifact" existing
  existing="$(gh issue list --repo "$(_ch51_repo_full)" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s
' "$existing" | grep -qxF "$title"; then log_ok "issue '$title' exists (skip)"; return 0; fi
  run_mutation gh issue create --repo "$(_ch51_repo_full)" --title "$title" --label "lfs: review" --body "Seeded by ghec-ch51. Replace with file pattern, expected size, update frequency, owner, alternatives, quota impact, and approval decision."
}

ghec_provision() {
  gh_create_repo "$ORG" "$REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then die "repo $(_ch51_repo_full) missing after create — aborting seed"; fi
  _ch51_seed_scaffold
  _ch51_seed_labels
  _ch51_seed_issue
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - gh repo view $(_ch51_repo_full) --json name,visibility,diskUsage,defaultBranchRef"
  log_info "  - git lfs track   # from a local clone, if git-lfs is installed"
  log_info "  - inspect repository size, LFS tracking, and ownership boundaries"
  log_info "  - replace sample CODEOWNERS entries with customer teams before enforcement"
  log_info "  - record LFS quota, migration, and history rewrite decisions explicitly"
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local issues labels size
    issues="$(gh issue list --repo "$(_ch51_repo_full)" --state all --limit 200 --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch51_repo_full)" --limit 200 --json name --jq 'length' 2>/dev/null || echo '?')"
    size="$(gh repo view "$(_ch51_repo_full)" --json diskUsage --jq '.diskUsage' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch51_repo_full) present — $issues issues, $labels labels, diskUsage=${size}KB"
  else
    log_info "repo $(_ch51_repo_full) not provisioned"
  fi
}
