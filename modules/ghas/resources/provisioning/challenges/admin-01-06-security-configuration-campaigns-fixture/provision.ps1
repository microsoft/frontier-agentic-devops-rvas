#!/usr/bin/env pwsh
#
# Shared fixture for ghas-admin-01 and ghas-admin-06.
# Imports OWASP Juice Shop at a pinned tag and seeds a mixed GHAS alert corpus.

[CmdletBinding()]
param(
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidateSet('provision', 'status', 'teardown')]
  [string]$Command,
  [Parameter(Mandatory = $true)]
  [string]$Org,
  [string]$Ref = 'v20.0.0',
  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$Prefix = 'ghas-admin-01-06-'
$Repo = "${Prefix}security-operations"
$ConfigBranch = 'ghas-admin-01-detachment-repair'
$CampaignBranch = 'ghas-admin-06-campaign-remediation'
$Upstream = 'https://github.com/juice-shop/juice-shop.git'
$AwsKeyId = 'AKIA' + 'IOSFODNN7EXAMPLE'
$AwsSecret = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLE' + 'KEY'

function Write-FixtureLog {
  param([string]$Message)
  Write-Host "[ghas-admin-01-06] $Message"
}

function Stop-Fixture {
  param([string]$Message)
  throw "[ghas-admin-01-06] $Message"
}

function Test-Repo {
  gh repo view "$Org/$Repo" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-Branch {
  param([string]$Branch)
  gh api "repos/$Org/$Repo/git/ref/heads/$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Test-RepoFile {
  param([string]$Path, [string]$Branch = 'main')
  gh api "repos/$Org/$Repo/contents/$Path`?ref=$Branch" 2>$null | Out-Null
  return ($LASTEXITCODE -eq 0)
}

function Set-RepoFile {
  param(
    [string]$Path,
    [string]$Message,
    [string]$Content,
    [string]$Branch = 'main'
  )
  if (Test-RepoFile -Path $Path -Branch $Branch) {
    Write-FixtureLog "file $Path on $Branch exists; skipping"
    return
  }
  if ($DryRun) {
    Write-FixtureLog "would create $Path on $Branch"
    return
  }
  $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  gh api -X PUT "repos/$Org/$Repo/contents/$Path" `
    -f "message=$Message" -f "content=$Encoded" -f "branch=$Branch" | Out-Null
}

function New-FixtureBranch {
  param([string]$Branch)
  if (Test-Branch -Branch $Branch) {
    Write-FixtureLog "branch $Branch exists; skipping"
    return
  }
  if ($DryRun) {
    Write-FixtureLog "would create branch $Branch from main"
    return
  }
  $Sha = gh api "repos/$Org/$Repo/git/ref/heads/main" --jq '.object.sha'
  gh api -X POST "repos/$Org/$Repo/git/refs" `
    -f "ref=refs/heads/$Branch" -f "sha=$Sha" | Out-Null
}

function New-FixtureIssue {
  param([string]$Title, [string]$Body)
  $Existing = gh issue list --repo "$Org/$Repo" --state all --limit 100 `
    --json title --jq ".[] | select(.title == `"$Title`") | .title" 2>$null
  if ($Existing -contains $Title) {
    Write-FixtureLog "issue '$Title' exists; skipping"
    return
  }
  if ($DryRun) {
    Write-FixtureLog "would create issue '$Title'"
    return
  }
  gh issue create --repo "$Org/$Repo" --title $Title --body $Body | Out-Null
}

