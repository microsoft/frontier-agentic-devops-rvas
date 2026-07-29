# shellcheck shell=bash
#
# challenges/ch40-actions-oidc-azure/provision.sh
#
# Seeds an OIDC-with-Azure workflow scaffold. Setup creates no Azure resources,
# credentials, federated credentials, or role assignments.

CH40_REPO="ghec-${CHID}-oidc-azure"
CH40_ENV="ghec-${CHID}-prod"

_ch40_repo_full() { printf '%s/%s' "$ORG" "$CH40_REPO"; }

_ch40_readme() {
  cat <<'EOF_README'
# Actions OIDC with Azure

Use this repository to validate GitHub Actions OpenID Connect with Azure.

Participant-owned cloud steps:

1. Create or select an Azure identity.
2. Add a federated credential for the approved GitHub subject claim.
3. Assign least-privilege Azure RBAC.
4. Add non-secret IDs as repository or environment variables.

Setup intentionally creates no Azure resources and no secrets.
EOF_README
}

_ch40_workflow() {
  cat <<'EOF_WORKFLOW'
name: Azure OIDC validation

on:
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

jobs:
  azure-login:
    runs-on: ubuntu-latest
    environment: ghec-ch40-prod
    steps:
      - name: Explain required variables
        run: |
          echo "Configure AZURE_CLIENT_ID, AZURE_TENANT_ID, and AZURE_SUBSCRIPTION_ID as variables."
          echo "No Azure client secret should be configured."
      - name: Azure login with OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - name: Show Azure context
        run: az account show --query '{tenantId:tenantId, subscriptionId:id, user:user.name}' -o json
EOF_WORKFLOW
}

_ch40_design() {
  cat <<'EOF_DESIGN'
# Azure OIDC Trust Design

| Field | Decision |
|---|---|
| GitHub organization | TBD |
| Repository | ghec-ch40-oidc-azure |
| Environment or branch subject | repo:<org>/ghec-ch40-oidc-azure:environment:ghec-ch40-prod |
| Audience | api://AzureADTokenExchange |
| Azure tenant | TBD |
| Azure subscription | TBD |
| Identity/app registration | TBD |
| Azure role and scope | TBD |
| GitHub owner | TBD |
| Azure owner | TBD |
| Old secret retirement date | TBD |

Record positive and negative workflow evidence here.
EOF_DESIGN
}

_ch40_seed_files() {
  log_step "seeding Azure OIDC workflow scaffold"
  gh_put_file "$ORG" "$CH40_REPO" "README.md" "Add Azure OIDC README" "$(_ch40_readme)"
  gh_put_file "$ORG" "$CH40_REPO" ".github/workflows/azure-oidc.yml" "Add Azure OIDC workflow" "$(_ch40_workflow)"
  gh_put_file "$ORG" "$CH40_REPO" "governance/azure-oidc-trust-design.md" "Add Azure OIDC trust design" "$(_ch40_design)"
}

_ch40_put_environment() {
  log_step "ensuring repository environment $CH40_ENV"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would PUT repos/$(_ch40_repo_full)/environments/$CH40_ENV"
    return 0
  fi
  gh api -X PUT "repos/$(_ch40_repo_full)/environments/$CH40_ENV" >/dev/null \
    || log_warn "could not create environment '$CH40_ENV' (participant can create it manually)"
}

_ch40_print_snapshot() {
  log_step "repository OIDC readiness snapshot"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read environments and workflow files for $(_ch40_repo_full)"
    return 0
  fi
  gh api "repos/$(_ch40_repo_full)/environments" --jq '.environments[]? | {name, protection_rules}' \
    || log_warn "could not list repository environments"
  gh api "repos/$(_ch40_repo_full)/actions/permissions" --jq '{enabled, allowed_actions, selected_actions_url}' \
    || log_warn "could not read repository Actions permissions"
}

ghec_provision() {
  gh_create_repo "$ORG" "$CH40_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$CH40_REPO"; then
    die "repo $(_ch40_repo_full) missing after create — aborting seed"
  fi
  _ch40_seed_files
  _ch40_put_environment
  _ch40_print_snapshot
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - configure Azure federated credential explicitly"
  log_info "  - add AZURE_* variables, not secrets"
  log_info "  - validate approved and denied subject claims"
}

ghec_teardown() {
  guard_prefix "$CH40_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$CH40_REPO"
  log_warn "teardown does not remove Azure identities, federated credentials, or role assignments"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$CH40_REPO"; then
    local envs
    envs="$(gh api "repos/$(_ch40_repo_full)/environments" --jq '.total_count' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch40_repo_full) present — $envs environments"
  else
    log_info "repo $(_ch40_repo_full) not provisioned"
  fi
}
