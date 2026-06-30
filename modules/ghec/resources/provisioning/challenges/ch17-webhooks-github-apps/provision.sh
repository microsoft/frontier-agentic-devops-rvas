# shellcheck shell=bash
#
# challenges/ch17-webhooks-github-apps/provision.sh
#
# ch17 seeds a webhook + GitHub App practice repo: an HMAC-verifying receiver
# scaffold (Bash + Node), a repository_dispatch workflow that the receiver can
# trigger, and a WEBHOOK-SETUP.md walkthrough. No live webhook/app is created —
# wiring them is the challenge.

_ch17_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch17_seed() {
  log_step "seeding webhook receiver scaffold"

  gh_put_file "$ORG" "$REPO" "README.md" \
    "Add webhooks & GitHub Apps overview" \
"$(cat <<EOF
# wth-ch17 — Webhooks & GitHub Apps

Scaffold for practising webhook delivery + GitHub App auth.

- \`receiver/verify.sh\` — Bash HMAC-SHA256 signature check
- \`receiver/verify.js\` — Node HMAC-SHA256 signature check
- \`app/auth.js\` — GitHub App auth helpers (App JWT + installation token), ready to use
- \`app/handler.js\` — almost-complete webhook handler; one TODO (Part G) to post the comment
- \`.github/workflows/receiver.yml\` — repository_dispatch responder
- \`WEBHOOK-SETUP.md\` — end-to-end setup walkthrough

No live webhook or App is provisioned — creating them is the exercise.
EOF
)"

  gh_put_file "$ORG" "$REPO" "receiver/verify.sh" \
    "Add Bash HMAC verifier" \
"$(cat <<'EOF'
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
EOF
)"

  gh_put_file "$ORG" "$REPO" "receiver/verify.js" \
    "Add Node HMAC verifier" \
"$(cat <<'EOF'
// wth-ch17 — verify an X-Hub-Signature-256 header against the raw body.
const crypto = require('crypto')
function verify (secret, body, signature) {
  const hmac = crypto.createHmac('sha256', secret).update(body).digest('hex')
  const expected = 'sha256=' + hmac
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature))
}
module.exports = { verify }
EOF
)"

  gh_put_file "$ORG" "$REPO" ".github/workflows/receiver.yml" \
    "Add repository_dispatch responder workflow" \
"$(cat <<'EOF'
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
EOF
)"

  gh_put_file "$ORG" "$REPO" "WEBHOOK-SETUP.md" \
    "Add webhook setup walkthrough" \
"$(cat <<EOF
# Webhook Setup — wth-ch17

1. Add a repo webhook (Settings → Webhooks) pointing at your receiver URL.
2. Set a strong **secret** and select the events you care about.
3. Verify deliveries with \`receiver/verify.sh\` or \`receiver/verify.js\`.
4. To exercise Actions, send a \`repository_dispatch\` event of type
   \`wth-event\` and watch \`.github/workflows/receiver.yml\` run:
   \`\`\`
   gh api repos/$ORG/$REPO/dispatches -f event_type=wth-event \\
     -F client_payload[hello]=world
   \`\`\`
EOF
)"

  gh_put_file "$ORG" "$REPO" "app/auth.js" \
    "Add GitHub App auth helpers" \
"$(cat <<'EOF'
// wth-ch17 — GitHub App auth helpers. Zero dependencies, Node 18+ (global fetch).
//
// This is the same JWT -> installation-token flow you ran by hand with openssl
// and `gh api` in Part F, now as reusable functions. It is provided ready-made
// so Part G stays focused on *acting* on the event, not re-plumbing auth.
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
      'User-Agent': 'wth-ch17-app'
    }
  })
  if (!res.ok) throw new Error(`token exchange failed: ${res.status} ${await res.text()}`)
  return (await res.json()).token
}

module.exports = { createAppJwt, getInstallationToken }
EOF
)"

  gh_put_file "$ORG" "$REPO" "app/handler.js" \
    "Add webhook handler scaffold (Part G TODO)" \
"$(cat <<'EOF'
// wth-ch17 — minimal GitHub App webhook handler. Zero dependencies, Node 18+.
//
// Run it (use the same secret you set on the repo webhook in Part A, and the
// App ID / installation ID / private key from Part E):
//
//   APP_ID=<id> INSTALLATION_ID=<id> WEBHOOK_SECRET=<secret> \
//     PRIVATE_KEY_PATH=./wth-ch17-app.private-key.pem node app/handler.js
//
// Then relay your public webhook deliveries to it in another shell:
//
//   npx smee-client --url <your-smee-url> --target http://localhost:3000/
//
// What is DONE for you: verify the HMAC signature, ack fast, route `issues`,
// act only on freshly opened issues, skip bot-authored issues (avoids App loops),
// and mint an installation token. What is YOURS: the TODO in onIssueOpened().
const http = require('http')
const fs = require('fs')
const { verify } = require('../receiver/verify')
const { createAppJwt, getInstallationToken } = require('./auth')

const PORT = process.env.PORT || 3000
const SECRET = process.env.WEBHOOK_SECRET
const APP_ID = process.env.APP_ID
const INSTALLATION_ID = process.env.INSTALLATION_ID
const PRIVATE_KEY = fs.readFileSync(process.env.PRIVATE_KEY_PATH || './private-key.pem', 'utf8')

async function onIssueOpened (issue, repo, token) {
  const owner = repo.owner.login
  const name = repo.name
  const number = issue.number

  // ===========================================================================
  // TODO (Part G): post a context-aware acknowledgement comment AS THE APP.
  //
  // You already have `token` (a short-lived installation token). Build a message
  // from the payload — e.g. greet `issue.user.login`, restate `issue.title`,
  // and say what happens next — then POST it:
  //
  //   POST https://api.github.com/repos/<owner>/<name>/issues/<number>/comments
  //   headers: Authorization: token <token>
  //            Accept: application/vnd.github+json
  //   body:    { "body": "<your message>" }
  //
  // Use fetch(), set the headers above, and check `res.ok`. The comment should
  // appear authored by your App (user.type: "Bot"), not by you.
  // ===========================================================================
  console.log(`TODO: acknowledge issue #${number} in ${owner}/${name}`)
}

