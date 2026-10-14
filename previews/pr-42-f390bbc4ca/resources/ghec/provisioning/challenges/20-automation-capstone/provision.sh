# shellcheck shell=bash

_ch20_seed_repo() {
  local integration_dir
  integration_dir="$CH_DIR/../../../integration"
  [[ -f "$integration_dir/handler.cjs" && -f "$integration_dir/handler.test.cjs" ]] \
    || die "missing Ch20 integration starter"

  gh_put_file "$ORG" "$REPO" "README.md" "Add integration overview" \
"# Ch20 integration test repository

Use the approved integration gap from the activity guide. Native Actions or a
Projects workflow may already solve it.

The optional App example receives signed issue webhooks and adds one triage
label. Configure the App and approved HTTPS receiver before running it.
Keep the private key and webhook secret outside this repository.

Run \`npm test\` for local checks and \`npm start\` for the configured HTTP receiver.
"
  gh_put_file "$ORG" "$REPO" "package.json" "Add integration commands" \
'{
  "name": "ghec-ch20-automation-capstone",
  "private": true,
  "engines": { "node": ">=22" },
  "scripts": {
    "start": "node src/handler.cjs",
    "test": "node --test src/handler.test.cjs"
  }
}'
  local file
  for file in handler.cjs handler.test.cjs; do
    gh_put_file "$ORG" "$REPO" "src/$file" "Add integration $file" \
      "$(cat "$integration_dir/$file")"
  done
}

ghec_provision() {
  gh_create_repo "$ORG" "$REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $ORG/$REPO missing after create"
  fi
  _ch20_seed_repo
  log_info "Next: follow Ch20 to test native automation or configure the approved App receiver."
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  if gh_repo_exists "$ORG" "$REPO"; then
    if gh_file_exists "$ORG" "$REPO" "src/handler.cjs"; then
      log_ok "repo $ORG/$REPO has the HTTP receiver"
    else
      log_warn "repo $ORG/$REPO is missing src/handler.cjs"
    fi
  else
    log_info "repo $ORG/$REPO not provisioned"
  fi
}
