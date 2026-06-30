# ghas-00 imports OWASP Juice Shop into the participant/organizer-owned org,
# seeds GHAS config, and enables repo-level security features where allowed.

$Global:WthGhasRepo = $Global:WthRepo
$Global:WthGhasResourcesDir = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $ScriptDir))))) 'modules/ghas/resources/github'

function _Ghas-Full { "$($Global:WthOrg)/$($Global:WthGhasRepo)" }

function _Ghas-ReadResource {
  param([string]$RelativePath)
  $file = Join-Path $Global:WthGhasResourcesDir $RelativePath
  if (-not (Test-Path -LiteralPath $file)) { Stop-Wth "missing GHAS resource fixture: $file" }
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
    Invoke-WthMutation -Plan $Plan -Action $Action
    if (-not $Global:WthDryRun) { Write-WthOk $Description }
  } catch {
    Write-WthWarn "$Description failed — check org/repo permissions or enable it manually in Settings → Code security and analysis"
  }
}

function _Ghas-EnableFeatures {
  Write-WthStep 'enabling GHAS repository features where available'

  _Ghas-MutationSoft -Description 'Actions enabled' -Plan "gh api PUT actions permissions for $($Global:WthGhasRepo)" -Action {
    gh api -X PUT "repos/$($Global:WthOrg)/$($Global:WthGhasRepo)/actions/permissions" `
      -F enabled=true -f allowed_actions=all
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }

  _Ghas-MutationSoft -Description 'advanced security, secret scanning, and push protection enabled' -Plan "gh api PATCH security_and_analysis for $($Global:WthGhasRepo)" -Action {
    gh api -X PATCH "repos/$($Global:WthOrg)/$($Global:WthGhasRepo)" `
      -F 'security_and_analysis[advanced_security][status]=enabled' `
      -F 'security_and_analysis[secret_scanning][status]=enabled' `
      -F 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }

  _Ghas-MutationSoft -Description 'Dependabot alerts enabled' -Plan "gh api PUT vulnerability-alerts for $($Global:WthGhasRepo)" -Action {
    gh api -X PUT "repos/$($Global:WthOrg)/$($Global:WthGhasRepo)/vulnerability-alerts"
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }

  _Ghas-MutationSoft -Description 'Dependabot security updates enabled' -Plan "gh api PUT automated-security-fixes for $($Global:WthGhasRepo)" -Action {
    gh api -X PUT "repos/$($Global:WthOrg)/$($Global:WthGhasRepo)/automated-security-fixes"
    if ($LASTEXITCODE -ne 0) { throw 'gh api failed' }
  }
}

function _Ghas-SeedConfigs {
  Write-WthStep 'seeding GHAS config files'
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Path '.github/workflows/codeql.yml' `
    -Message 'Add GHAS CodeQL workflow' -Content (_Ghas-ReadResource 'workflows/codeql.yml')
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Path '.github/codeql/codeql-config.yml' `
    -Message 'Add GHAS CodeQL configuration' -Content (_Ghas-ReadResource 'codeql/codeql-config.yml')
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Path '.github/dependabot.yml' `
    -Message 'Add Dependabot configuration' -Content (_Ghas-DependabotForImportedRepo)
}

function _Ghas-TriggerCodeql {
  Write-WthStep 'triggering first CodeQL scan'
  _Ghas-MutationSoft -Description 'CodeQL workflow dispatch queued' -Plan "gh workflow run codeql.yml --repo $(_Ghas-Full) --ref main" -Action {
    gh workflow run codeql.yml --repo (_Ghas-Full) --ref main
    if ($LASTEXITCODE -ne 0) { throw 'gh workflow run failed' }
  }
}

function Invoke-WthProvision {
  Import-WthJuiceShop -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Ref $Global:WthJuiceShopRef
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthGhasRepo))) {
    Stop-Wth "repo $(_Ghas-Full) missing after import — aborting GHAS setup"
  }

  _Ghas-EnableFeatures
  _Ghas-SeedConfigs
  _Ghas-TriggerCodeql

  Write-Host ''
  Write-WthInfo 'Next steps:'
  Write-WthInfo "  - open https://github.com/$($Global:WthOrg)/$($Global:WthGhasRepo)/settings/security_analysis and confirm all requested GHAS features are enabled"
  Write-WthInfo "  - manually add any participants or teams that need access to $(_Ghas-Full)"
  Write-WthInfo "  - have each participant clone $(_Ghas-Full) and push a personal/team branch"
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthGhasRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthGhasRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthGhasRepo) {
    $codeql = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Path '.github/workflows/codeql.yml') { 'present' } else { 'MISSING' }
    $config = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Path '.github/codeql/codeql-config.yml') { 'present' } else { 'MISSING' }
    $dependabot = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthGhasRepo -Path '.github/dependabot.yml') { 'present' } else { 'MISSING' }
    $visibility = gh repo view (_Ghas-Full) --json visibility --jq '.visibility' 2>$null
    if (-not $visibility) { $visibility = 'unknown' }
    $security = gh api "repos/$($Global:WthOrg)/$($Global:WthGhasRepo)" --jq '.security_and_analysis // {}' 2>$null
    if (-not $security) { $security = '{}' }
    Write-WthOk "repo $(_Ghas-Full) present ($visibility) — codeql.yml $codeql, codeql config $config, dependabot.yml $dependabot"
    Write-WthInfo "security_and_analysis: $security"
  } else {
    Write-WthInfo "repo $(_Ghas-Full) not provisioned"
  }
}