const server = http.createServer((req, res) => {
  if (req.method !== 'POST') { res.writeHead(405).end(); return }
  const chunks = []
  req.on('data', c => chunks.push(c))
  req.on('end', async () => {
    const rawBody = Buffer.concat(chunks).toString('utf8')
    const signature = req.headers['x-hub-signature-256'] || ''
    const event = req.headers['x-github-event']

    // 1) Reject anything that fails signature verification (raw body!).
    let ok = false
    try { ok = !!SECRET && verify(SECRET, rawBody, signature) } catch { ok = false }
    if (!ok) { console.warn('rejected: bad signature'); res.writeHead(401).end('bad signature'); return }

    // Ack fast — GitHub retries on non-2xx, so respond before any slow work.
    res.writeHead(202).end('accepted')

    if (event === 'ping') { console.log('ping ok'); return }
    if (event !== 'issues') return

    const payload = JSON.parse(rawBody)
    if (payload.action !== 'opened') return          // 2) only freshly opened issues
    if (payload.issue.user.type === 'Bot') return    // 3) never react to bots (no loops)

    try {
      const jwt = createAppJwt(APP_ID, PRIVATE_KEY)
      const token = await getInstallationToken(jwt, INSTALLATION_ID)
      await onIssueOpened(payload.issue, payload.repository, token)
    } catch (err) {
      console.error('handler error:', err.message)
    }
  })
})

server.listen(PORT, () => console.log(`wth-ch17 handler listening on :${PORT} (POST)`))
EOF
)"
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch17_repo_full) missing after create — aborting seed"
  fi
  _ch17_seed
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - register a webhook and verify signed deliveries"
  log_info "  - create a GitHub App (manual registration — see README Part E) and install it"
  log_warn "manual: no live webhook or App is created — wiring them is the challenge."
}

wth_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
  log_warn "manual: delete any GitHub App you created — teardown only removes the repo."
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local recv
    recv="present"; gh_file_exists "$ORG" "$REPO" "receiver/verify.js" || recv="MISSING"
    log_ok "repo $(_ch17_repo_full) present — receiver $recv"
  else
    log_info "repo $(_ch17_repo_full) not provisioned"
  fi
}
