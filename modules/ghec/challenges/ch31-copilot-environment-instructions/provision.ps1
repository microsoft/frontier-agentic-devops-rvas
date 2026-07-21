[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Org,
  [switch]$Teardown
)

$ErrorActionPreference = 'Stop'
$repo = 'ghec-ch31-copilot-environment-instructions'
$repoFull = "$Org/$repo"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw 'gh is required'
}

if ($Teardown) {
  if (-not $repo.StartsWith('ghec-ch31-')) {
    throw 'Refusing to delete a non-ch31 repository'
  }
  gh repo delete $repoFull --yes
  Write-Host "Deleted $repoFull"
  exit 0
}

gh repo view $repoFull 2>$null
if ($LASTEXITCODE -ne 0) {
  gh repo create $repoFull --public --description 'Safe fallback for GHEC Ch31 Copilot environment instructions'
}

function Set-SeedFile {
  param([string]$Path, [string]$Message, [string]$Content)

  $sha = gh api "repos/$repoFull/contents/$Path" --jq .sha 2>$null
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Content))
  $args = @('--method', 'PUT', "repos/$repoFull/contents/$Path", '-f', "message=$Message", '-f', "content=$encoded")
  if ($sha) { $args += @('-f', "sha=$sha") }
  gh api @args | Out-Null
}

Set-SeedFile -Path 'README.md' -Message 'Add Ch31 fallback overview' -Content @'
# GHEC Ch31 — Copilot Environment & Instructions

Safe fallback repository for validating a Copilot setup workflow and instruction
layout. It contains no customer data, secret, service, internal endpoint, runner,
or Copilot policy change.

Run `npm ci && npm test`. The default-branch setup workflow is the common
environment baseline for Copilot cloud agent and Copilot code review.
'@

Set-SeedFile -Path 'package.json' -Message 'Add minimal Node.js fixture' -Content @'
{
  "name": "ghec-ch31-copilot-environment-instructions",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node test/greeting.test.js"
  }
}
'@

Set-SeedFile -Path 'package-lock.json' -Message 'Add npm lockfile' -Content @'
{
  "name": "ghec-ch31-copilot-environment-instructions",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "ghec-ch31-copilot-environment-instructions",
      "version": "1.0.0"
    }
  }
}
'@

Set-SeedFile -Path 'src/greeting.js' -Message 'Add greeting fixture' -Content @'
function formatGreeting (name) {
  return `Hello, ${name}!`
}

module.exports = { formatGreeting }
'@

Set-SeedFile -Path 'test/greeting.test.js' -Message 'Add fixture test' -Content @'
const assert = require('assert')
const { formatGreeting } = require('../src/greeting')

assert.strictEqual(formatGreeting('Ada'), 'Hello, Ada!')
console.log('greeting test passed')
'@

Set-SeedFile -Path '.github/copilot-instructions.md' -Message 'Add repository Copilot instructions' -Content @'
# Repository instructions

Use Node.js 20. Run `npm ci` and `npm test` before proposing a change. Keep
changes small, avoid adding secrets or network access, and explain validation in
the pull request. Human review and CI remain required.
'@

Set-SeedFile -Path '.github/instructions/source.instructions.md' -Message 'Add path-specific Copilot instructions' -Content @'
---
applyTo: "src/**/*.js"
---
Use CommonJS exports. Update the matching test under `test/` for behavior
changes and run `npm test`.
'@

Set-SeedFile -Path '.github/workflows/copilot-setup-steps.yml' -Message 'Add Copilot setup steps' -Content @'
name: Copilot setup steps

on:
  workflow_dispatch:
  push:
    paths: [.github/workflows/copilot-setup-steps.yml]
  pull_request:
    paths: [.github/workflows/copilot-setup-steps.yml]

jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm
      - run: npm ci
      - run: npm test
'@

$issueTitle = 'Validate the Copilot environment and instructions'
$existing = gh issue list --repo $repoFull --state all --limit 100 --json title --jq '.[].title' 2>$null
if ($existing -notcontains $issueTitle) {
  $body = @'
Validate the default-branch Copilot setup workflow and instruction layout.

Acceptance criteria:
- Run the setup workflow from Actions and retain its successful URL.
- Make a small, reviewed pull request that changes `src/greeting.js`.
- Confirm the repository and matching path-specific instructions are on the PR head branch.
- Request approved Copilot code review and/or assign an approved cloud-agent task.
- Record observed evidence and any unavailable-feature limitation.

Do not add a secret, service, self-hosted runner, or policy change to this seed.
'@
  gh issue create --repo $repoFull --title $issueTitle --body $body | Out-Null
}

Write-Host "Safe fallback ready: $repoFull"
Write-Host 'Next: confirm the setup workflow is on the repository default branch, run it from Actions, then use the bounded issue only if the applicable Copilot feature is approved.'
