# challenges/40-actions-oidc-azure/provision.ps1

$Global:GhecCh40Repo = "ghec-$($Global:GhecChid)-oidc-azure"
$Global:GhecCh40Env = "ghec-$($Global:GhecChid)-prod"

function _Ch40-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh40Repo)" }

function _Ch40-Readme {
@'
# Actions OIDC with Azure

Use this repository to validate GitHub Actions OpenID Connect with Azure.

Participant-owned cloud steps:

1. Create or select an Azure identity.
2. Add a federated credential for the approved GitHub subject claim.
3. Assign least-privilege Azure RBAC.
4. Add non-secret IDs as repository or environment variables.

Setup intentionally creates no Azure resources and no secrets.
'@
}

function _Ch40-Workflow {
@'
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
'@
}

function _Ch40-Design {
@'
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
'@
}

function _Ch40-SeedFiles {
  Write-GhecStep 'seeding Azure OIDC workflow scaffold'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo -Path 'README.md' -Message 'Add Azure OIDC README' -Content (_Ch40-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo -Path '.github/workflows/azure-oidc.yml' -Message 'Add Azure OIDC workflow' -Content (_Ch40-Workflow)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo -Path 'governance/azure-oidc-trust-design.md' -Message 'Add Azure OIDC trust design' -Content (_Ch40-Design)
}

function _Ch40-PutEnvironment {
  Write-GhecStep "ensuring repository environment $($Global:GhecCh40Env)"
  Invoke-GhecMutation -Plan "gh api -X PUT repos/$(_Ch40-RepoFull)/environments/$($Global:GhecCh40Env)" -Action {
    gh api -X PUT "repos/$(_Ch40-RepoFull)/environments/$($Global:GhecCh40Env)" | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-GhecWarn "could not create environment '$($Global:GhecCh40Env)' (participant can create it manually)" }
  }
}

function _Ch40-PrintSnapshot {
  Write-GhecStep 'repository OIDC readiness snapshot'
  if ($Global:GhecDryRun) { Write-GhecPlan "would read environments and workflow files for $(_Ch40-RepoFull)"; return }
  gh api "repos/$(_Ch40-RepoFull)/environments" --jq '.environments[]? | {name, protection_rules}'
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not list repository environments' }
  gh api "repos/$(_Ch40-RepoFull)/actions/permissions" --jq '{enabled, allowed_actions, selected_actions_url}'
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read repository Actions permissions' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo))) {
    Stop-Ghec "repo $(_Ch40-RepoFull) missing after create — aborting seed"
  }
  _Ch40-SeedFiles
  _Ch40-PutEnvironment
  _Ch40-PrintSnapshot
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - configure Azure federated credential explicitly'
  Write-GhecInfo '  - add AZURE_* variables, not secrets'
  Write-GhecInfo '  - validate approved and denied subject claims'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh40Repo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo
  Write-GhecWarn 'teardown does not remove Azure identities, federated credentials, or role assignments'
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh40Repo) {
    $envs = gh api "repos/$(_Ch40-RepoFull)/environments" --jq '.total_count' 2>$null
    Write-GhecOk "repo $(_Ch40-RepoFull) present — $envs environments"
  } else {
    Write-GhecInfo "repo $(_Ch40-RepoFull) not provisioned"
  }
}
