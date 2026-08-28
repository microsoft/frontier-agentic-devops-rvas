# shellcheck shell=bash
# challenges/ch46-pages-publishing-governance/provision.sh
#
# Seeds a Pages candidate repo with static content and a governance issue.
# Organization Pages publication settings are participant-controlled governance
# changes, not setup mutations.

PAGES_REPO="ghec-${CHID}-pages-site"

_ch46_repo_full() { printf '%s/%s' "$ORG" "$PAGES_REPO"; }

_ch46_readme() {
  cat <<'EOT'
# Pages Publishing Governance Sample

This repository is a safe sample for the ghec-ch46 Pages publishing governance activity.

Use `docs/` as the candidate Pages source after the organization publishing policy is approved.
Setup does not enable Pages or mutate organization-wide Pages settings.
EOT
}

_ch46_index() {
  cat <<'EOT'
# Governed Pages Site

This sample page exists so participants can configure a repository-level GitHub Pages source after approval.

Evidence to capture:

- organization Pages publication policy decision
- repository Pages source or workflow run
- published URL and visibility
- rollback owner and next review
EOT
}

_ch46_seed_files() {
  log_step "seeding Pages candidate content"
  gh_put_file "$ORG" "$PAGES_REPO" "README.md" "Add Pages governance sample README" "$(_ch46_readme)"
  gh_put_file "$ORG" "$PAGES_REPO" "docs/index.md" "Add Pages sample content" "$(_ch46_index)"
}

_ch46_seed_labels() {
  log_step "seeding Pages governance labels"
  local existing
  existing="$(gh label list --repo "$(_ch46_repo_full)" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "pages-governance: decision-needed|fbca04|Org Pages policy decision is needed"
    "pages-governance: approved|0e8a16|Publishing decision approved"
    "pages-governance: exception|d93f0b|Approved exception or risk acceptance"
    "pages-governance: rollback-ready|0052cc|Rollback owner and path recorded"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch46_repo_full)" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch46_seed_issue() {
  log_step "seeding Pages governance decision issue"
  local title="Pages publication governance decision"
  local existing
  existing="$(gh issue list --repo "$(_ch46_repo_full)" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$title"; then
    log_ok "governance decision issue exists (skip)"
    return 0
  fi
  run_mutation gh issue create --repo "$(_ch46_repo_full)" \
    --title "$title" \
    --label "pages-governance: decision-needed" \
    --body "$(cat <<'EOT'
Record the approved Pages publishing decision before enabling the site.

Required evidence:
- organization Pages policy snapshot
- approved publisher scope and visibility
- repository source or workflow choice
- site owner and content owner
- rollback owner and review cadence

Setup intentionally did not enable Pages or change org-wide Pages settings.
EOT
)"
}

_ch46_print_pages_policy() {
  log_step "organization Pages policy snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api /orgs/$ORG Pages settings"
    return 0
  fi
  gh api "/orgs/$ORG" \
    --jq '{members_can_create_pages, members_can_create_public_pages, members_can_create_private_pages}' \
    2>/dev/null || log_warn "could not read org Pages settings; capture them from Organization settings > Pages"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$PAGES_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$PAGES_REPO"; then
    die "repo $(_ch46_repo_full) missing after create — aborting seed"
  fi
  _ch46_seed_files
  _ch46_seed_labels
  _ch46_seed_issue
  _ch46_print_pages_policy
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - approve the organization Pages publishing policy"
  log_info "  - configure repository-level Pages for $PAGES_REPO only after approval"
  log_info "  - capture site URL, source/workflow evidence, rollback owner, and next review"
}

ghec_teardown() {
  guard_prefix "$PAGES_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$PAGES_REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$PAGES_REPO"; then
    local issues pages_state
    issues="$(gh issue list --repo "$(_ch46_repo_full)" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"
    pages_state="$(gh api "repos/$(_ch46_repo_full)/pages" --jq '.status // .html_url // "configured"' 2>/dev/null || echo 'not configured')"
    log_ok "repo $(_ch46_repo_full) present — $issues issues, Pages: $pages_state"
  else
    log_info "repo $(_ch46_repo_full) not provisioned"
  fi
}
