# challenges/ch41-required-reusable-workflows/provision.ps1

$Global:GhecCh41Library = "ghec-$($Global:GhecChid)-workflow-library"
$Global:GhecCh41Consumer = "ghec-$($Global:GhecChid)-consumer-service"

function _Ch41-Full { param([string]$Repo) "$($Global:GhecOrg)/$Repo" }

function _Ch41-LibraryReadme {
@'
# Required Workflow Library

This repository owns reusable workflows for organization baseline checks. Treat changes as platform releases: review, version, communicate, and support rollback.
'@
}

function _Ch41-BaselineWorkflow {
@'
name: Baseline required checks

on:
  workflow_call:
    inputs:
      service-name:
        required: true
        type: string

permissions:
  contents: read

jobs:
  baseline:
    runs-on: ubuntu-latest
    steps:
      - name: Validate service metadata
        run: |
          test -n "${{ inputs.service-name }}"
          echo "Baseline checks passed for ${{ inputs.service-name }}"
      - name: Check required files
        run: |
          echo "Reusable workflow library owns this check. Extend with approved organization gates."
'@
}

function _Ch41-ConsumerReadme {
@'
# Consumer Service

Use this repository to prove the reusable baseline workflow can be called and then required by an approved ruleset or required-workflow control.
'@
}

function _Ch41-ConsumerWorkflow {
@"
name: Consumer baseline

on:
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  required-baseline:
    uses: $($Global:GhecOrg)/$($Global:GhecCh41Library)/.github/workflows/baseline.yml@main
    with:
      service-name: $($Global:GhecCh41Consumer)
"@
}

function _Ch41-Governance {
@'
# Required Reusable Workflow Governance

| Decision | Value |
|---|---|
| Library owner | TBD |
| Required check | Baseline required checks |
| Versioning model | TBD |
| Authorized repository cohort | TBD |
| Exception approver | TBD |
| Next review | TBD |

Required workflows or rulesets must be configured manually by the participant after approval.
'@
}

function _Ch41-SeedLibrary {
  Write-GhecStep 'seeding reusable workflow library'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh41Library -Path 'README.md' -Message 'Add reusable workflow library README' -Content (_Ch41-LibraryReadme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh41Library -Path '.github/workflows/baseline.yml' -Message 'Add reusable baseline workflow' -Content (_Ch41-BaselineWorkflow)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh41Library -Path 'governance/required-workflow-register.md' -Message 'Add required workflow register' -Content (_Ch41-Governance)
}

function _Ch41-SeedConsumer {
  Write-GhecStep 'seeding consumer repository'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh41Consumer -Path 'README.md' -Message 'Add consumer README' -Content (_Ch41-ConsumerReadme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh41Consumer -Path '.github/workflows/consumer-baseline.yml' -Message 'Add consumer baseline caller' -Content (_Ch41-ConsumerWorkflow)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh41Consumer -Path 'src/service.txt' -Message 'Add sample service file' -Content "sample service content for ghec-$($Global:GhecChid)"
}

function _Ch41-PrintSnapshot {
  Write-GhecStep 'repository workflow and ruleset snapshot'
  if ($Global:GhecDryRun) { Write-GhecPlan "would list workflows and rulesets for $($Global:GhecCh41Library) and $($Global:GhecCh41Consumer)"; return }
  gh workflow list --repo (_Ch41-Full $Global:GhecCh41Library)
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not list library workflows' }
  gh workflow list --repo (_Ch41-Full $Global:GhecCh41Consumer)
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not list consumer workflows' }
  gh api "repos/$(_Ch41-Full $Global:GhecCh41Consumer)/rulesets" --jq '.[]? | {name, enforcement, target}'
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read repository rulesets' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh41Library -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh41Consumer -Visibility private
  if (-not $Global:GhecDryRun) {
    if (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh41Library)) { Stop-Ghec "repo $(_Ch41-Full $Global:GhecCh41Library) missing after create" }
    if (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh41Consumer)) { Stop-Ghec "repo $(_Ch41-Full $Global:GhecCh41Consumer) missing after create" }
  }
  _Ch41-SeedLibrary
  _Ch41-SeedConsumer
  _Ch41-PrintSnapshot
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - review and version the reusable workflow'
  Write-GhecInfo "  - allow approved org repositories to call workflows from $($Global:GhecCh41Library) in Settings > Actions > General > Access"
  Write-GhecInfo '  - validate the consumer caller workflow'
  Write-GhecInfo '  - configure required workflow or ruleset manually for the approved cohort'
}

function Invoke-GhecTeardown {
  foreach ($r in @($Global:GhecCh41Library, $Global:GhecCh41Consumer)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $Global:GhecOrg -Repo $r
  }
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  foreach ($r in @($Global:GhecCh41Library, $Global:GhecCh41Consumer)) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $r) {
      $workflows = @(gh workflow list --repo (_Ch41-Full $r) 2>$null).Count
      Write-GhecOk "repo $(_Ch41-Full $r) present — $workflows workflows"
    } else {
      Write-GhecInfo "repo $(_Ch41-Full $r) not provisioned"
    }
  }
}
