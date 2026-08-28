# challenges/ch13-dependabot-dependency-review/provision.ps1
#
# PowerShell twin of ch13.

$Global:GhecJsRepo = "ghec-$($Global:GhecChid)-juice-shop"

function _Ch13-JsFull { "$($Global:GhecOrg)/$($Global:GhecJsRepo)" }

function _Ch13-DependabotConfig {
@'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
'@
}

function _Ch13-SeedConfig {
  Write-GhecStep 'seeding .github/dependabot.yml'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/dependabot.yml' `
    -Message 'Add Dependabot version + security update config' -Content (_Ch13-DependabotConfig)
}

function _Ch13-SeedRiskyBranch {
  Write-GhecStep 'seeding feature/add-risky-dep (known-vulnerable dependency)'
  New-GhecBranch -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Branch 'feature/add-risky-dep' -Base 'main'
  $pkg = @'
{
  "name": "ghec-ch13-risky-dep",
  "version": "1.0.0",
  "private": true,
  "description": "ghec-ch13 SEED — pins known-vulnerable versions so dependency review flags the PR diff.",
  "dependencies": {
    "lodash": "4.17.4",
    "minimist": "1.2.0",
    "marked": "0.3.6"
  }
}
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'ghec-risky-dep/package.json' `
    -Message 'Add a known-vulnerable dependency (seed, for dependency-review)' -Content $pkg -Branch 'feature/add-risky-dep'
}

# ===========================================================================
function Invoke-GhecProvision {
  Import-GhecJuiceShop -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Ref $Global:GhecJuiceShopRef
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo))) {
    Stop-Ghec "repo $(_Ch13-JsFull) missing after import — aborting seed"
  }
  _Ch13-SeedConfig
  _Ch13-SeedRiskyBranch
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - enable Dependabot alerts + security updates in Security settings'
  Write-GhecInfo '  - review the dependency graph and triage the alerts'
  Write-GhecInfo '  - open a PR from feature/add-risky-dep and read the dependency-review result'
  Write-GhecWarn 'manual: Dependabot alerts/security updates are toggled in repo Security settings.'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecJsRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecJsRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo) {
    $cfg = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/dependabot.yml') { 'present' } else { 'MISSING' }
    $branch = if (Test-GhecBranchExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Branch 'feature/add-risky-dep') { 'present' } else { 'MISSING' }
    Write-GhecOk "repo $(_Ch13-JsFull) present — dependabot.yml $cfg, feature/add-risky-dep $branch"
  } else {
    Write-GhecInfo "repo $(_Ch13-JsFull) not provisioned"
  }
}