function Import-JuiceShop {
  if (Test-Repo) {
    Write-FixtureLog "repository $Org/$Repo exists; skipping import"
    return
  }
  if ($DryRun) {
    Write-FixtureLog "would import OWASP Juice Shop $Ref into $Org/$Repo"
    return
  }

  $Work = Join-Path ([IO.Path]::GetTempPath()) ("ghas-admin-fixture-" + [guid]::NewGuid().ToString('N'))
  $Source = Join-Path $Work 'src'
  New-Item -ItemType Directory -Path $Work | Out-Null
  try {
    git clone --quiet --depth 1 --branch $Ref $Upstream $Source
    if ($LASTEXITCODE -ne 0) { Stop-Fixture "failed to clone OWASP Juice Shop at $Ref" }
    if (-not (Test-Path -LiteralPath (Join-Path $Source 'LICENSE'))) {
      Stop-Fixture 'upstream LICENSE is missing'
    }

    Remove-Item -LiteralPath (Join-Path $Source '.git') -Recurse -Force
    git -C $Source init --quiet
    git -C $Source symbolic-ref HEAD refs/heads/main
    git -C $Source add -A
    git -C $Source -c user.name='ghas-fixture-bot' `
      -c user.email='ghas-fixture-bot@users.noreply.github.com' `
      commit --quiet -m "Import OWASP Juice Shop $Ref for GHAS admin labs"

    gh repo create "$Org/$Repo" --public `
      --description 'GHAS admin 01 and 06 fixture; safe to delete with its provisioner' 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-FixtureLog 'public repository creation failed; trying private visibility'
      gh repo create "$Org/$Repo" --private `
        --description 'GHAS admin 01 and 06 fixture; safe to delete with its provisioner' | Out-Null
      if ($LASTEXITCODE -ne 0) { Stop-Fixture 'repository creation failed' }
    }

    gh auth setup-git | Out-Null
    git -C $Source remote add origin "https://github.com/$Org/$Repo.git"
    git -C $Source push --quiet -u origin main
    if ($LASTEXITCODE -ne 0) { Stop-Fixture 'initial push failed' }
    Write-FixtureLog "imported OWASP Juice Shop $Ref into $Org/$Repo"
  }
  finally {
    if (Test-Path -LiteralPath $Work) {
      Remove-Item -LiteralPath $Work -Recurse -Force
    }
  }
}

function Add-AlertCorpus {
  $Codeql = @'
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
  $Dependabot = @'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
'@
  $Credentials = @"
; ghas-admin-06 planted NON-LIVE example secret
[default]
aws_access_key_id = $AwsKeyId
aws_secret_access_key = $AwsSecret
"@
  $Manifest = @'
# GHAS admin 01 and 06 alert corpus

This repository is a controlled training fixture.

| Source | Seed |
| --- | --- |
| Code scanning | CodeQL workflow plus OWASP Juice Shop source |
| Dependabot | Dependabot configuration plus the pinned Juice Shop dependency tree |
| Secret scanning | One non-live AWS example key in `config/aws-credentials.ini` |

Use `ghas-admin-01` for security configuration attachment work. Use `ghas-admin-06` for Security Overview, delegated triage, and a live campaign.
'@
  $ConfigNote = @'
# Configuration attachment repair

Use this branch to record the observed attachment state, failure or detachment, repair, final state, and rollout decision for `ghas-admin-01`.
'@
  $CampaignNote = @'
# Campaign remediation

Use this branch for reviewed fixes created during `ghas-admin-06`. Merge at least one alert fix to `main`, then wait for the scan before measuring burn-down.
'@

  Set-RepoFile -Path '.github/workflows/codeql.yml' -Message 'Add CodeQL alert corpus' -Content $Codeql
  Set-RepoFile -Path '.github/dependabot.yml' -Message 'Add Dependabot alert corpus' -Content $Dependabot
  Set-RepoFile -Path 'config/aws-credentials.ini' -Message 'Add non-live secret scanning seed' -Content $Credentials
  Set-RepoFile -Path 'SECURITY-CORPUS.md' -Message 'Document GHAS admin alert corpus' -Content $Manifest

  New-FixtureBranch -Branch $ConfigBranch
  New-FixtureBranch -Branch $CampaignBranch
  Set-RepoFile -Path 'GHAS-ADMIN-01-DETACHMENT-REPAIR.md' `
    -Message 'Add configuration repair worksheet' -Content $ConfigNote -Branch $ConfigBranch
  Set-RepoFile -Path 'GHAS-ADMIN-06-CAMPAIGN-REMEDIATION.md' `
    -Message 'Add campaign remediation worksheet' -Content $CampaignNote -Branch $CampaignBranch

  $Expiry = (Get-Date).ToUniversalTime().AddDays(30).ToString('yyyy-MM-dd')
  New-FixtureIssue -Title 'ghas-admin-01: configuration attachment repair' -Body @"
Record the live configuration ID, attachment status history, failure or detachment, repair, and final enforce-or-rollback decision.

Repository: $Org/$Repo
Repair branch: $ConfigBranch
"@
  New-FixtureIssue -Title 'ghas-admin-06: expiring exception and campaign burn-down' -Body @"
Record the published campaign URL, developer access result, delegated decision, and measured burn-down.

Repository: $Org/$Repo
Remediation branch: $CampaignBranch
Exception expiry: $Expiry
Replace this template date if the exception is created later.
"@
}

