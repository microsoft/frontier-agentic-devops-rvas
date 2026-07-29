# shellcheck shell=bash
# challenges/ch48-vendor-access-lifecycle/provision.sh
#
# Seeds a vendor access register. Setup never invites or removes collaborators
# and never changes organization-wide collaborator settings.

REGISTER_REPO="ghec-${CHID}-vendor-access-register"

_ch48_repo_full() { printf '%s/%s' "$ORG" "$REGISTER_REPO"; }

_ch48_readme() {
  cat <<'EOT'
# Vendor Access Register

Use this repository to track approved vendor and outside-collaborator access lifecycle evidence.

Required fields for each access record:

- vendor or partner name
- business sponsor
- repository scope
- requested permission
- start and end dates
- reviewer and review cadence
- offboarding trigger and evidence

Setup does not invite users, remove users, or change organization settings.
EOT
}

_ch48_access_form() {
  cat <<'EOT'
name: Vendor access request
description: Request scoped, time-bound outside collaborator access.
title: "Vendor access request: <vendor>"
labels:
  - "vendor-access: requested"
body:
  - type: input
    id: vendor
    attributes:
      label: Vendor or partner
    validations:
      required: true
  - type: input
    id: business_sponsor
    attributes:
      label: Business sponsor
    validations:
      required: true
  - type: textarea
    id: repository_scope
    attributes:
      label: Repository scope
      description: List repositories and why access is needed.
    validations:
      required: true
  - type: dropdown
    id: permission
    attributes:
      label: Requested permission
      options:
        - read
        - triage
        - write
    validations:
      required: true
  - type: input
    id: end_date
    attributes:
      label: Access end date
      placeholder: YYYY-MM-DD
    validations:
      required: true
  - type: textarea
    id: offboarding
    attributes:
      label: Offboarding trigger and evidence plan
    validations:
      required: true
EOT
}

_ch48_review_form() {
  cat <<'EOT'
name: Vendor access review
description: Review active vendor access or record offboarding evidence.
title: "Vendor access review: <vendor or cohort>"
labels:
  - "vendor-access: review-due"
body:
  - type: textarea
    id: active_access
    attributes:
      label: Active access reviewed
    validations:
      required: true
  - type: textarea
    id: decision
    attributes:
      label: Review decision
      description: Continue, reduce, remove, or exception with owner/date.
    validations:
      required: true
  - type: textarea
    id: audit_evidence
    attributes:
      label: Audit evidence
      description: Link audit-log query, invitation, permission change, or removal evidence.
    validations:
      required: true
EOT
}

_ch48_seed_files() {
  log_step "seeding vendor access register files"
  gh_put_file "$ORG" "$REGISTER_REPO" "README.md" "Add vendor access register README" "$(_ch48_readme)"
  gh_put_file "$ORG" "$REGISTER_REPO" ".github/ISSUE_TEMPLATE/vendor-access-request.yml" "Add vendor access request form" "$(_ch48_access_form)"
  gh_put_file "$ORG" "$REGISTER_REPO" ".github/ISSUE_TEMPLATE/vendor-access-review.yml" "Add vendor access review form" "$(_ch48_review_form)"
}

_ch48_seed_labels() {
  log_step "seeding vendor access labels"
  local existing
  existing="$(gh label list --repo "$(_ch48_repo_full)" --limit 100 --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "vendor-access: requested|fbca04|Access request awaiting review"
    "vendor-access: approved|0e8a16|Approved for explicit participant grant"
    "vendor-access: active|1d76db|Access is active and tracked"
    "vendor-access: review-due|d93f0b|Periodic access review is due"
    "vendor-access: offboarded|5319e7|Access removed or verified absent"
    "vendor-access: exception|d73a4a|Exception or risk acceptance required"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch48_repo_full)" --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch48_seed_issue() {
  log_step "seeding sample vendor access request"
  local title="Vendor access request: sample-docs-vendor"
  local existing
  existing="$(gh issue list --repo "$(_ch48_repo_full)" --state all --limit 100 --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$title"; then
    log_ok "sample vendor request exists (skip)"
    return 0
  fi
  run_mutation gh issue create --repo "$(_ch48_repo_full)" \
    --title "$title" \
    --label "vendor-access: requested" \
    --body "$(cat <<'EOT'
### Vendor or partner
sample-docs-vendor

### Business sponsor
platform-governance

### Repository scope
ghec-ch48-vendor-access-register for sample documentation review only.

### Requested permission
read

### Access end date
YYYY-MM-DD

### Offboarding trigger and evidence plan
Remove repository collaborator access at end date and link audit-log evidence.

This is a sample request. Do not invite any user unless explicitly approved during the activity.
EOT
)"
}

_ch48_print_access_snapshots() {
  log_step "outside-collaborator snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api /orgs/$ORG/outside_collaborators and /orgs/$ORG/invitations"
    return 0
  fi
  gh api "/orgs/$ORG/outside_collaborators" --paginate \
    --jq '[.[] | {login, type}]' 2>/dev/null || log_warn "could not read outside collaborators"
  log_step "pending organization invitation snapshot for '$ORG'"
  gh api "/orgs/$ORG/invitations" --paginate \
    --jq '[.[] | {login: .login, role: .role}]' 2>/dev/null || log_warn "could not read pending invitations"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$REGISTER_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REGISTER_REPO"; then
    die "repo $(_ch48_repo_full) missing after create — aborting seed"
  fi
  _ch48_seed_files
  _ch48_seed_labels
  _ch48_seed_issue
  _ch48_print_access_snapshots
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - inventory outside collaborators and pending invitations"
  log_info "  - complete the access register and approval path"
  log_info "  - grant or remove access only as explicit approved participant steps"
}

ghec_teardown() {
  guard_prefix "$REGISTER_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REGISTER_REPO"
  log_warn "teardown only deletes the register repo; it never changes collaborator access"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REGISTER_REPO"; then
    local issues labels
    issues="$(gh issue list --repo "$(_ch48_repo_full)" --state all --limit 100 --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch48_repo_full)" --limit 100 --json name --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch48_repo_full) present — $issues issues, $labels labels"
  else
    log_info "repo $(_ch48_repo_full) not provisioned"
  fi
}
