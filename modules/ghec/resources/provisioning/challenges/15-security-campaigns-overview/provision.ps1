# challenges/ch15-security-campaigns-overview/provision.ps1
#
# PowerShell twin of ch15 — multi-tool alert corpus over a Juice Shop import.

$Global:GhecJsRepo = "ghec-$($Global:GhecChid)-juice-shop"
$Global:GhecAwsKeyId  = 'AKIAIOSFODNN7EXAMPLE'
$Global:GhecAwsSecret = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'

function _Ch15-JsFull { "$($Global:GhecOrg)/$($Global:GhecJsRepo)" }

function _Ch15-SeedCodeql {
  Write-GhecStep 'seeding CodeQL workflow (code scanning corpus)'
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
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/workflows/codeql.yml' `
    -Message 'Add CodeQL advanced setup (javascript-typescript)' -Content $wf
}

function _Ch15-SeedDependabot {
  Write-GhecStep 'seeding Dependabot config (Dependabot alert corpus)'
  $cfg = @'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/dependabot.yml' `
    -Message 'Add Dependabot config' -Content $cfg
}

function _Ch15-SeedSecret {
  Write-GhecStep 'planting one non-live secret (secret scanning corpus)'
  $creds = @"
; ghec-ch15 planted NON-LIVE test secret — see SECURITY-CORPUS.md
[default]
aws_access_key_id = $($Global:GhecAwsKeyId)
aws_secret_access_key = $($Global:GhecAwsSecret)
"@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'config/aws-credentials.ini' `
    -Message 'Add legacy AWS uploader credentials (seed)' -Content $creds

  $corpus = @'
# SECURITY-CORPUS — ghec-ch15

This repo deliberately produces alerts across THREE tools so you can build and
manage a security campaign end to end:

| Tool | Source | What to expect |
|------|--------|----------------|
| Code scanning (CodeQL) | `.github/workflows/codeql.yml` + Juice Shop source | SQLi, XSS, and more |
| Dependabot | `.github/dependabot.yml` + Juice Shop `package.json` | vulnerable npm deps |
| Secret scanning | `config/aws-credentials.ini` | one planted NON-LIVE AWS key |

Use these to scope a campaign, assign owners, and track burn-down.
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'SECURITY-CORPUS.md' `
    -Message 'Add multi-tool alert corpus manifest' -Content $corpus
}

# ===========================================================================
function Invoke-GhecProvision {
  Import-GhecJuiceShop -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Ref $Global:GhecJuiceShopRef
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo))) {
    Stop-Ghec "repo $(_Ch15-JsFull) missing after import — aborting seed"
  }
  _Ch15-SeedCodeql
  _Ch15-SeedDependabot
  _Ch15-SeedSecret
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - enable code scanning, Dependabot, and secret scanning in Security settings'
  Write-GhecInfo '  - create a security campaign and scope it across the three alert sources'
  Write-GhecWarn 'manual: enabling the three scanners is the learning — not auto-enabled.'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecJsRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecJsRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo) {
    $codeql = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/workflows/codeql.yml') { 'present' } else { 'MISSING' }
    $dependabot = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path '.github/dependabot.yml') { 'present' } else { 'MISSING' }
    $secret = if (Test-GhecFileExists -Org $Global:GhecOrg -Repo $Global:GhecJsRepo -Path 'config/aws-credentials.ini') { 'present' } else { 'MISSING' }
    Write-GhecOk "repo $(_Ch15-JsFull) present — codeql $codeql, dependabot $dependabot, secret $secret"
  } else {
    Write-GhecInfo "repo $(_Ch15-JsFull) not provisioned"
  }
}
