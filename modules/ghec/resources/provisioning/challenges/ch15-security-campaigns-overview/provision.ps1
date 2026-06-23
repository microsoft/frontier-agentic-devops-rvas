# challenges/ch15-security-campaigns-overview/provision.ps1
#
# PowerShell twin of ch15 — multi-tool alert corpus over a Juice Shop import.

$Global:WthJsRepo = "wth-$($Global:WthChid)-juice-shop"
$Global:WthAwsKeyId  = 'AKIAIOSFODNN7EXAMPLE'
$Global:WthAwsSecret = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'

function _Ch15-JsFull { "$($Global:WthOrg)/$($Global:WthJsRepo)" }

function _Ch15-SeedCodeql {
  Write-WthStep 'seeding CodeQL workflow (code scanning corpus)'
  $wf = @'
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 6 * * 1"
permissions:
  contents: read
  security-events: write
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3
'@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/workflows/codeql.yml' `
    -Message 'Add CodeQL advanced setup (javascript-typescript)' -Content $wf
}

function _Ch15-SeedDependabot {
  Write-WthStep 'seeding Dependabot config (Dependabot alert corpus)'
  $cfg = @'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
'@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/dependabot.yml' `
    -Message 'Add Dependabot config' -Content $cfg
}

function _Ch15-SeedSecret {
  Write-WthStep 'planting one non-live secret (secret scanning corpus)'
  $creds = @"
; wth-ch15 planted NON-LIVE test secret — see SECURITY-CORPUS.md
[default]
aws_access_key_id = $($Global:WthAwsKeyId)
aws_secret_access_key = $($Global:WthAwsSecret)
"@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'config/aws-credentials.ini' `
    -Message 'Add legacy AWS uploader credentials (seed)' -Content $creds

  $corpus = @'
# SECURITY-CORPUS — wth-ch15

This repo deliberately produces alerts across THREE tools so you can build and
manage a security campaign end to end:

| Tool | Source | What to expect |
|------|--------|----------------|
| Code scanning (CodeQL) | `.github/workflows/codeql.yml` + Juice Shop source | SQLi, XSS, and more |
| Dependabot | `.github/dependabot.yml` + Juice Shop `package.json` | vulnerable npm deps |
| Secret scanning | `config/aws-credentials.ini` | one planted NON-LIVE AWS key |

Use these to scope a campaign, assign owners, and track burn-down.
'@
  Set-WthFile -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'SECURITY-CORPUS.md' `
    -Message 'Add multi-tool alert corpus manifest' -Content $corpus
}

# ===========================================================================
function Invoke-WthProvision {
  Import-WthJuiceShop -Org $Global:WthOrg -Repo $Global:WthJsRepo -Ref $Global:WthJuiceShopRef
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo))) {
    Stop-Wth "repo $(_Ch15-JsFull) missing after import — aborting seed"
  }
  _Ch15-SeedCodeql
  _Ch15-SeedDependabot
  _Ch15-SeedSecret
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - enable code scanning, Dependabot, and secret scanning in Security settings'
  Write-WthInfo '  - create a security campaign and scope it across the three alert sources'
  Write-WthWarn 'manual: enabling the three scanners is the learning — not auto-enabled.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthJsRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthJsRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthJsRepo) {
    $codeql = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/workflows/codeql.yml') { 'present' } else { 'MISSING' }
    $dependabot = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path '.github/dependabot.yml') { 'present' } else { 'MISSING' }
    $secret = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthJsRepo -Path 'config/aws-credentials.ini') { 'present' } else { 'MISSING' }
    Write-WthOk "repo $(_Ch15-JsFull) present — codeql $codeql, dependabot $dependabot, secret $secret"
  } else {
    Write-WthInfo "repo $(_Ch15-JsFull) not provisioned"
  }
}
