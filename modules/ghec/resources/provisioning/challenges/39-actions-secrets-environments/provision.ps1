# challenges/39-actions-secrets-environments/provision.ps1

$Global:GhecCh39Repo = "ghec-$($Global:GhecChid)-actions-secrets-envs"
$Global:GhecCh39EnvDev = "ghec-$($Global:GhecChid)-dev"
$Global:GhecCh39EnvProd = "ghec-$($Global:GhecChid)-prod"

function _Ch39-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh39Repo)" }

function _Ch39-Readme {
@'
# Actions Secrets and Environments Governance

Use this repository to practice moving deployment credentials from broad repository secrets to protected GitHub Actions environments.

## Participant-owned setup

1. Inventory secret metadata only; never record values.
2. Configure environment protection rules for production after owner approval.
3. Add environment secrets through GitHub UI or `gh secret set --env`.
4. Validate that unauthorized branches cannot access production credentials.

Setup intentionally creates no secrets.
'@
}

function _Ch39-Workflow {
@'
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
'@
}

function _Ch39-Register {
@'
# Secret and Environment Governance Register

| Secret name | Scope | Consumer workflow/job | Owner | Rotation cadence | Move/retain decision | Evidence |
|---|---|---|---|---|---|---|
| DEPLOY_TOKEN | environment | deploy | TBD | TBD | Move to protected production environment | TBD |

## Environment decisions

| Environment | Reviewers | Branch or tag policy | Wait timer | Exception owner | Next review |
|---|---|---|---|---|---|
| ghec-ch39-dev | optional | feature and main branches | none | TBD | TBD |
| ghec-ch39-prod | required | protected release branches or tags | TBD | TBD | TBD |
'@
}

function _Ch39-PutEnvironment {
  param([string]$Name)
  Write-GhecStep "ensuring repository environment $Name"
  Invoke-GhecMutation -Plan "gh api -X PUT repos/$(_Ch39-RepoFull)/environments/$Name" -Action {
    gh api -X PUT "repos/$(_Ch39-RepoFull)/environments/$Name" | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-GhecWarn "could not create environment '$Name' (participant can create it manually)" }
  }
}

function _Ch39-SeedFiles {
  Write-GhecStep 'seeding workflow and governance checklist'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo -Path 'README.md' -Message 'Add Actions environment governance README' -Content (_Ch39-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo -Path '.github/workflows/environment-deploy.yml' -Message 'Add environment deployment workflow' -Content (_Ch39-Workflow)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo -Path 'governance/secret-environment-register.md' -Message 'Add secret environment register' -Content (_Ch39-Register)
}

function _Ch39-PrintSnapshot {
  Write-GhecStep 'repository Actions secrets and environments snapshot'
  if ($Global:GhecDryRun) { Write-GhecPlan "would list repo secrets and environments for $(_Ch39-RepoFull)"; return }
  gh secret list --repo (_Ch39-RepoFull)
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not list repository secrets' }
  gh api "repos/$(_Ch39-RepoFull)/environments" --jq '.environments[]? | {name, protection_rules}'
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not list repository environments' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo))) {
    Stop-Ghec "repo $(_Ch39-RepoFull) missing after create — aborting seed"
  }
  _Ch39-SeedFiles
  _Ch39-PutEnvironment $Global:GhecCh39EnvDev
  _Ch39-PutEnvironment $Global:GhecCh39EnvProd
  _Ch39-PrintSnapshot
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - inventory secret metadata without values'
  Write-GhecInfo "  - configure reviewers/branch policies on $($Global:GhecCh39EnvProd)"
  Write-GhecInfo '  - add environment secrets manually and validate workflow gating'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh39Repo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh39Repo) {
    $envs = gh api "repos/$(_Ch39-RepoFull)/environments" --jq '.total_count' 2>$null
    $secrets = @(gh secret list --repo (_Ch39-RepoFull) 2>$null).Count
    Write-GhecOk "repo $(_Ch39-RepoFull) present — $envs environments, $secrets listed secrets"
  } else {
    Write-GhecInfo "repo $(_Ch39-RepoFull) not provisioned"
  }
}
