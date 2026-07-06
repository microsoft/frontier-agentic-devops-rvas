# shellcheck shell=bash
#
# challenges/ch20-automation-capstone/provision.sh
#
# ch20 is the capstone: it seeds a repo with a GitHub App webhook-handler
# scaffold, an automation workflow, and a CAPSTONE.md brief. It also creates an
# empty org Projects v2 board (ghec-ch20-board) for the GraphQL step to populate.
# Live App registration stays a manual step (see the challenge README, Part A).

PROJECT_TITLE="ghec-${CHID}-board"

_ch20_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch20_project_number() {
  { gh project list --owner "$ORG" --format json --limit 100 2>/dev/null \
    | jq -r --arg t "$PROJECT_TITLE" '.projects[]? | select(.title==$t) | .number' \
    | head -n1; } || true
}

_ch20_seed_repo() {
  log_step "seeding capstone scaffold (App handler + automation + brief)"

  gh_put_file "$ORG" "$REPO" "README.md" \
    "Add capstone overview" \
"$(cat <<EOF
# ghec-ch20 — Automation Capstone

Tie it all together: a GitHub App webhook handler, an automation workflow, and
a Projects v2 board driven by the API.

- \`src/handler.js\` — webhook handler scaffold (signature verify + route)
- \`src/auth.js\` — GitHub App auth helpers (App JWT + installation token), ready to use
- \`.github/workflows/automation.yml\` — automation entry point
- \`CAPSTONE.md\` — the capstone brief and acceptance criteria
- Board: \`$PROJECT_TITLE\` (empty org Projects v2 board to populate via GraphQL)
EOF
)"

  gh_put_file "$ORG" "$REPO" "package.json" \
    "Add minimal package.json" \
"$(cat <<'EOF'
{
  "name": "ghec-ch20-automation-capstone",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node src/handler.js"
  }
}
EOF
)"

  gh_put_file "$ORG" "$REPO" "src/handler.js" \
    "Add webhook handler scaffold" \
"$(cat <<'EOF'
// ghec-ch20 — GitHub App webhook handler scaffold.
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
      // TODO (Part D): add the new issue to the ghec-ch20-board project via GraphQL.
      return { handled: true, action: body.action, token: Boolean(token) }
    }
    default:
      return { handled: false }
  }
}

module.exports = { verifySignature, mintInstallationToken, handleEvent }
EOF
)"

  gh_put_file "$ORG" "$REPO" "src/auth.js" \
    "Add GitHub App auth helpers" \
"$(cat <<'EOF'
// ghec-ch20 — GitHub App auth helpers. Zero dependencies, Node 18+ (global fetch).
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
      'User-Agent': 'ghec-ch20-capstone-app'
    }
  })
  if (!res.ok) throw new Error(`token exchange failed: ${res.status} ${await res.text()}`)
  return (await res.json()).token
}

module.exports = { createAppJwt, getInstallationToken }
EOF
)"

  gh_put_file "$ORG" "$REPO" ".github/workflows/automation.yml" \
    "Add automation workflow" \
"$(cat <<'EOF'
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
EOF
)"

  gh_put_file "$ORG" "$REPO" "CAPSTONE.md" \
    "Add capstone brief" \
"$(cat <<EOF
# Capstone Brief — ghec-ch20

Combine the automation building blocks into one working flow.

## Goals
- Register and install a GitHub App (manual — see the challenge README, Part A).
- Verify webhook signatures in \`src/handler.js\`.
- Mint an installation token via \`src/auth.js\` (JWT signing is provided — just call \`mintInstallationToken()\`).
- On new issues, add them to the \`$PROJECT_TITLE\` board via the GraphQL API.
- Use \`.github/workflows/automation.yml\` as the automation entry point.

## Acceptance criteria
- [ ] App registered and installed on this repo.
- [ ] Webhook deliveries verified (bad signatures rejected).
- [ ] New issues appear on the \`$PROJECT_TITLE\` board automatically.
- [ ] Secrets stored as Actions/App secrets — never committed.

> Live App registration is a manual step — there is no JSON to upload; create the App via the GitHub Apps form.
EOF
)"
}

_ch20_seed_project() {
  log_step "seeding empty Project (v2): $PROJECT_TITLE"
  local num
  num="$(_ch20_project_number)"
  if [[ -n "${num:-}" ]]; then
    log_ok "project '$PROJECT_TITLE' exists (#$num, skip)"
    return 0
  fi
  run_mutation gh project create --owner "$ORG" --title "$PROJECT_TITLE"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch20_repo_full) missing after create — aborting seed"
  fi
  _ch20_seed_repo
  _ch20_seed_project
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - register the App (manual — see README Part A) and install it on this repo"
  log_info "  - drive the '$PROJECT_TITLE' board from issue events via GraphQL"
  log_warn "manual: live GitHub App registration + webhook endpoint are not automated."
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"

  local num
  num="$(_ch20_project_number)"
  if [[ -n "${num:-}" ]]; then
    guard_prefix "$PROJECT_TITLE" "$CHID" || return 1
    run_mutation gh project delete "$num" --owner "$ORG"
  else
    log_ok "project '$PROJECT_TITLE' absent (skip)"
  fi
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local handler num
    handler="present"; gh_file_exists "$ORG" "$REPO" "src/handler.js" || handler="MISSING"
    num="$(_ch20_project_number)"
    if [[ -n "${num:-}" ]]; then num="present (#$num)"; else num="MISSING"; fi
    log_ok "repo $(_ch20_repo_full) present — handler $handler, board $num"
  else
    log_info "repo $(_ch20_repo_full) not provisioned"
  fi
}
