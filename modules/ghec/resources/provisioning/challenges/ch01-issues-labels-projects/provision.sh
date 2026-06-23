# shellcheck shell=bash
#
# challenges/ch01-issues-labels-projects/provision.sh
#
# REFERENCE per-challenge provisioner. Sourced by scripts/setup.sh, which
# exports: ORG CHID SLUG APP JUICE_SHOP_REF DRY_RUN ASSUME_YES NAMESPACE REPO META
# and provides the lib helpers: log_*, run_mutation, gh_*, guard_prefix, meta_*.
#
# CONTRACT — every challenge's provision.sh MUST define exactly these three
# functions (generic names; setup.sh calls them):
#     wth_provision   create-if-absent, idempotent, dry-run aware
#     wth_teardown    delete ONLY wth-<chid>-* (prefix-guarded)
#     wth_status      report what currently exists
#
# ch01 builds: a public repo seeded with a deliberately MESSY backlog
# (~26 issues, many unlabeled / inconsistently labeled), a label taxonomy with
# obvious GAPS, milestones, and an EMPTY org-level Project (v2) board — the
# raw material a participant cleans up to learn issues/labels/projects.

PROJECT_TITLE="wth-${CHID}-board"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

_ch01_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

# ---------------------------------------------------------------------------
# labels — intentionally incomplete taxonomy (the "gap" the student fixes)
# ---------------------------------------------------------------------------
_ch01_seed_labels() {
  log_step "seeding label taxonomy (intentionally incomplete)"
  local existing
  existing="$(gh label list --repo "$(_ch01_repo_full)" --limit 200 \
    --json name --jq '.[].name' 2>/dev/null || true)"

  # name|hexcolor|description   (dup casing + dup colour are deliberate mess)
  local labels=(
    "bug|d73a4a|Something is broken"
    "Bug|b60205|duplicate casing of 'bug' — intentional mess"
    "enhancement|a2eeef|New feature or request"
    "urgent|e11d21|Drop everything"
    "wontfix|ffffff|This will not be worked on"
    "question|d876e3|Needs clarification"
    "backend|0e8a16|Server-side work"
    "frontend|0e8a16|duplicate colour of 'backend' — intentional mess"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch01_repo_full)" \
      --color "$color" --description "$desc"
  done
  log_info "GAP by design: no priority scale, no 'triage', no 'good first issue', dup 'bug/Bug'."
}

# ---------------------------------------------------------------------------
# milestones
# ---------------------------------------------------------------------------
_ch01_seed_milestones() {
  log_step "seeding milestones"
  local existing
  existing="$(gh api "repos/$(_ch01_repo_full)/milestones?state=all" \
    --jq '.[].title' 2>/dev/null || true)"

  local titles=("Sprint 1" "Sprint 2" "Backlog Grooming")
  local t
  for t in "${titles[@]}"; do
    if printf '%s\n' "$existing" | grep -qxF "$t"; then
      log_ok "milestone '$t' exists (skip)"
      continue
    fi
    run_mutation gh api -X POST "repos/$(_ch01_repo_full)/milestones" \
      -f title="$t" -f state=open \
      -f description="Seeded by wth-ch01 — re-assign issues as part of triage."
  done
}

