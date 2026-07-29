# shellcheck shell=bash
#
# challenges/ch39-actions-secrets-environments/provision.sh
#
# Seeds a repository for Actions secrets/environments governance. Setup creates
# no secrets and does not apply high-impact production protection choices.

CH39_REPO="ghec-${CHID}-actions-secrets-envs"
CH39_ENV_DEV="ghec-${CHID}-dev"
CH39_ENV_PROD="ghec-${CHID}-prod"

_ch39_repo_full() { printf '%s/%s' "$ORG" "$CH39_REPO"; }

_ch39_readme() {
  cat <<'EOF_README'
# Actions Secrets and Environments Governance

Use this repository to practice moving deployment credentials from broad repository secrets to protected GitHub Actions environments.

## Participant-owned setup

1. Inventory secret metadata only; never record values.
2. Configure environment protection rules for production after owner approval.
3. Add environment secrets through GitHub UI or `gh secret set --env`.
4. Validate that unauthorized branches cannot access production credentials.

Setup intentionally creates no secrets.
EOF_README
}

_ch39_workflow() {
  cat <<'EOF_WORKFLOW'
name: Environment-gated deployment sample

on:
  workflow_dispatch:
    inputs:
      target_environment:
        description: Environment to deploy to
        required: true
        default: ghec-ch39-dev
        type: choice
        options:
          - ghec-ch39-dev
          - ghec-ch39-prod

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.target_environment }}
    steps:
      - name: Show environment gate
        run: |
          echo "Deployment job entered environment: ${{ inputs.target_environment }}"
          echo "Add environment-scoped secrets after approval; do not print secret values."
      - name: Validate expected secret metadata only
        env:
          DEPLOY_TOKEN_PRESENT: ${{ secrets.DEPLOY_TOKEN != '' }}
        run: |
          if [ "$DEPLOY_TOKEN_PRESENT" = "true" ]; then
            echo "DEPLOY_TOKEN is present for this environment."
          else
            echo "DEPLOY_TOKEN is not configured yet; add it as an environment secret during the lab."
          fi
EOF_WORKFLOW
}

_ch39_register() {
  cat <<'EOF_REGISTER'
# Secret and Environment Governance Register

| Secret name | Scope | Consumer workflow/job | Owner | Rotation cadence | Move/retain decision | Evidence |
|---|---|---|---|---|---|---|
| DEPLOY_TOKEN | environment | deploy | TBD | TBD | Move to protected production environment | TBD |

## Environment decisions

| Environment | Reviewers | Branch or tag policy | Wait timer | Exception owner | Next review |
|---|---|---|---|---|---|
| ghec-ch39-dev | optional | feature and main branches | none | TBD | TBD |
| ghec-ch39-prod | required | protected release branches or tags | TBD | TBD | TBD |
EOF_REGISTER
}

_ch39_put_environment() {
  local env_name="$1"
  log_step "ensuring repository environment $env_name"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would PUT repos/$(_ch39_repo_full)/environments/$env_name"
    return 0
  fi
  gh api -X PUT "repos/$(_ch39_repo_full)/environments/$env_name" >/dev/null \
    || log_warn "could not create environment '$env_name' (participant can create it manually)"
}

_ch39_seed_files() {
  log_step "seeding workflow and governance checklist"
  gh_put_file "$ORG" "$CH39_REPO" "README.md" "Add Actions environment governance README" "$(_ch39_readme)"
  gh_put_file "$ORG" "$CH39_REPO" ".github/workflows/environment-deploy.yml" "Add environment deployment workflow" "$(_ch39_workflow)"
  gh_put_file "$ORG" "$CH39_REPO" "governance/secret-environment-register.md" "Add secret environment register" "$(_ch39_register)"
}

_ch39_print_snapshot() {
  log_step "repository Actions secrets and environments snapshot"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would list repo secrets and environments for $(_ch39_repo_full)"
    return 0
  fi
  gh secret list --repo "$(_ch39_repo_full)" || log_warn "could not list repository secrets"
  gh api "repos/$(_ch39_repo_full)/environments" --jq '.environments[]? | {name, protection_rules}' \
    || log_warn "could not list repository environments"
}

ghec_provision() {
  gh_create_repo "$ORG" "$CH39_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$CH39_REPO"; then
    die "repo $(_ch39_repo_full) missing after create — aborting seed"
  fi
  _ch39_seed_files
  _ch39_put_environment "$CH39_ENV_DEV"
  _ch39_put_environment "$CH39_ENV_PROD"
  _ch39_print_snapshot
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - inventory secret metadata without values"
  log_info "  - configure reviewers/branch policies on $CH39_ENV_PROD"
  log_info "  - add environment secrets manually and validate workflow gating"
}

ghec_teardown() {
  guard_prefix "$CH39_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$CH39_REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$CH39_REPO"; then
    local envs secrets
    envs="$(gh api "repos/$(_ch39_repo_full)/environments" --jq '.total_count' 2>/dev/null || echo '?')"
    secrets="$(gh secret list --repo "$(_ch39_repo_full)" 2>/dev/null | wc -l | tr -d ' ' || echo '?')"
    log_ok "repo $(_ch39_repo_full) present — $envs environments, $secrets listed secrets"
  else
    log_info "repo $(_ch39_repo_full) not provisioned"
  fi
}
