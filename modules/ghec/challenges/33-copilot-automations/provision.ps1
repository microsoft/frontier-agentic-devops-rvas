[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Org,
  [switch]$Teardown
)

$ErrorActionPreference = 'Stop'
$repo = 'ghec-ch33-copilot-automations'
$repoFull = "$Org/$repo"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw 'gh is required'
}

if ($Teardown) {
  if (-not $repo.StartsWith('ghec-ch33-')) {
    throw 'Refusing to delete a non-ch33 repository'
  }
  gh repo view $repoFull 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    gh repo delete $repoFull --yes
    Write-Host "Deleted $repoFull"
  } else {
    Write-Host "Fallback repository already absent: $repoFull"
  }
  exit 0
}

gh repo view $repoFull 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  gh repo create $repoFull --private --description 'Safe fallback for GHEC Ch33 Copilot Automations'
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Unable to create private fallback '$repoFull'."
    Write-Warning 'Do not use a public substitute; retain the decision package in the customer evidence location.'
    exit 0
  }
}

function Set-SeedFile {
  param([string]$Path, [string]$Message, [string]$Content)

  $sha = gh api "repos/$repoFull/contents/$Path" --jq .sha 2>$null
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $args = @('--method', 'PUT', "repos/$repoFull/contents/$Path", '-f', "message=$Message", '-f', "content=$encoded")
  if ($sha) { $args += @('-f', "sha=$sha") }
  gh api @args | Out-Null
}

Set-SeedFile -Path 'README.md' -Message 'Add Ch33 fallback overview' -Content @'
# GHEC Ch33 — Copilot Automations decision-package fallback

This private `ghec-ch33-*` repository is a safe fallback. It does not create,
enable, or test a Copilot automation.

Use it only when an approved customer private/internal repository is not yet
available. Complete `docs/AUTOMATION-DECISION-PACKAGE.md`, then move the
approved operating model and evidence to the customer-owned target.

Do not place secrets in an automation prompt or this repository. Do not opt in
to untrusted event triggers. Copilot automations are configured in the GitHub
UI and their sessions, rather than this file, are the authoritative run record.
'@

Set-SeedFile -Path 'docs/AUTOMATION-DECISION-PACKAGE.md' `
  -Message 'Add Ch33 automation decision package' -Content @'
# Copilot Automations decision package

## Target and authority
- Customer repository URL and visibility:
- Repository owner:
- Automation creator:
- Independent reviewer:
- Security and Copilot owners:
- Approval and evidence location:

## Eligibility
- Copilot plan and evidence:
- Cloud-agent policy and evidence:
- Automations policy and evidence:
- Creator write access:
- Private/internal repository result:
- EMU eligibility result:

## Proposed bounded automation
- Task and accepted outcome:
- Schedule or event trigger:
- Event search/files filters and controlled match/non-match evidence:
- Prompt boundary and untrusted-content instruction:
- Requested tools and rejected higher-privilege tools:
- Data boundary, run-rate limit, and cost owner:

## Safety, evidence, and next decision
- Default untrusted-user-event guardrail retained:
- Independent-review and workflow-run approval posture:
- Session-log and audit-log evidence locations:
- Stop conditions and disable/rollback owner:
- Blocker, if any:
- Decision (`approved pilot`, `inspect-and-propose`, `unavailable`, or `not applicable`):
- Next decision owner and date:
'@

Write-Host "Safe fallback decision-package repository ready: $repoFull"
Write-Host 'Next: record eligibility and approval decisions; do not enable an automation until the customer target is authorized.'
