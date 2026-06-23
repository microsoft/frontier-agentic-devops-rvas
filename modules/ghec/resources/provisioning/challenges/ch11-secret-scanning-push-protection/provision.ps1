# challenges/ch11-secret-scanning-push-protection/provision.ps1
#
# PowerShell twin. Dot-sourced by scripts/setup.ps1 (globals Wth*; helpers
# Write-Wth*, Invoke-WthMutation, *-WthRepo, Set-WthFile, New-WthBranch,
# Confirm-WthPrefix, Import-WthJuiceShop).

$Global:WthJsRepo = "wth-$($Global:WthChid)-juice-shop"

# Non-live / synthetic secrets — pattern-shaped only, grant nothing.
$Global:WthAwsKeyId      = 'AKIAIOSFODNN7EXAMPLE'
$Global:WthAwsSecret     = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
$Global:WthGhToken       = 'ghp_000000000000000000000000000000WTHch11'
$Global:WthAwsKeyIdFresh = 'AKIAIOSFODNN7WTHFRESH'

function _Ch11-JsFull { "$($Global:WthOrg)/$($Global:WthJsRepo)" }

function _Ch11-PlantSecrets {
  Write-WthStep 'planting non-live partner-pattern secrets'
  $aws = @"
; wth-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
[default]
aws_access_key_id = $($Global:WthAwsKeyId)
aws_secret_access_key = $($Global:WthAwsSecret)
region = us-east-1
"@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'config/aws-credentials.ini' `
    -Message 'Add legacy AWS uploader credentials (seed)' -Content $aws

  $deploy = @"
#!/usr/bin/env bash
# wth-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
set -e
GITHUB_TOKEN="$($Global:WthGhToken)"
echo "deploying with `$GITHUB_TOKEN" >/dev/null
"@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'scripts/deploy.sh' `
    -Message 'Add deploy helper with embedded token (seed)' -Content $deploy
}

function _Ch11-SeedManifest {
  Write-WthStep 'writing SECRETS-MANIFEST.md'
  $m = @"
# SECRETS-MANIFEST — wth-ch11

Every secret below is **synthetic / non-live** and exists only so secret
scanning + push protection have partner-pattern material to detect. None
grant any access. Reconcile each row against the secret-scanning alert list.

| # | Location | Secret type | Pattern | Branch |
|---|----------|-------------|---------|--------|
| 1 | ``config/aws-credentials.ini`` | AWS access key id + secret | ``AKIA…`` | main |
| 2 | ``scripts/deploy.sh`` | GitHub-style token | ``ghp_…`` | main |
| 3 | ``config/extra-uploader.ini`` | AWS access key id (fresh) | ``AKIA…`` | feature/leaky-config |

All values are documented EXAMPLE / padded-filler credentials.
"@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'SECRETS-MANIFEST.md' `
    -Message 'Add SECRETS-MANIFEST for wth-ch11' -Content $m
}

function _Ch11-SeedLeakyBranch {
  Write-WthStep 'seeding feature/leaky-config with a fresh planted secret'
  New-WthBranch -Org $Global:WthOrg -Repo $Global:WthJsRepo -Branch 'feature/leaky-config' -Base 'main'
  $extra = @"
; wth-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
[uploader]
aws_access_key_id = $($Global:WthAwsKeyIdFresh)
aws_secret_access_key = $($Global:WthAwsSecret)
"@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'config/extra-uploader.ini' `
    -Message 'Add second uploader credential (seed)' -Content $extra -Branch 'feature/leaky-config'
}

# ===========================================================================
function Invoke-WthProvision {
  Import-WthJuiceShop -Org $Global:WthOrg -Repo $Global:WthJsRepo -Ref $Global:WthJuiceShopRef
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo))) {
    Stop-Wth "repo $(_Ch11-JsFull) missing after import — aborting seed"
  }
  _Ch11-PlantSecrets
  _Ch11-SeedManifest
  _Ch11-SeedLeakyBranch
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - enable secret scanning + push protection in the repo Security settings'
  Write-WthInfo '  - reconcile each SECRETS-MANIFEST.md row against the alert list'
  Write-WthInfo '  - try pushing the fresh secret to confirm push protection blocks it'
  Write-WthWarn 'manual: enabling secret scanning/push protection is the learning — not auto-enabled.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthJsRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthJsRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo) {
    $manifest = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'SECRETS-MANIFEST.md') { 'present' } else { 'MISSING' }
    $branch = if (Test-WthBranchExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Branch 'feature/leaky-config') { 'present' } else { 'MISSING' }
    Write-WthOk "repo $(_Ch11-JsFull) present — SECRETS-MANIFEST.md $manifest, feature/leaky-config $branch"
  } else {
    Write-WthInfo "repo $(_Ch11-JsFull) not provisioned"
  }
}
