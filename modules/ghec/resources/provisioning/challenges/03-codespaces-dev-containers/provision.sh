# shellcheck shell=bash
#
# challenges/ch03-codespaces-dev-containers/provision.sh
#
# Sourced by scripts/setup.sh (exports ORG CHID SLUG ... REPO; lib helpers
# log_*, run_mutation, gh_*, guard_prefix, meta_*).
#
# CONTRACT: ghec_provision / ghec_teardown / ghec_status.
#
# ch03 builds: a seeded Node/Express app with package.json, a README that
# documents the local run path, and a minimal .devcontainer/ baseline that
# participants extend with features, lifecycle polish, policy, and prebuilds.

_ch03_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch03_seed() {
  log_step "seeding Node/Express app on main"

  gh_put_file "$ORG" "$REPO" "README.md" "seed README (ghec-${CHID})" \
"# ghec-${CHID} — Codespaces & Dev Containers

A tiny Node/Express app. Today it only runs if you install the right Node
version locally — your job is to make it reproducible in a Codespace.

## Run locally (the painful path)
1. Install Node 20+ and npm yourself.
2. \`npm install\`
3. \`npm start\`  → serves http://localhost:3000
4. Forward/expose the port manually.

## Your task
- Inspect the seeded \`.devcontainer/devcontainer.json\` baseline.
- Extend it with dev-container Features, lifecycle polish, and port settings.
- Bonus: configure a prebuild.

> The seeded \`.devcontainer/\` is intentionally minimal — improve it as part of the challenge."

  gh_put_file "$ORG" "$REPO" "package.json" "seed package.json (ghec-${CHID})" \
"{
  \"name\": \"ghec-${CHID}-app\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"engines\": { \"node\": \">=20\" },
  \"scripts\": { \"start\": \"node src/index.js\" },
  \"dependencies\": { \"express\": \"^4.19.2\" }
}
"

  gh_put_file "$ORG" "$REPO" "src/index.js" "seed src/index.js (ghec-${CHID})" \
"const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.json({ ok: true, app: 'ghec-${CHID}', node: process.version });
});

app.listen(port, () => {
  console.log('ghec-${CHID} listening on http://localhost:' + port);
});
"

  gh_put_file "$ORG" "$REPO" ".gitignore" "seed .gitignore (ghec-${CHID})" \
"node_modules/
npm-debug.log
.env
"

  gh_put_file "$ORG" "$REPO" ".devcontainer/devcontainer.json" \
    "seed minimal devcontainer (ghec-${CHID})" \
"{
  \"name\": \"ghec-${CHID}\",
  \"image\": \"mcr.microsoft.com/devcontainers/javascript-node:22\",
  \"onCreateCommand\": \"npm install\",
  \"forwardPorts\": [3000],
  \"portsAttributes\": {
    \"3000\": {
      \"label\": \"web\",
      \"onAutoForward\": \"notify\"
    }
  }
}
"
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch03_full) missing after create — aborting seed"
  fi
  _ch03_seed
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - inspect the seeded .devcontainer/devcontainer.json baseline"
  log_info "  - add dev-container Features, postStartCommand, and VS Code customizations"
  log_info "  - open the repo in a Codespace and run 'npm start'"
  log_info "  - tune a prebuild for freshness, cost, and developer regions"
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    if gh_file_exists "$ORG" "$REPO" ".devcontainer/devcontainer.json"; then
      log_ok "repo $(_ch03_full) present — minimal devcontainer present"
    else
      log_warn "repo $(_ch03_full) present — .devcontainer/devcontainer.json missing"
    fi
  else
    log_info "repo $(_ch03_full) not provisioned"
  fi
}
