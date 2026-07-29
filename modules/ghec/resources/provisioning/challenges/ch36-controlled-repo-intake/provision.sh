# shellcheck shell=bash
#
# challenges/ch36-controlled-repo-intake/provision.sh
#
# Seeds a repository-intake repo with an issue form, labels, and a workflow
# scaffold. The workflow requires a participant-provided secret; setup never
# creates or stores credentials.

INTAKE_REPO="ghec-${CHID}-repo-intake"

_ch36_repo_full() { printf '%s/%s' "$ORG" "$INTAKE_REPO"; }

_ch36_readme() {
  cat <<'EOF'
# Repository Intake

Use this repository to request and approve new repositories through a governed issue-form workflow.

## Flow

1. A requester opens a repository request issue.
2. A maintainer reviews ownership, purpose, visibility, and baseline requirements.
3. A maintainer applies `repo-intake: approved`.
4. The provisioning workflow creates the repository and comments back with evidence.

Configure `REPO_PROVISIONER_TOKEN` before applying the approval label.
EOF
}

_ch36_issue_form() {
  cat <<'EOF'
name: Repository request
description: Request a new organization repository through the governed intake path.
title: "Repository request: <repo-name>"
labels:
  - "repo-intake: ready-for-review"
body:
  - type: input
    id: repository_name
    attributes:
      label: Repository name
      description: Use the approved sample prefix in this lab, for example ghec-ch36-payments-api.
      placeholder: ghec-ch36-payments-api
    validations:
      required: true
  - type: input
    id: owning_team
    attributes:
      label: Owning team
      placeholder: platform-engineering
    validations:
      required: true
  - type: textarea
    id: business_purpose
    attributes:
      label: Business purpose
      description: Explain why this repository is needed and what service or product owns it.
    validations:
      required: true
  - type: dropdown
    id: visibility
    attributes:
      label: Visibility
      options:
        - private
        - internal
    validations:
      required: true
  - type: dropdown
    id: data_classification
    attributes:
      label: Data classification
      options:
        - public
        - internal
        - confidential
    validations:
      required: true
  - type: textarea
    id: baseline_requirements
    attributes:
      label: Baseline requirements
      description: List required teams, labels, rulesets, custom properties, or CI defaults.
      value: |
        - README required
        - Organization label taxonomy required
        - Owner recorded in request issue
    validations:
      required: true
EOF
}

_ch36_workflow() {
  cat <<'EOF'
name: Provision requested repository

on:
  issues:
    types: [labeled]

permissions:
  contents: read
  issues: write

jobs:
  provision:
    if: github.event.label.name == 'repo-intake: approved'
    runs-on: ubuntu-latest
    steps:
      - name: Provision repository
        uses: actions/github-script@v7
        env:
          PROVISIONER_TOKEN: ${{ secrets.REPO_PROVISIONER_TOKEN }}
          APPROVAL_LABEL: "repo-intake: approved"
          PROVISIONED_LABEL: "repo-intake: provisioned"
          FAILED_LABEL: "repo-intake: failed"
        with:
          github-token: ${{ github.token }}
          script: |
            const token = process.env.PROVISIONER_TOKEN
            const issue = context.payload.issue
            const org = context.repo.owner

            function fail(message) {
              core.setFailed(message)
              return github.rest.issues.createComment({
                owner: org,
                repo: context.repo.repo,
                issue_number: issue.number,
                body: `Repository provisioning failed: ${message}`
              }).then(() => github.rest.issues.addLabels({
                owner: org,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: [process.env.FAILED_LABEL]
              }))
            }

            if (!token) {
              await fail('missing REPO_PROVISIONER_TOKEN secret')
              return
            }

            const labels = issue.labels.map(label => label.name)
            if (!labels.includes(process.env.APPROVAL_LABEL)) {
              core.info('Approval label is not present; skipping.')
              return
            }

            const body = issue.body || ''
            const field = (label) => {
              const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
              const match = body.match(new RegExp(`### ${escaped}\\s+([^#]+)`, 'i'))
              return match ? match[1].trim() : ''
            }

            const repoName = field('Repository name')
            const ownerTeam = field('Owning team')
            const purpose = field('Business purpose')
            const visibility = field('Visibility') || 'private'

            if (!/^ghec-ch36-[a-z0-9][a-z0-9-]{2,80}$/.test(repoName)) {
              await fail(`invalid repository name "${repoName}". Use the ghec-ch36- sample prefix for this lab.`)
              return
            }
            if (!['private', 'internal'].includes(visibility)) {
              await fail(`visibility "${visibility}" is not allowed by this workflow`)
              return
            }
            if (!ownerTeam || !purpose) {
              await fail('owning team and business purpose are required')
              return
            }

            const provisioner = github.getOctokit(token)
            try {
              await provisioner.rest.repos.get({ owner: org, repo: repoName })
              await fail(`repository ${org}/${repoName} already exists`)
              return
            } catch (error) {
              if (error.status !== 404) throw error
            }

            const created = await provisioner.rest.repos.createInOrg({
              org,
              name: repoName,
              private: visibility === 'private',
              visibility,
              description: `Requested in ${context.repo.repo}#${issue.number} for ${ownerTeam}`,
              auto_init: true
            })

            for (const label of [
              ['type: chore', 'fef2c0', 'Operational or maintenance work'],
              ['priority: p2', 'cfd3d7', 'Normal priority'],
              ['status: needs-triage', 'fbca04', 'Needs initial triage']
            ]) {
              await provisioner.rest.issues.createLabel({
                owner: org,
                repo: repoName,
                name: label[0],
                color: label[1],
                description: label[2]
              }).catch(error => {
                if (error.status !== 422) throw error
              })
            }

            await github.rest.issues.createComment({
              owner: org,
              repo: context.repo.repo,
              issue_number: issue.number,
              body: `Provisioned ${created.data.html_url}\n\nOwner: ${ownerTeam}\nVisibility: ${visibility}\nWorkflow run: ${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`
            })
            await github.rest.issues.addLabels({
              owner: org,
              repo: context.repo.repo,
              issue_number: issue.number,
              labels: [process.env.PROVISIONED_LABEL]
            })
EOF
}

