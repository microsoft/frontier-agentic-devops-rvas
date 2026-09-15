#!/usr/bin/env pwsh
#
# PowerShell twin for the ghas-admin-03 and ghas-admin-04 CodeQL fixture.
# Teardown removes fixture artifacts, never the repository.

[CmdletBinding()]
param(
  [ValidateSet('provision', 'status', 'teardown', 'render-workflow', 'render-fix')]
  [string]$Action = 'provision',
  [string]$Org,
  [string]$Repo = 'ghas-admin-03-04-codeql-live-lab',
  [string]$Ref = 'v20.0.0',
  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'

$WorkflowBranch = 'codeql/advanced-setup'
$VulnerableBranch = 'codeql/vulnerable-pr'
$CoveragePath = 'tools/ghas_codeql_coverage_probe.py'
$VulnerablePath = 'routes/ghasCodeqlLookup.js'
$IssueTitle = 'GHAS CodeQL live lab: coverage, Autofix, and merge enforcement'
$PrTitle = 'Add insecure product lookup for CodeQL enforcement test'

function Get-WorkflowContent {
@'
name: CodeQL

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  merge_group:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:

permissions: {}

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    strategy:
      fail-fast: false
      matrix:
        language:
          - javascript-typescript
          - python
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v4
        with:
          languages: ${{ matrix.language }}
          build-mode: none
          queries: security-extended
      - name: Perform CodeQL analysis
        uses: github/codeql-action/analyze@v4
        with:
          category: /language:${{ matrix.language }}
'@
}

function Get-CoverageProbe {
@'
"""Small source file used to verify that CodeQL covers the tools root."""


def normalized_name(value: str) -> str:
    return value.strip().lower()
'@
}

function Get-Vulnerability {
@'
// ghas-admin-04 fixture. Deliberately vulnerable. Do not ship.
const express = require('express')
const sqlite3 = require('sqlite3')
const router = express.Router()

router.get('/ghas-codeql-lookup', (req, res) => {
  const db = new sqlite3.Database(':memory:')
  const query = "SELECT * FROM Products WHERE name = '" + req.query.name + "'"
  db.all(query, (err, rows) => {
    res.send('<h1>Results for ' + req.query.name + '</h1>' + JSON.stringify(rows || err))
  })
})

module.exports = router
'@
}

function Get-Fix {
@'
const express = require('express')
const sqlite3 = require('sqlite3')
const router = express.Router()

router.get('/ghas-codeql-lookup', (req, res) => {
  const db = new sqlite3.Database(':memory:')
  db.all(
    'SELECT * FROM Products WHERE name = ?',
    [req.query.name],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: 'lookup failed' })
        return
      }
      res.json({ query: req.query.name, rows })
    }
  )
})

module.exports = router
'@
}

function Get-IssueBody {
@"
This fixture supports ``ghas-admin-03`` and ``ghas-admin-04``.

Repository state:

- ``main`` contains ``$CoveragePath`` and no advanced CodeQL workflow.
- ``$WorkflowBranch`` contains the advanced-setup recovery workflow.
- ``$VulnerableBranch`` contains ``$VulnerablePath``.
- The open pull request from ``$VulnerableBranch`` is the merge-enforcement test.

Start with CodeQL default setup. Configure JavaScript/TypeScript only for the first
run, find the missing Python coverage, add Python, and run CodeQL again.

Keep the vulnerable pull request unchanged during ghas-admin-03. In ghas-admin-04,
activate Require code scanning results, prove that the pull request is blocked, then
replace ``$VulnerablePath`` with the output of:

``````powershell
pwsh -File provision.ps1 -Action render-fix
``````

A workflow stored only on ``$WorkflowBranch`` is a recovery fixture. It does not
count as a live scan until an administrator restores it to ``main`` and completes a
run.
"@
}

if ($Action -eq 'render-workflow') {
  Get-WorkflowContent
  exit 0
}

if ($Action -eq 'render-fix') {
  Get-Fix
  exit 0
}

if (-not $Org) {
  throw "-Org is required for $Action"
}

$FullRepo = "$Org/$Repo"

foreach ($Tool in @('gh', 'git')) {
  if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
    throw "Required tool not found: $Tool"
  }
}

function Invoke-Gh {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  $Output = & gh @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "gh command failed: gh $($Arguments -join ' ')"
  }
  return $Output
}

function Test-Repo {
  & gh repo view $FullRepo *> $null
  return $LASTEXITCODE -eq 0
}