# ---------------------------------------------------------------------------
# issues — deliberately messy backlog
# ---------------------------------------------------------------------------
_ch01_seed_issues() {
  log_step "seeding messy issue backlog"
  local existing
  existing="$(gh issue list --repo "$(_ch01_repo_full)" --state all --limit 300 \
    --json title --jq '.[].title' 2>/dev/null || true)"

  # "title::labels"  (labels comma-separated; empty = intentionally unlabeled)
  local issues=(
    "Login button does nothing on Safari::bug"
    "app slow sometimes::"
    "Crash when uploading an avatar over 5MB::bug"
    "Add dark mode::enhancement"
    "URGENT: checkout page returns 500::urgent"
    "typo on about page::"
    "Make the logo bigger::enhancement"
    "Users report being logged out randomly::"
    "password reset email never arrives::bug"
    "Support German language::enhancement"
    "search returns no results for valid queries::bug"
    "improve performance of dashboard::"
    "Broken link in footer::"
    "Add export to CSV::enhancement"
    "API rate limit errors under load::"
    "Mobile layout overlaps on iPhone SE::bug"
    "Question: how do I rotate API keys?::question"
    "We should refactor the auth module::"
    "Cookie banner not GDPR compliant::urgent"
    "Add two-factor authentication::enhancement"
    "Flaky test in CI::"
    "Update dependencies::"
    "Profile picture not saving::bug"
    "wontfix: legacy IE11 support::wontfix"
    "Onboarding flow confusing for new users::"
    "Add webhook support::enhancement"
  )

  local entry title labels
  for entry in "${issues[@]}"; do
    title="${entry%%::*}"
    labels="${entry#*::}"
    [[ "$labels" == "$entry" ]] && labels=""   # guard: no '::' present

    if printf '%s\n' "$existing" | grep -qxF "$title"; then
      log_ok "issue '$title' exists (skip)"
      continue
    fi

    local args=(gh issue create --repo "$(_ch01_repo_full)" \
      --title "$title" \
      --body "Seeded by wth-ch01. This backlog is intentionally messy — triage, label, milestone, and add it to the board.")
    if [[ -n "$labels" ]]; then
      local l
      IFS=',' read -ra _ls <<< "$labels"
      for l in "${_ls[@]}"; do args+=(--label "$l"); done
    fi
    run_mutation "${args[@]}"
  done
}

# ---------------------------------------------------------------------------
# project (v2) — empty org-level board
# ---------------------------------------------------------------------------
_ch01_project_number() {
  { gh project list --owner "$ORG" --format json --limit 100 2>/dev/null \
    | jq -r --arg t "$PROJECT_TITLE" '.projects[]? | select(.title==$t) | .number' \
    | head -n1; } || true
}

_ch01_seed_project() {
  log_step "seeding empty Project (v2): $PROJECT_TITLE"
  local num
  num="$(_ch01_project_number)"
  if [[ -n "${num:-}" ]]; then
    log_ok "project '$PROJECT_TITLE' exists (#$num, skip)"
    return 0
  fi
  run_mutation gh project create --owner "$ORG" --title "$PROJECT_TITLE"
}

# ===========================================================================
# CONTRACT FUNCTIONS
# ===========================================================================

wth_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch01_repo_full) missing after create — aborting seed"
  fi
  _ch01_seed_labels
  _ch01_seed_milestones
  _ch01_seed_issues
  _ch01_seed_project
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - clean up the label taxonomy (priorities, triage, dedupe bug/Bug)"
  log_info "  - triage & label the backlog, assign milestones"
  log_info "  - add issues to the '$PROJECT_TITLE' board and build views"
}

wth_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"

  local num
  num="$(_ch01_project_number)"
  if [[ -n "${num:-}" ]]; then
    guard_prefix "$PROJECT_TITLE" "$CHID" || return 1
    run_mutation gh project delete "$num" --owner "$ORG"
  else
    log_ok "project '$PROJECT_TITLE' absent (skip)"
  fi
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local issues labels
    issues="$(gh issue list --repo "$(_ch01_repo_full)" --state all --limit 500 \
      --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch01_repo_full)" --limit 200 \
      --json name --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch01_repo_full) present — $issues issues, $labels labels"
  else
    log_info "repo $(_ch01_repo_full) not provisioned"
  fi

  local num
  num="$(_ch01_project_number)"
  if [[ -n "${num:-}" ]]; then
    log_ok "project '$PROJECT_TITLE' present (#$num)"
  else
    log_info "project '$PROJECT_TITLE' not provisioned"
  fi
}