_ch36_seed_labels() {
  log_step "seeding intake labels"
  local existing
  existing="$(gh label list --repo "$(_ch36_repo_full)" --limit 100 \
    --json name --jq '.[].name' 2>/dev/null || true)"
  local labels=(
    "repo-intake: ready-for-review|fbca04|Request is ready for maintainer review"
    "repo-intake: approved|0e8a16|Maintainer approval to provision"
    "repo-intake: provisioned|1a7f37|Repository was provisioned"
    "repo-intake: failed|d73a4a|Provisioning failed"
    "repo-intake: rejected|57606a|Request was rejected"
  )
  local entry name color desc
  for entry in "${labels[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    if printf '%s\n' "$existing" | grep -qxF "$name"; then
      log_ok "label '$name' exists (skip)"
      continue
    fi
    run_mutation gh label create "$name" --repo "$(_ch36_repo_full)" \
      --color "$color" --description "$desc"
    existing="${existing}"$'\n'"${name}"
  done
}

_ch36_seed_files() {
  log_step "seeding issue form and workflow"
  gh_put_file "$ORG" "$INTAKE_REPO" "README.md" "Add repository intake README" "$(_ch36_readme)"
  gh_put_file "$ORG" "$INTAKE_REPO" ".github/ISSUE_TEMPLATE/repository-request.yml" \
    "Add repository request issue form" "$(_ch36_issue_form)"
  gh_put_file "$ORG" "$INTAKE_REPO" ".github/workflows/provision-repository.yml" \
    "Add repository provisioning workflow scaffold" "$(_ch36_workflow)"
}

_ch36_seed_issue() {
  log_step "seeding sample repository request"
  local title="Repository request: ghec-ch36-sample-service"
  local existing
  existing="$(gh issue list --repo "$(_ch36_repo_full)" --state all --limit 100 \
    --json title --jq '.[].title' 2>/dev/null || true)"
  if printf '%s\n' "$existing" | grep -qxF "$title"; then
    log_ok "sample request exists (skip)"
    return 0
  fi
  run_mutation gh issue create --repo "$(_ch36_repo_full)" \
    --title "$title" \
    --label "repo-intake: ready-for-review" \
    --body "$(cat <<'EOF'
### Repository name
ghec-ch36-sample-service

### Owning team
platform-engineering

### Business purpose
Sample request used to validate controlled repository intake.

### Visibility
private

### Data classification
internal

### Baseline requirements
- README required
- Organization label taxonomy required
- Owner recorded in request issue
EOF
)"
}

_ch36_print_policy() {
  log_step "organization repository-creation policy snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api /orgs/$ORG repository-creation settings"
    return 0
  fi
  gh api "/orgs/$ORG" \
    --jq '{members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories}' \
    2>/dev/null || log_warn "could not read org repository-creation settings (needs admin:org / read:org)"
}

ghec_provision() {
  gh_create_repo "$ORG" "$INTAKE_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$INTAKE_REPO"; then
    die "repo $(_ch36_repo_full) missing after create — aborting seed"
  fi
  _ch36_seed_labels
  _ch36_seed_files
  _ch36_seed_issue
  _ch36_print_policy
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - configure REPO_PROVISIONER_TOKEN on $INTAKE_REPO"
  log_info "  - inspect or restrict member repository creation"
  log_info "  - apply 'repo-intake: approved' to the sample request when ready"
}

ghec_teardown() {
  guard_prefix "$INTAKE_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$INTAKE_REPO"
  log_warn "teardown does not delete repositories provisioned by the workflow unless they use the ghec-${CHID}- prefix and are removed manually"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$INTAKE_REPO"; then
    local issues labels
    issues="$(gh issue list --repo "$(_ch36_repo_full)" --state all --limit 200 \
      --json number --jq 'length' 2>/dev/null || echo '?')"
    labels="$(gh label list --repo "$(_ch36_repo_full)" --limit 100 \
      --json name --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch36_repo_full) present — $issues issues, $labels labels"
  else
    log_info "repo $(_ch36_repo_full) not provisioned"
  fi
}
