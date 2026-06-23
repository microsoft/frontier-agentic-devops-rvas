# shellcheck shell=bash
#
# challenges/ch03-codespaces-dev-containers/provision.sh
#
# Sourced by scripts/setup.sh (exports ORG CHID SLUG ... REPO; lib helpers
# log_*, run_mutation, gh_*, guard_prefix, meta_*).
#
# CONTRACT: wth_provision / wth_teardown / wth_status.
#
# ch03 builds: a seeded Node/Express app with package.json and a README that
# documents the LOCAL run path. There is intentionally NO .devcontainer/ —
# authoring it (and launching a Codespace) is the challenge.

_ch03_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch03_seed() {
  log_step "seeding Node/Express app on main"

  gh_put_file "$ORG" "$REPO" "README.md" "seed README (wth-${CHID})" \
"# wth-${CHID} — Codespaces & Dev Containers

A tiny Node/Express app. Today it only runs if you install the right Node
version locally — your job is to make it reproducible in a Codespace.

## Run locally (the painful path)
1. Install Node 20+ and npm yourself.
2. \`npm install\`
3. \`npm start\`  → serves http://localhost:3000
4. Forward/expose the port manually.

## Your task
- Add a \`.devcontainer/devcontainer.json\` so a Codespace boots ready-to-run.
- Pin the Node image, install deps on create, and forward port 3000.
- Bonus: configure a prebuild.

> There is no \`.devcontainer/\` yet — that's the point."

  gh_put_file "$ORG" "$REPO" "package.json" "seed package.json (wth-${CHID})" \
"{
  \"name\": \"wth-${CHID}-app\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"engines\": { \"node\": \">=20\" },
  \"scripts\": { \"start\": \"node src/index.js\" },
  \"dependencies\": { \"express\": \"^4.19.2\" }
}
"

  gh_put_file "$ORG" "$REPO" "src/index.js" "seed src/index.js (wth-${CHID})" \
"const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.json({ ok: true, app: 'wth-${CHID}', node: process.version });
});

app.listen(port, () => {
  console.log('wth-${CHID} listening on http://localhost:' + port);
});
"

  gh_put_file "$ORG" "$REPO" ".gitignore" "seed .gitignore (wth-${CHID})" \
"node_modules/
npm-debug.log
.env
"
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch03_full) missing after create — aborting seed"
  fi
  _ch03_seed
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - author .devcontainer/devcontainer.json (pin Node, postCreate npm install, forward 3000)"
  log_info "  - open the repo in a Codespace and run 'npm start'"
  log_info "  - configure a prebuild for faster boots"
}

wth_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    if gh_file_exists "$ORG" "$REPO" ".devcontainer/devcontainer.json"; then
      log_ok "repo $(_ch03_full) present — devcontainer authored (challenge progressed)"
    else
      log_ok "repo $(_ch03_full) present — no .devcontainer yet (expected at provision)"
    fi
  else
    log_info "repo $(_ch03_full) not provisioned"
  fi
}
