# challenges/ch17-webhooks-github-apps/provision.ps1
#
# PowerShell twin of ch17 — webhook receiver scaffold.

function _Ch17-RepoFull { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch17-Seed {
  Write-WthStep 'seeding webhook receiver scaffold'
  $org = $Global:WthOrg
  $repo = $Global:WthRepo

  $readme = @"
# wth-ch17 — Webhooks & GitHub Apps

Scaffold for practising webhook delivery + GitHub App auth.

- ``receiver/verify.sh`` — Bash HMAC-SHA256 signature check
- ``receiver/verify.js`` — Node HMAC-SHA256 signature check
- ``.github/workflows/receiver.yml`` — repository_dispatch responder
- ``WEBHOOK-SETUP.md`` — end-to-end setup walkthrough

No live webhook or App is provisioned — creating them is the exercise.
"@
  Set-WthFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add webhooks & GitHub Apps overview' -Content $readme

  $verifySh = @'
#!/usr/bin/env bash
# wth-ch17 — verify an X-Hub-Signature-256 header against the raw body.
set -euo pipefail
SECRET="${WEBHOOK_SECRET:?set WEBHOOK_SECRET}"
SIG_HEADER="${1:?usage: verify.sh <sha256=...> <body-file>}"
BODY_FILE="${2:?usage: verify.sh <sha256=...> <body-file>}"
expected="sha256=$(openssl dgst -sha256 -hmac "$SECRET" "$BODY_FILE" | sed 's/^.* //')"
if [[ "$expected" == "$SIG_HEADER" ]]; then
  echo "signature OK"
else
  echo "signature MISMATCH" >&2; exit 1
fi
'@
  Set-WthFile -Org $org -Repo $repo -Path 'receiver/verify.sh' -Message 'Add Bash HMAC verifier' -Content $verifySh

  $verifyJs = @'
// wth-ch17 — verify an X-Hub-Signature-256 header against the raw body.
const crypto = require('crypto')
function verify (secret, body, signature) {
  const hmac = crypto.createHmac('sha256', secret).update(body).digest('hex')
  const expected = 'sha256=' + hmac
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature))
}
module.exports = { verify }
'@
  Set-WthFile -Org $org -Repo $repo -Path 'receiver/verify.js' -Message 'Add Node HMAC verifier' -Content $verifyJs

  $wf = @'
name: Webhook Responder
on:
  repository_dispatch:
    types: [wth-event]
permissions:
  contents: read
jobs:
  respond:
    runs-on: ubuntu-latest
    steps:
      - name: Show payload
        run: |
          echo "Received event: ${{ github.event.action }}"
          echo "Client payload: ${{ toJSON(github.event.client_payload) }}"
'@
  Set-WthFile -Org $org -Repo $repo -Path '.github/workflows/receiver.yml' -Message 'Add repository_dispatch responder workflow' -Content $wf

  $setup = @"
# Webhook Setup — wth-ch17

1. Add a repo webhook (Settings → Webhooks) pointing at your receiver URL.
2. Set a strong **secret** and select the events you care about.
3. Verify deliveries with ``receiver/verify.sh`` or ``receiver/verify.js``.
4. To exercise Actions, send a ``repository_dispatch`` event of type
   ``wth-event`` and watch ``.github/workflows/receiver.yml`` run:
   ``````
   gh api repos/$org/$repo/dispatches -f event_type=wth-event \
     -F client_payload[hello]=world
   ``````
"@
  Set-WthFile -Org $org -Repo $repo -Path 'WEBHOOK-SETUP.md' -Message 'Add webhook setup walkthrough' -Content $setup
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility 'public'
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch17-RepoFull) missing after create — aborting seed"
  }
  _Ch17-Seed
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - register a webhook and verify signed deliveries'
  Write-WthInfo '  - create a GitHub App (manual registration — see README Part E) and install it'
  Write-WthWarn 'manual: no live webhook or App is created — wiring them is the challenge.'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo
  Write-WthWarn 'manual: delete any GitHub App you created — teardown only removes the repo.'
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $recv = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRepo -Path 'receiver/verify.js') { 'present' } else { 'MISSING' }
    Write-WthOk "repo $(_Ch17-RepoFull) present — receiver $recv"
  } else {
    Write-WthInfo "repo $(_Ch17-RepoFull) not provisioned"
  }
}
