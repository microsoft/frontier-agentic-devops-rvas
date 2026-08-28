# shellcheck shell=bash
# challenges/47-innersource-program-operations/provision.sh
#
# Seeds an InnerSource hub repository with discoverability files, labels, and
# program-operation issues. Setup does not mutate access or branch protection.

HUB_REPO="ghec-${CHID}-innersource-hub"

_ch47_repo_full() { printf '%s/%s' "$ORG" "$HUB_REPO"; }

_ch47_readme() {
  cat <<'EOT'
# InnerSource Hub

This sample hub is the operating surface for the ghec-ch47 InnerSource program activity.

Use it to record:

- program charter and owner
- participating repositories
- contribution-ready work
- maintainer response expectations
- adoption metrics and review cadence
EOT
}

_ch47_contributing() {
  cat <<'EOT'
# Contributing

Thank you for contributing through the InnerSource program.

1. Pick an issue labeled `innersource: good-first-contribution` or `innersource: mentored`.
2. Comment with your intent and wait for maintainer confirmation when the issue requests it.
3. Open a pull request with tests or documentation evidence.
4. Maintainers target an initial response within the program SLA recorded in the charter.

Do not bypass repository branch protection, CODEOWNERS review, or data classification requirements.
EOT
}

_ch47_codeowners() {
  cat <<'EOT'
# Replace this sample owner with the approved maintainer team during the activity.
* @octocat
EOT
}

_ch47_support() {
  cat <<'EOT'
# Support Path

Record the approved support route here:

- program owner:
- maintainer escalation:
- response SLA:
- office hours or channel:
- next review date:
EOT
}

_ch47_seed_files() {
  log_step "seeding InnerSource hub files"
  gh_put_file "$ORG" "$HUB_REPO" "README.md" "Add InnerSource hub README" "$(_ch47_readme)"
  gh_put_file "$ORG" "$HUB_REPO" "CONTRIBUTING.md" "Add InnerSource contribution guide" "$(_ch47_contributing)"
  gh_put_file "$ORG" "$HUB_REPO" ".github/CODEOWNERS" "Add sample CODEOWNERS" "$(_ch47_codeowners)"
  gh_put_file "$ORG" "$HUB_REPO" "SUPPORT.md" "Add InnerSource support path" "$(_ch47_support)"
}

_ch47_seed_labels() {
  log_step "seeding InnerSource labels"
  local existing
  existing="$(gh label list --repo "$(_ch47_repo_full)" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "innersource: good-first-contribution|0e8a16|Ready for a first-time internal contributor"
    "innersource: mentored|1d76db|Maintainer has agreed to mentor this work"
    "innersource: maintainer-needed|fbca04|Needs maintainer routing or ownership"
    "innersource: blocked|d73a4a|Blocked by access, design, or ownership decision"
    "innersource: metrics|5319e7|Program metric or operating review item"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch47_repo_full)" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch47_seed_issues() {
  log_step "seeding InnerSource program issues"
  local existing
  existing="$(gh issue list --repo "$(_ch47_repo_full)" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  local issues=(
    "Draft InnerSource program charter::innersource: maintainer-needed::Define scope, owner, metrics, participating repositories, cadence, and exception process."
    "Prepare first contribution-ready issue::innersource: good-first-contribution::Write acceptance criteria, owner, test guidance, and review route for a small pilot contribution."
    "Set maintainer response SLA and office hours::innersource: mentored::Record response SLA, support channel, and maintainer rotation."
    "Create adoption metrics baseline::innersource: metrics::Record ready issues, pilot repositories, response times, and merged cross-team pull requests."
  )
  local entry title rest label body
  for entry in "${issues[@]}"; do
    title="${entry%%::*}"
    rest="${entry#*::}"
    label="${rest%%::*}"
    body="${rest#*::}"
    if printf '%s\n' "$existing" | grep -qxF "$title"; then
      log_ok "issue '$title' exists (skip)"
      continue
    fi
    run_mutation gh issue create --repo "$(_ch47_repo_full)" --title "$title" --label "$label" --body "$body"
  done
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$HUB_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$HUB_REPO"; then
    die "repo $(_ch47_repo_full) missing after create — aborting seed"
  fi
  _ch47_seed_files
  _ch47_seed_labels
  _ch47_seed_issues
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - replace sample CODEOWNERS with approved maintainer owners"
  log_info "  - complete the program charter and contribution-ready backlog"
  log_info "  - record metrics, owner, exception path, and next review"
}

ghec_teardown() {
  guard_prefix "$HUB_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$HUB_REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$HUB_REPO"; then
    local issues labels
    issues="$(gh issue list --repo "$(_ch47_repo_full)" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch47_repo_full)" --limit 100 --json name --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch47_repo_full) present — $issues issues, $labels labels"
  else
    log_info "repo $(_ch47_repo_full) not provisioned"
  fi
}