function New-RepoIfMissing {
  if (Test-Repo) {
    Write-Host "Repository exists: $FullRepo"
    return
  }

  if ($DryRun) {
    Write-Host "DRY RUN: import juice-shop/juice-shop@$Ref into $FullRepo"
    return
  }

  $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "ghas-codeql-$([guid]::NewGuid())"
  try {
    Invoke-Gh --version *> $null
    & git clone --quiet --depth 1 --branch $Ref https://github.com/juice-shop/juice-shop.git $TempDir
    if ($LASTEXITCODE -ne 0) { throw 'git clone failed' }
    & git -C $TempDir checkout -q -B main
    if ($LASTEXITCODE -ne 0) { throw 'git checkout failed' }
    & git -C $TempDir remote remove origin
    if ($LASTEXITCODE -ne 0) { throw 'git remote remove failed' }
    Invoke-Gh repo create $FullRepo --public --source $TempDir --remote origin --push `
      --description 'GHAS CodeQL live administration lab' *> $null
  } finally {
    if (Test-Path -LiteralPath $TempDir) {
      Remove-Item -LiteralPath $TempDir -Recurse -Force
    }
  }
}

function Enable-SecurityFeatures {
  if ($DryRun) {
    Write-Host "DRY RUN: enable Actions and available security features on $FullRepo"
    return
  }

  Invoke-Gh api -X PUT "repos/$FullRepo/actions/permissions" `
    -F 'enabled=true' -f 'allowed_actions=all' *> $null

  & gh api -X PATCH "repos/$FullRepo" `
    -F 'security_and_analysis[advanced_security][status]=enabled' *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Warning 'GitHub did not accept the advanced-security update. Public repositories can still use CodeQL.'
  }
}

function Test-Branch {
  param([string]$Branch)
  & gh api "repos/$FullRepo/git/ref/heads/$Branch" *> $null
  return $LASTEXITCODE -eq 0
}

function Add-Branch {
  param([string]$Branch)
  if ($DryRun) {
    Write-Host "DRY RUN: ensure branch $Branch from main"
    return
  }

  if (Test-Branch $Branch) {
    Write-Host "Branch exists: $Branch"
    return
  }

  $MainSha = Invoke-Gh api "repos/$FullRepo/git/ref/heads/main" --jq '.object.sha'
  Invoke-Gh api -X POST "repos/$FullRepo/git/refs" `
    -f "ref=refs/heads/$Branch" -f "sha=$MainSha" *> $null
}

function Set-RepoFile {
  param(
    [string]$Branch,
    [string]$Path,
    [string]$Message,
    [string]$Content
  )

  if ($DryRun) {
    Write-Host "DRY RUN: put $Path on $Branch"
    return
  }

  $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $Sha = & gh api "repos/$FullRepo/contents/$Path`?ref=$Branch" --jq '.sha' 2>$null
  $Arguments = @(
    'api', '-X', 'PUT', "repos/$FullRepo/contents/$Path",
    '-f', "message=$Message", '-f', "content=$Encoded", '-f', "branch=$Branch"
  )
  if ($LASTEXITCODE -eq 0 -and $Sha) {
    $Arguments += @('-f', "sha=$Sha")
  }
  Invoke-Gh @Arguments *> $null
}

function Get-IssueNumber {
  $Filter = ".[] | select(.title == `"$IssueTitle`") | .number"
  return @(
    Invoke-Gh issue list --repo $FullRepo --state all --limit 100 `
      --json number,title --jq $Filter
  ) | Select-Object -First 1
}

function Add-Issue {
  if ($DryRun) { return 0 }
  $Number = Get-IssueNumber
  if ($Number) { return $Number }

  return [int](Invoke-Gh api -X POST "repos/$FullRepo/issues" `
    -f "title=$IssueTitle" -f "body=$(Get-IssueBody)" --jq '.number')
}

function Get-PrNumber {
  return (Invoke-Gh pr list --repo $FullRepo --state all --head $VulnerableBranch `
    --json number --jq '.[0].number // empty')
}

