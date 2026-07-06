# ghas-00 imports OWASP Juice Shop into the participant/organizer-owned org,
# seeds GHAS config, and enables repo-level security features where allowed.

$Global:GhecGhasRepo = $Global:GhecRepo
$Global:GhecGhasResourcesDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))))) 'modules/ghas/resources/github'

function _Ghas-Full { "$($Global:GhecOrg)/$($Global:GhecGhasRepo)" }

function _Ghas-ReadResource {
  param([string]$RelativePath)
  $file = Join-Path $Global:GhecGhasResourcesDir $RelativePath
  if (-not (Test-Path -LiteralPath $file)) { Stop-Ghec "missing GHAS resource fixture: $file" }
  return (Get-Content -LiteralPath $file -Raw)
}

function _Ghas-DependabotForImportedRepo {
  # The curriculum repo uses app/ as a lazy Juice Shop symlink. The provisioned
  # GHAS target is a fresh Juice Shop import, so npm manifests live at repo root.
  return ((_Ghas-ReadResource 'dependabot.yml') -replace 'directory: "/app"', 'directory: "/"')
}

function _Ghas-MutationSoft {
  param([string]$Description, [string]$Plan, [scriptblock]$Action)
  try {
    Invoke-GhecMutation -Plan $Plan -Action $Action
    if (-not $Global:GhecDryRun) { Write-GhecOk $Description }
  } catch {
    Write-GhecWarn "$Description failed — check org/repo permissions or enable it manually in Settings → Code security and analysis"
  }
}

function _Ghas-EnableFeatures {
  Write-GhecStep 'enabling GHAS repository features where available'

  _Ghas-MutationSoft -Description 'Actions enabled' -Plan "gh api PUT actions permissions for $($Global:GhecGhasRepo)" -Action {
    gh api -X PUT "repos/$($Global:GhecOrg)/$($Global:GhecGhasRepo)/actions/permissions" `
      -F enabled=true -f allowed_actions=all
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }

  _Ghas-MutationSoft -Description 'advanced security, secret scanning, and push protection enabled' -Plan "gh api PATCH security_and_analysis for $($Global:GhecGhasRepo)" -Action {
    gh api -X PATCH "repos/$($Global:GhecOrg)/$($Global:GhecGhasRepo)" `
      -F 'security_and_analysis[advanced_security][status]=enabled' `
      -F 'security_and_analysis[secret_scanning][status]=enabled' `
      -F 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }

  _Ghas-MutationSoft -Description 'Dependabot alerts enabled' -Plan "gh api PUT vulnerability-alerts for $($Global:GhecGhasRepo)" -Action {
    gh api -X PUT "repos/$($Global:GhecOrg)/$($Global:GhecGhasRepo)/vulnerability-alerts"
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }

  _Ghas-MutationSoft -Description 'Dependabot security updates enabled' -Plan "gh api PUT automated-security-fixes for $($Global:GhecGhasRepo)" -Action {
    gh api -X PUT "repos/$($Global:GhecOrg)/$($Global:GhecGhasRepo)/automated-security-fixes"
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }
}

function _Ghas-SeedConfigs {
  Write-GhecStep 'seeding GHAS config files'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Path '.github/workflows/codeql.yml' `
    -Message 'Add GHAS CodeQL workflow' -Content (_Ghas-ReadResource 'workflows/codeql.yml')
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Path '.github/codeql/codeql-config.yml' `
    -Message 'Add GHAS CodeQL configuration' -Content (_Ghas-ReadResource 'codeql/codeql-config.yml')
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Path '.github/dependabot.yml' `
    -Message 'Add Dependabot configuration' -Content (_Ghas-DependabotForImportedRepo)
}

function _Ghas-TriggerCodeql {
  Write-GhecStep 'triggering first CodeQL scan'
  _Ghas-MutationSoft -Description 'CodeQL workflow dispatch queued' -Plan "gh workflow run codeql.yml --repo $(_Ghas-Full) --ref main" -Action {
    gh workflow run codeql.yml --repo (_Ghas-Full) --ref main
    if ($LASTEXITCODE -ne 0) { throw 'gh workflow run failed' }
  }
}

function Invoke-GhecProvision {
  Import-GhecJuiceShop -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Ref $Global:GhecJuiceShopRef
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo))) {
    Stop-Ghec "repo $(_Ghas-Full) missing after import — aborting GHAS setup"
  }

  _Ghas-EnableFeatures
  _Ghas-SeedConfigs
  _Ghas-TriggerCodeql

  Write-Host ''
  Write-GhecInfo 'Next steps:'
  Write-GhecInfo "  - open https://github.com/$($Global:GhecOrg)/$($Global:GhecGhasRepo)/settings/security_analysis and confirm all requested GHAS features are enabled"
  Write-GhecInfo "  - manually add any participants or teams that need access to $(_Ghas-Full)"
  Write-GhecInfo "  - have each participant clone $(_Ghas-Full) and push a personal/team branch"
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecGhasRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo) {
    $codeql = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Path '.github/workflows/codeql.yml') { 'present' } else { 'MISSING' }
    $config = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Path '.github/codeql/codeql-config.yml') { 'present' } else { 'MISSING' }
    $dependabot = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecGhasRepo -Path '.github/dependabot.yml') { 'present' } else { 'MISSING' }
    $visibility = gh repo view (_Ghas-Full) --json visibility --jq '.visibility' 2>$null
    if (-not $visibility) { $visibility = 'unknown' }
    $security = gh api "repos/$($Global:GhecOrg)/$($Global:GhecGhasRepo)" --jq '.security_and_analysis // {}' 2>$null
    if (-not $security) { $security = '{}' }
    Write-GhecOk "repo $(_Ghas-Full) present ($visibility) — codeql.yml $codeql, codeql config $config, dependabot.yml $dependabot"
    Write-GhecInfo "security_and_analysis: $security"
  } else {
    Write-GhecInfo "repo $(_Ghas-Full) not provisioned"
  }
}
