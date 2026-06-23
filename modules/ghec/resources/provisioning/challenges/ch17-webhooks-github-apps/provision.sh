# shellcheck shell=bash
#
# challenges/ch17-webhooks-github-apps/provision.sh
#
# ch17 seeds a webhook + GitHub App practice repo: an HMAC-verifying receiver
# scaffold (Bash + Node), a repository_dispatch workflow that the receiver can
# trigger, a WEBHOOK-SETUP.md walkthrough, and an app-manifest.json for the
# GitHub App manifest flow. No live webhook/app is created — wiring them is the
# challenge.

_ch17_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch17_seed() {
  log_step "seeding webhook receiver scaffold + app manifest"

  gh_put_file "$ORG" "$REPO" "README.md" \
    "Add webhooks & GitHub Apps overview" \
"$(cat <<EOF
# wth-ch17 — Webhooks & GitHub Apps

Scaffold for practising webhook delivery + GitHub App auth.

- \`receiver/verify.sh\` — Bash HMAC-SHA256 signature check
- \`receiver/verify.js\` — Node HMAC-SHA256 signature check
- \`.github/workflows/receiver.yml\` — repository_dispatch responder
- \`WEBHOOK-SETUP.md\` — end-to-end setup walkthrough
- \`app-manifest.json\` — GitHub App manifest for the create-from-manifest flow

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

  gh_put_file "$ORG" "$REPO" "app-manifest.json" \
    "Add GitHub App manifest" \
"$(cat <<EOF
{
  "name": "wth-ch17-app",
  "url": "https://github.com/$ORG/$REPO",
  "hook_attributes": { "active": true },
  "redirect_url": "https://example.com/callback",
  "public": false,
  "default_permissions": { "issues": "write", "metadata": "read" },
  "default_events": ["issues", "issue_comment"]
}
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
  log_info "  - create a GitHub App from app-manifest.json and install it"
  log_warn "manual: no live webhook or App is created — wiring them is the challenge."
}

wth_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
  log_warn "manual: delete any GitHub App you created from the manifest — teardown only removes the repo."
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local recv manifest
    recv="present"; gh_file_exists "$ORG" "$REPO" "receiver/verify.js" || recv="MISSING"
    manifest="present"; gh_file_exists "$ORG" "$REPO" "app-manifest.json" || manifest="MISSING"
    log_ok "repo $(_ch17_repo_full) present — receiver $recv, app-manifest.json $manifest"
  else
    log_info "repo $(_ch17_repo_full) not provisioned"
  fi
}
