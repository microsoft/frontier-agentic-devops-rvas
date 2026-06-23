# challenges/ch13-dependabot-dependency-review/provision.ps1
#
# PowerShell twin of ch13.

$Global:WthJsRepo = "wth-$($Global:WthChid)-juice-shop"

function _Ch13-JsFull { "$($Global:WthOrg)/$($Global:WthJsRepo)" }

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
  Write-WthStep 'seeding .github/dependabot.yml'
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/dependabot.yml' `
    -Message 'Add Dependabot version + security update config' -Content (_Ch13-DependabotConfig)
}

function _Ch13-SeedRiskyBranch {
  Write-WthStep 'seeding feature/add-risky-dep (known-vulnerable dependency)'
  New-WthBranch -Org $Global:WthOrg -Repo $Global:WthJsRepo -Branch 'feature/add-risky-dep' -Base 'main'
  $pkg = @'
{
  "name": "wth-ch13-risky-dep",
  "version": "1.0.0",
  "private": true,
  "description": "wth-ch13 SEED — pins known-vulnerable versions so dependency review flags the PR diff.",
  "dependencies": {
    "lodash": "4.17.4",
    "minimist": "1.2.0",
    "marked": "0.3.6"
  }
}
'@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'wth-risky-dep/package.json' `
    -Message 'Add a known-vulnerable dependency (seed, for dependency-review)' -Content $pkg -Branch 'feature/add-risky-dep'
}

# ===========================================================================
function Invoke-WthProvision {
  Import-WthJuiceShop -Org $Global:WthOrg -Repo $Global:WthJsRepo -Ref $Global:WthJuiceShopRef
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo))) {
    Stop-Wth "repo $(_Ch13-JsFull) missing after import — aborting seed"
  }
  _Ch13-SeedConfig
  _Ch13-SeedRiskyBranch
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - enable Dependabot alerts + security updates in Security settings'
  Write-WthInfo '  - review the dependency graph and triage the alerts'
  Write-WthInfo '  - open a PR from feature/add-risky-dep and read the dependency-review result'
  Write-WthWarn 'manual: Dependabot alerts/security updates are toggled in repo Security settings.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthJsRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthJsRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo) {
    $cfg = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/dependabot.yml') { 'present' } else { 'MISSING' }
    $branch = if (Test-WthBranchExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Branch 'feature/add-risky-dep') { 'present' } else { 'MISSING' }
    Write-WthOk "repo $(_Ch13-JsFull) present — dependabot.yml $cfg, feature/add-risky-dep $branch"
  } else {
    Write-WthInfo "repo $(_Ch13-JsFull) not provisioned"
  }
}
