# shellcheck shell=bash
#
# challenges/ch16-rest-graphql-automation/provision.sh
#
# ch16 seeds a plain automation target — a repo with a small src/ + docs/
# layout, a starter (intentionally incomplete) label set, ~60 loop-generated
# issues in a mix of open/closed and mostly UNLABELED states, and an EMPTY
# org-level Project (v2) board. The volume is what makes REST + GraphQL
# automation worth practising.

PROJECT_TITLE="ghec-${CHID}-board"

_ch16_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch16_seed_scaffold() {
  log_step "seeding src/ + docs/ scaffold"
  gh_put_file "$ORG" "$REPO" "README.md" \
    "Add automation target overview" \
"$(cat <<EOF
# ghec-ch16 — REST & GraphQL Automation Target

A deliberately large, messy backlog to automate against. Use the REST and
GraphQL APIs to triage, label, and organise the issues in this repo.

- \`src/\` — placeholder service code
- \`docs/\` — placeholder docs
- ~60 seeded issues (mixed open/closed, mostly unlabeled)
- empty board: \`$PROJECT_TITLE\`
EOF
)"
  gh_put_file "$ORG" "$REPO" "src/app.js" \
    "Add placeholder service entrypoint" \
"$(cat <<'EOF'
// ghec-ch16 placeholder service — the code is not the point; the backlog is.
module.exports = function app () {
  return { status: 'ok' }
}
EOF
)"
  gh_put_file "$ORG" "$REPO" "docs/API.md" \
    "Add placeholder API docs" \
"$(cat <<'EOF'
# API (placeholder)

Document the endpoints here as part of the automation exercise.
EOF
)"
}

_ch16_seed_labels() {
  log_step "seeding starter labels (intentionally incomplete)"
  local existing
  existing="$(gh label list --repo "$(_ch16_repo_full)" --limit 200 \
    --json name --jq '.[].name' 2>/dev/null || true)"
  # name|hex|desc — gaps by design: no priority scale, no good-first-issue.
  local labels=(
    "bug|d73a4a|Something is broken"
    "enhancement|a2eeef|New feature or request"
    "triage|fbca04|Needs triage"
    "area:backend|0e8a16|Backend work"
    "area:docs|0052cc|Documentation work"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch16_repo_full)" \
      --color "$color" --description "$desc"
  done
  log_info "GAP by design: no priority scale, no 'good first issue' — automation fills these."
}

_ch16_seed_issues() {
  log_step "seeding ~60 issues (mixed open/closed, mostly unlabeled)"
  local existing
  existing="$(gh issue list --repo "$(_ch16_repo_full)" --state all --limit 500 \
    --json title --jq '.[].title' 2>/dev/null || true)"

  local topics=(
    "login flow" "search endpoint" "rate limiting" "pagination" "webhook retries"
    "CSV export" "audit logging" "cache invalidation" "error messages" "timezone handling"
  )
  local i n topic title label state url
  for i in $(seq 1 60); do
    printf -v n '%03d' "$i"
    topic="${topics[$(( (i - 1) % ${#topics[@]} ))]}"
    title="Backlog $n: review $topic"

    # ~1 in 4 gets a label; the rest are intentionally unlabeled.
    label=""
    case $(( i % 4 )) in
      0) label="bug" ;;
      1) label="" ;;
      2) label="enhancement" ;;
      3) label="" ;;
    esac
    # ~1 in 3 starts closed -> a realistic mixed-state backlog.
    state="open"; [[ $(( i % 3 )) -eq 0 ]] && state="closed"

    if printf '%s\n' "$existing" | grep -qxF "$title"; then
      log_ok "issue '$title' exists (skip)"
      continue
    fi

    local args=(gh issue create --repo "$(_ch16_repo_full)" --title "$title"
      --body "Seeded by ghec-ch16 — messy backlog at scale. Triage, label, and organise via REST/GraphQL.")
    [[ -n "$label" ]] && args+=(--label "$label")
    url="$(run_mutation "${args[@]}")"
    if [[ "$state" == "closed" && -n "${url:-}" ]]; then
      run_mutation gh issue close "$url"
    fi
  done
}

_ch16_project_number() {
  { gh project list --owner "$ORG" --format json --limit 100 2>/dev/null \
    | jq -r --arg t "$PROJECT_TITLE" '.projects[]? | select(.title==$t) | .number' \
    | head -n1; } || true
}

_ch16_seed_project() {
  log_step "seeding empty Project (v2): $PROJECT_TITLE"
  local num
  num="$(_ch16_project_number)"
  if [[ -n "${num:-}" ]]; then
    log_ok "project '$PROJECT_TITLE' exists (#$num, skip)"
    return 0
  fi
  run_mutation gh project create --owner "$ORG" --title "$PROJECT_TITLE"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch16_repo_full) missing after create — aborting seed"
  fi
  _ch16_seed_scaffold
  _ch16_seed_labels
  _ch16_seed_issues
  _ch16_seed_project
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - script bulk triage/labeling over the backlog with REST + GraphQL"
  log_info "  - add issues to the '$PROJECT_TITLE' board programmatically"
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"

  local num
  num="$(_ch16_project_number)"
  if [[ -n "${num:-}" ]]; then
    guard_prefix "$PROJECT_TITLE" "$CHID" || return 1
    run_mutation gh project delete "$num" --owner "$ORG"
  else
    log_ok "project '$PROJECT_TITLE' absent (skip)"
  fi
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local issues labels
    issues="$(gh issue list --repo "$(_ch16_repo_full)" --state all --limit 500 \
      --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch16_repo_full)" --limit 200 \
      --json name --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch16_repo_full) present — $issues issues, $labels labels"
  else
    log_info "repo $(_ch16_repo_full) not provisioned"
  fi
}
