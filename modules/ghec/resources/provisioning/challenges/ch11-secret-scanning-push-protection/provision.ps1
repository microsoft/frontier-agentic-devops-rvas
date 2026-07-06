# challenges/ch11-secret-scanning-push-protection/provision.ps1
#
# PowerShell twin. Dot-sourced by scripts/setup.ps1 (globals Ghec*; helpers
# Write-Ghec*, Invoke-GhecMutation, *-GhecRepo, Set-GhecFile, New-GhecBranch,
# Confirm-GhecPrefix, Import-GhecJuiceShop).

$Global:GhecJsRepo = "ghec-$($Global:GhecChid)-juice-shop"

# Non-live / synthetic secrets — pattern-shaped only, grant nothing.
$Global:GhecAwsKeyId      = 'AKIAIOSFODNN7EXAMPLE'
$Global:GhecAwsSecret     = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
$Global:GhecGhToken       = 'ghp_000000000000000000000000000000WTHch11'
$Global:GhecAwsKeyIdFresh = 'AKIAIOSFODNN7WTHFRESH'

function _Ch11-JsFull { "$($Global:GhecOrg)/$($Global:GhecJsRepo)" }

function _Ch11-PlantSecrets {
  Write-GhecStep 'planting non-live partner-pattern secrets'
  $aws = @"
; ghec-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
[default]
aws_access_key_id = $($Global:GhecAwsKeyId)
aws_secret_access_key = $($Global:GhecAwsSecret)
region = us-east-1
"@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'config/aws-credentials.ini' `
    -Message 'Add legacy AWS uploader credentials (seed)' -Content $aws

  $deploy = @"
#!/usr/bin/env bash
# ghec-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
set -e
GITHUB_TOKEN="$($Global:GhecGhToken)"
echo "deploying with `$GITHUB_TOKEN" >/dev/null
"@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'scripts/deploy.sh' `
    -Message 'Add deploy helper with embedded token (seed)' -Content $deploy
}

function _Ch11-SeedManifest {
  Write-GhecStep 'writing SECRETS-MANIFEST.md'
  $m = @"
# SECRETS-MANIFEST — ghec-ch11

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
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'SECRETS-MANIFEST.md' `
    -Message 'Add SECRETS-MANIFEST for ghec-ch11' -Content $m
}

function _Ch11-SeedLeakyBranch {
  Write-GhecStep 'seeding feature/leaky-config with a fresh planted secret'
  New-GhecBranch -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Branch 'feature/leaky-config' -Base 'main'
  $extra = @"
; ghec-ch11 planted NON-LIVE test secret — see SECRETS-MANIFEST.md
[uploader]
aws_access_key_id = $($Global:GhecAwsKeyIdFresh)
aws_secret_access_key = $($Global:GhecAwsSecret)
"@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'config/extra-uploader.ini' `
    -Message 'Add second uploader credential (seed)' -Content $extra -Branch 'feature/leaky-config'
}

# ===========================================================================
function Invoke-GhecProvision {
  Import-GhecJuiceShop -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Ref $Global:GhecJuiceShopRef
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo))) {
    Stop-Ghec "repo $(_Ch11-JsFull) missing after import — aborting seed"
  }
  _Ch11-PlantSecrets
  _Ch11-SeedManifest
  _Ch11-SeedLeakyBranch
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - enable secret scanning + push protection in the repo Security settings'
  Write-GhecInfo '  - reconcile each SECRETS-MANIFEST.md row against the alert list'
  Write-GhecInfo '  - try pushing the fresh secret to confirm push protection blocks it'
  Write-GhecWarn 'manual: enabling secret scanning/push protection is the learning — not auto-enabled.'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecJsRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecJsRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo) {
    $manifest = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'SECRETS-MANIFEST.md') { 'present' } else { 'MISSING' }
    $branch = if (Test-GhecBranchExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Branch 'feature/leaky-config') { 'present' } else { 'MISSING' }
    Write-GhecOk "repo $(_Ch11-JsFull) present — SECRETS-MANIFEST.md $manifest, feature/leaky-config $branch"
  } else {
    Write-GhecInfo "repo $(_Ch11-JsFull) not provisioned"
  }
}
