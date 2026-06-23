# shellcheck shell=bash
#
# challenges/ch20-automation-capstone/provision.sh
#
# ch20 is the capstone: it seeds a repo with a GitHub App webhook-handler
# scaffold, an automation workflow, a CAPSTONE.md brief, and an App manifest
# (app-manifest.json) for the manifest registration flow. It also creates an
# empty org Projects v2 board (wth-ch20-board) for the GraphQL step to populate.
# Live App registration stays a manual step (the manifest is the supported path).

PROJECT_TITLE="wth-${CHID}-board"

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
# wth-ch20 — Automation Capstone

Tie it all together: a GitHub App webhook handler, an automation workflow, and
a Projects v2 board driven by the API.

- \`src/handler.js\` — webhook handler scaffold (signature verify + route)
- \`.github/workflows/automation.yml\` — automation entry point
- \`app-manifest.json\` — GitHub App manifest (registration flow)
- \`CAPSTONE.md\` — the capstone brief and acceptance criteria
- Board: \`$PROJECT_TITLE\` (empty org Projects v2 board to populate via GraphQL)
EOF
)"

  gh_put_file "$ORG" "$REPO" "package.json" \
    "Add minimal package.json" \
"$(cat <<'EOF'
{
  "name": "wth-ch20-automation-capstone",
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

  gh_put_file "$ORG" "$REPO" "app-manifest.json" \
    "Add GitHub App manifest" \
"$(cat <<EOF
{
  "name": "wth-ch20-capstone-app",
  "url": "https://github.com/$ORG",
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
EOF
)"

  gh_put_file "$ORG" "$REPO" "CAPSTONE.md" \
    "Add capstone brief" \
"$(cat <<EOF
# Capstone Brief — wth-ch20

Combine the automation building blocks into one working flow.

## Goals
- Register a GitHub App using \`app-manifest.json\` (manifest flow).
- Verify webhook signatures in \`src/handler.js\`.
- On new issues, add them to the \`$PROJECT_TITLE\` board via the GraphQL API.
- Use \`.github/workflows/automation.yml\` as the automation entry point.

## Acceptance criteria
- [ ] App registered and installed on this repo.
- [ ] Webhook deliveries verified (bad signatures rejected).
- [ ] New issues appear on the \`$PROJECT_TITLE\` board automatically.
- [ ] Secrets stored as Actions/App secrets — never committed.

> Live App registration is a manual step; the manifest is the supported path.
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
wth_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch20_repo_full) missing after create — aborting seed"
  fi
  _ch20_seed_repo
  _ch20_seed_project
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - register the App from app-manifest.json and install it on this repo"
  log_info "  - drive the '$PROJECT_TITLE' board from issue events via GraphQL"
  log_warn "manual: live GitHub App registration + webhook endpoint are not automated."
}

wth_teardown() {
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

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local manifest num
    manifest="present"; gh_file_exists "$ORG" "$REPO" "app-manifest.json" || manifest="MISSING"
    num="$(_ch20_project_number)"
    if [[ -n "${num:-}" ]]; then num="present (#$num)"; else num="MISSING"; fi
    log_ok "repo $(_ch20_repo_full) present — manifest $manifest, board $num"
  else
    log_info "repo $(_ch20_repo_full) not provisioned"
  fi
}