function Add-Pr {
  param([int]$IssueNumber)
  if ($DryRun) { return 0 }
  $Number = Get-PrNumber
  if ($Number) { return $Number }

  return [int](Invoke-Gh api -X POST "repos/$FullRepo/pulls" `
    -f 'base=main' -f "head=$VulnerableBranch" -f "title=$PrTitle" `
    -f "body=Prepared vulnerable pull request for ghas-admin-04. Fixture details: #$IssueNumber" `
    --jq '.number')
}

function Remove-RepoFile {
  param([string]$Branch, [string]$Path, [string]$Message)
  $Sha = & gh api "repos/$FullRepo/contents/$Path`?ref=$Branch" --jq '.sha' 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $Sha) { return }
  if ($DryRun) {
    Write-Host "DRY RUN: delete $Branch`:$Path"
    return
  }
  Invoke-Gh api -X DELETE "repos/$FullRepo/contents/$Path" `
    -f "message=$Message" -f "sha=$Sha" -f "branch=$Branch" *> $null
}

function Remove-Branch {
  param([string]$Branch)
  if (-not (Test-Branch $Branch)) { return }
  if ($DryRun) {
    Write-Host "DRY RUN: delete branch $Branch"
    return
  }
  Invoke-Gh api -X DELETE "repos/$FullRepo/git/refs/heads/$Branch" *> $null
}

function Show-Status {
  if (-not (Test-Repo)) {
    throw "Repository missing: $FullRepo"
  }

  $Missing = [System.Collections.Generic.List[string]]::new()
  Write-Host "Repository: $FullRepo"
  foreach ($Branch in @('main', $WorkflowBranch, $VulnerableBranch)) {
    $State = if (Test-Branch $Branch) { 'present' } else { 'MISSING' }
    Write-Host "branch $Branch`: $State"
    if ($State -eq 'MISSING') { $Missing.Add("branch $Branch") }
  }

  $Items = @(
    @{ Branch = 'main'; Path = $CoveragePath },
    @{ Branch = $WorkflowBranch; Path = '.github/workflows/codeql.yml' },
    @{ Branch = $VulnerableBranch; Path = $VulnerablePath }
  )
  foreach ($Item in $Items) {
    & gh api "repos/$FullRepo/contents/$($Item.Path)`?ref=$($Item.Branch)" *> $null
    $State = if ($LASTEXITCODE -eq 0) { 'present' } else { 'MISSING' }
    Write-Host "$($Item.Branch):$($Item.Path): $State"
    if ($State -eq 'MISSING') { $Missing.Add("$($Item.Branch):$($Item.Path)") }
  }

  $IssueNumber = Get-IssueNumber
  $PrNumber = Get-PrNumber
  Write-Host "issue: $(if ($IssueNumber) { $IssueNumber } else { 'MISSING' })"
  Write-Host "pull request: $(if ($PrNumber) { $PrNumber } else { 'MISSING' })"
  if (-not $IssueNumber) { $Missing.Add('issue') }
  if (-not $PrNumber) { $Missing.Add('pull request') }
  if ($Missing.Count -gt 0) {
    throw "Fixture is incomplete: $($Missing -join ', ')"
  }
}

function Invoke-Provision {
  New-RepoIfMissing
  if (-not $DryRun -and -not (Test-Repo)) { throw "Repository missing after import: $FullRepo" }
  Enable-SecurityFeatures

  Set-RepoFile -Branch main -Path $CoveragePath `
    -Message 'Add CodeQL coverage probe for GHAS admin lab' -Content (Get-CoverageProbe)

  Add-Branch $WorkflowBranch
  Set-RepoFile -Branch $WorkflowBranch -Path '.github/workflows/codeql.yml' `
    -Message 'Prepare CodeQL advanced setup recovery workflow' -Content (Get-WorkflowContent)

  Add-Branch $VulnerableBranch
  Set-RepoFile -Branch $VulnerableBranch -Path $VulnerablePath `
    -Message 'Add insecure lookup for CodeQL merge test' -Content (Get-Vulnerability)

  $IssueNumber = Add-Issue
  $PrNumber = Add-Pr -IssueNumber $IssueNumber

  Write-Host "Fixture ready: $FullRepo"
  Write-Host "Issue: $IssueNumber"
  Write-Host "Prepared pull request: $PrNumber"
  Write-Host 'Start with CodeQL default setup on main.'
}

function Invoke-Teardown {
  if (-not (Test-Repo)) {
    Write-Host "Repository missing: $FullRepo"
    return
  }
  if (-not $Yes) {
    throw 'Teardown requires -Yes because it removes fixture branches and files.'
  }

  $PrNumber = Get-PrNumber
  $IssueNumber = Get-IssueNumber

  if ($PrNumber) {
    if ($DryRun) { Write-Host "DRY RUN: close pull request $PrNumber" }
    else { Invoke-Gh pr close $PrNumber --repo $FullRepo *> $null }
  }

  Remove-Branch $VulnerableBranch
  Remove-Branch $WorkflowBranch
  Remove-RepoFile -Branch main -Path $CoveragePath `
    -Message 'Remove GHAS CodeQL coverage probe'

  if ($IssueNumber) {
    if ($DryRun) { Write-Host "DRY RUN: close issue $IssueNumber" }
    else { Invoke-Gh issue close $IssueNumber --repo $FullRepo *> $null }
  }

  Write-Host "Fixture artifacts removed. Repository preserved: $FullRepo"
}

switch ($Action) {
  'provision' { Invoke-Provision }
  'status' { Show-Status }
  'teardown' { Invoke-Teardown }
}
