# challenges/ch20-automation-capstone/provision.ps1
#
# PowerShell twin of ch20 — capstone scaffold, App manifest, and org board.

$Global:WthProjectTitle = "wth-$($Global:WthChid)-board"

function _Ch20-RepoFull { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch20-ProjectNumber {
  $json = gh project list --owner $Global:WthOrg --format json --limit 100 2>$null
  if (-not $json) { return $null }
  return ($json | ConvertFrom-Json).projects |
    Where-Object { $_.title -eq $Global:WthProjectTitle } |
    Select-Object -First 1 -ExpandProperty number
}

function _Ch20-SeedRepo {
  Write-WthStep 'seeding capstone scaffold (App handler + automation + brief)'
  $org = $Global:WthOrg
  $repo = $Global:WthRepo
  $board = $Global:WthProjectTitle

  $readme = @"
# wth-ch20 — Automation Capstone

Tie it all together: a GitHub App webhook handler, an automation workflow, and
a Projects v2 board driven by the API.

- ``src/handler.js`` — webhook handler scaffold (signature verify + route)
- ``.github/workflows/automation.yml`` — automation entry point
- ``app-manifest.json`` — GitHub App manifest (registration flow)
- ``CAPSTONE.md`` — the capstone brief and acceptance criteria
- Board: ``$board`` (empty org Projects v2 board to populate via GraphQL)
"@
  Set-WthFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add capstone overview' -Content $readme

  $pkg = @'
{
  "name": "wth-ch20-automation-capstone",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node src/handler.js"
  }
}
'@
  Set-WthFile -Org $org -Repo $repo -Path 'package.json' -Message 'Add minimal package.json' -Content $pkg

  $handler = @'
// wth-ch20 — GitHub App webhook handler scaffold.
// Verify the signature, then route events. Fill in the TODOs for the capstone.
const crypto = require('crypto')

function verifySignature (secret, payload, signature) {
  const hmac = crypto.createHmac('sha256', secret)
  const digest = 'sha256=' + hmac.update(payload).digest('hex')
  return signature &&
    crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest))
}

function handleEvent (event, body) {
  switch (event) {
    case 'issues':
      // TODO: add new issues to the wth-ch20-board project via GraphQL
      return { handled: true, action: body.action }
    default:
      return { handled: false }
  }
}

module.exports = { verifySignature, handleEvent }
'@
  Set-WthFile -Org $org -Repo $repo -Path 'src/handler.js' -Message 'Add webhook handler scaffold' -Content $handler

  $auto = @'
name: Automation
on:
  issues:
    types: [opened, labeled]
  workflow_dispatch:
permissions:
  contents: read
  issues: write
jobs:
  automate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "capstone automation entry point — wire up your API calls here"
'@
  Set-WthFile -Org $org -Repo $repo -Path '.github/workflows/automation.yml' -Message 'Add automation workflow' -Content $auto

  $manifest = @"
{
  "name": "wth-ch20-capstone-app",
  "url": "https://github.com/$org",
  "hook_attributes": {
    "url": "https://example.com/webhook"
  },
  "redirect_url": "https://example.com/callback",
  "public": false,
  "default_permissions": {
    "issues": "write",
    "contents": "read",
    "metadata": "read"
  },
  "default_events": [
    "issues",
    "issue_comment"
  ]
}
"@
  Set-WthFile -Org $org -Repo $repo -Path 'app-manifest.json' -Message 'Add GitHub App manifest' -Content $manifest

  $capstone = @"
# Capstone Brief — wth-ch20

Combine the automation building blocks into one working flow.

## Goals
- Register a GitHub App using ``app-manifest.json`` (manifest flow).
- Verify webhook signatures in ``src/handler.js``.
- On new issues, add them to the ``$board`` board via the GraphQL API.
- Use ``.github/workflows/automation.yml`` as the automation entry point.

## Acceptance criteria
- [ ] App registered and installed on this repo.
- [ ] Webhook deliveries verified (bad signatures rejected).
- [ ] New issues appear on the ``$board`` board automatically.
- [ ] Secrets stored as Actions/App secrets — never committed.

> Live App registration is a manual step; the manifest is the supported path.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'CAPSTONE.md' -Message 'Add capstone brief' -Content $capstone
}

function _Ch20-SeedProject {
  Write-WthStep "seeding empty Project (v2): $($Global:WthProjectTitle)"
  $num = _Ch20-ProjectNumber
  if ($num) { Write-WthOk "project '$($Global:WthProjectTitle)' exists (#$num, skip)"; return }
  Invoke-WthMutation -Plan "gh project create $($Global:WthProjectTitle)" -Action {
    gh project create --owner $Global:WthOrg --title $Global:WthProjectTitle
  }
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility 'public'
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch20-RepoFull) missing after create — aborting seed"
  }
  _Ch20-SeedRepo
  _Ch20-SeedProject
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - register the App from app-manifest.json and install it on this repo'
  Write-WthInfo "  - drive the '$($Global:WthProjectTitle)' board from issue events via GraphQL"
  Write-WthWarn 'manual: live GitHub App registration + webhook endpoint are not automated.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo

  $num = _Ch20-ProjectNumber
  if ($num) {
    if (-not (Confirm-WthPrefix -Name $Global:WthProjectTitle -Chid $Global:WthChid)) { return }
    Invoke-WthMutation -Plan "gh project delete $num" -Action { gh project delete $num --owner $Global:WthOrg }
  } else {
    Write-WthOk "project '$($Global:WthProjectTitle)' absent (skip)"
  }
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $manifest = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRepo -Path 'app-manifest.json') { 'present' } else { 'MISSING' }
    $num = _Ch20-ProjectNumber
    $board = if ($num) { "present (#$num)" } else { 'MISSING' }
    Write-WthOk "repo $(_Ch20-RepoFull) present — manifest $manifest, board $board"
  } else {
    Write-WthInfo "repo $(_Ch20-RepoFull) not provisioned"
  }
}
