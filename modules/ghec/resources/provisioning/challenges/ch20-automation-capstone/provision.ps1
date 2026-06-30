# challenges/ch20-automation-capstone/provision.ps1
#
# PowerShell twin of ch20 — capstone scaffold and org board.

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
- ``src/auth.js`` — GitHub App auth helpers (App JWT + installation token), ready to use
- ``.github/workflows/automation.yml`` — automation entry point
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
// Signature verification and App auth are provided for you; fill in the REST and
// GraphQL TODOs — that automation logic is the capstone.
const crypto = require('crypto')
const fs = require('fs')
const { createAppJwt, getInstallationToken } = require('./auth')

function verifySignature (secret, payload, signature) {
  const hmac = crypto.createHmac('sha256', secret)
  const digest = 'sha256=' + hmac.update(payload).digest('hex')
  return signature &&
    crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest))
}

// Mint a short-lived installation token. JWT signing is done for you in auth.js,
// so you never touch RS256/openssl here — just call this and use the token.
async function mintInstallationToken () {
  const pem = fs.readFileSync(process.env.PRIVATE_KEY_PATH || './private-key.pem', 'utf8')
  const jwt = createAppJwt(process.env.APP_ID, pem)
  return getInstallationToken(jwt, process.env.INSTALLATION_ID)
}

async function handleEvent (event, body) {
  switch (event) {
    case 'issues': {
      if (body.action !== 'opened') return { handled: false }
      const token = await mintInstallationToken()
      // TODO (Part C): with `token`, add a triage label + acknowledgement comment via REST.
      // TODO (Part D): add the new issue to the wth-ch20-board project via GraphQL.
      return { handled: true, action: body.action, token: Boolean(token) }
    }
    default:
      return { handled: false }
  }
}

module.exports = { verifySignature, mintInstallationToken, handleEvent }
'@
  Set-WthFile -Org $org -Repo $repo -Path 'src/handler.js' -Message 'Add webhook handler scaffold' -Content $handler

  $auth = @'
// wth-ch20 — GitHub App auth helpers. Zero dependencies, Node 18+ (global fetch).
//
// The App JWT -> installation-token flow is provided ready-made so the capstone
// stays focused on the REST + GraphQL automation, not auth plumbing. You should
// never need to hand-sign a JWT (RS256/openssl) yourself.
const crypto = require('crypto')

function base64url (input) {
  return Buffer.from(input).toString('base64')
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
}

// Mint a short-lived App JWT (RS256). `iss` may be the App ID or the Client ID.
function createAppJwt (appId, privateKeyPem) {
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = { iat: now - 60, exp: now + 9 * 60, iss: String(appId) }
  const unsigned = base64url(JSON.stringify(header)) + '.' + base64url(JSON.stringify(payload))
  const signature = crypto.createSign('RSA-SHA256').update(unsigned).sign(privateKeyPem)
  const sig = signature.toString('base64')
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  return unsigned + '.' + sig
}

// Exchange the App JWT for a short-lived installation access token.
async function getInstallationToken (jwt, installationId) {
  const url = `https://api.github.com/app/installations/${installationId}/access_tokens`
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${jwt}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'wth-ch20-capstone-app'
    }
  })
  if (!res.ok) throw new Error(`token exchange failed: ${res.status} ${await res.text()}`)
  return (await res.json()).token
}

module.exports = { createAppJwt, getInstallationToken }
'@
  Set-WthFile -Org $org -Repo $repo -Path 'src/auth.js' -Message 'Add GitHub App auth helpers' -Content $auth

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

  $capstone = @"
# Capstone Brief — wth-ch20

Combine the automation building blocks into one working flow.

## Goals
- Register and install a GitHub App (manual — see the challenge README, Part A).
- Verify webhook signatures in ``src/handler.js``.
- Mint an installation token via ``src/auth.js`` (JWT signing is provided — just call ``mintInstallationToken()``).
- On new issues, add them to the ``$board`` board via the GraphQL API.
- Use ``.github/workflows/automation.yml`` as the automation entry point.

## Acceptance criteria
- [ ] App registered and installed on this repo.
- [ ] Webhook deliveries verified (bad signatures rejected).
- [ ] New issues appear on the ``$board`` board automatically.
- [ ] Secrets stored as Actions/App secrets — never committed.

> Live App registration is a manual step — there is no JSON to upload; create the App via the GitHub Apps form.
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
  Write-WthInfo '  - register the App (manual — see README Part A) and install it on this repo'
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
    $handler = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRepo -Path 'src/handler.js') { 'present' } else { 'MISSING' }
    $num = _Ch20-ProjectNumber
    $board = if ($num) { "present (#$num)" } else { 'MISSING' }
    Write-WthOk "repo $(_Ch20-RepoFull) present — handler $handler, board $board"
  } else {
    Write-WthInfo "repo $(_Ch20-RepoFull) not provisioned"
  }
}