function Invoke-Provision {
  Import-JuiceShop
  if ((-not $DryRun) -and (-not (Test-Repo))) {
    Stop-Fixture 'repository is missing after import'
  }
  Add-AlertCorpus
  Write-FixtureLog 'next: enable the approved security features and wait for the alert corpus'
  Write-FixtureLog 'next: run ghas-admin-01 before ghas-admin-06'
}

function Get-FixtureStatus {
  if (-not (Test-Repo)) {
    Stop-Fixture "repository $Org/$Repo is absent"
  }
  $Missing = [System.Collections.Generic.List[string]]::new()
  foreach ($Item in @(
    @{ Path = '.github/workflows/codeql.yml'; Branch = 'main' },
    @{ Path = '.github/dependabot.yml'; Branch = 'main' },
    @{ Path = 'config/aws-credentials.ini'; Branch = 'main' },
    @{ Path = 'SECURITY-CORPUS.md'; Branch = 'main' },
    @{ Path = 'GHAS-ADMIN-01-DETACHMENT-REPAIR.md'; Branch = $ConfigBranch },
    @{ Path = 'GHAS-ADMIN-06-CAMPAIGN-REMEDIATION.md'; Branch = $CampaignBranch }
  )) {
    if (-not (Test-RepoFile -Path $Item.Path -Branch $Item.Branch)) {
      $Missing.Add("$($Item.Branch):$($Item.Path)")
    }
  }
  foreach ($Branch in @($ConfigBranch, $CampaignBranch)) {
    if (-not (Test-Branch -Branch $Branch)) { $Missing.Add("branch $Branch") }
  }
  foreach ($Title in @(
    'ghas-admin-01: configuration attachment repair',
    'ghas-admin-06: expiring exception and campaign burn-down'
  )) {
    $Existing = gh issue list --repo "$Org/$Repo" --state all --limit 100 `
      --json title --jq ".[] | select(.title == `"$Title`") | .title" 2>$null
    if ($Existing -notcontains $Title) { $Missing.Add("issue '$Title'") }
  }
  if ($Missing.Count -gt 0) {
    Stop-Fixture "fixture is incomplete: $($Missing -join ', ')"
  }
  Write-FixtureLog "fixture ready: $Org/$Repo"
}

function Remove-Fixture {
  if (-not (Test-Repo)) {
    Write-FixtureLog "repository $Org/$Repo is absent"
    return
  }
  if (-not $Yes) {
    Stop-Fixture 'teardown requires -Yes'
  }
  if ($DryRun) {
    Write-FixtureLog "would delete $Org/$Repo"
    return
  }
  if (-not $Repo.StartsWith($Prefix, [StringComparison]::Ordinal)) {
    Stop-Fixture "unsafe repository name: $Repo"
  }
  gh repo delete "$Org/$Repo" --yes
  if ($LASTEXITCODE -ne 0) { Stop-Fixture 'repository deletion failed' }
  Write-FixtureLog "deleted $Org/$Repo"
}

if (-not $Repo.StartsWith($Prefix, [StringComparison]::Ordinal)) {
  Stop-Fixture "unsafe repository name: $Repo"
}

if (-not $DryRun) {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Stop-Fixture 'gh is required' }
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Stop-Fixture 'git is required' }
  gh auth status 2>$null | Out-Null
  if ($LASTEXITCODE -ne 0) { Stop-Fixture 'authenticate gh before running this fixture' }
}

switch ($Command) {
  'provision' { Invoke-Provision }
  'status' { Get-FixtureStatus }
  'teardown' { Remove-Fixture }
}
