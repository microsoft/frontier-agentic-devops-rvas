# shellcheck shell=bash
#
# challenges/ch18-self-hosted-runners/provision.sh
#
# ch18 seeds a self-hosted runner practice repo: a hosted workflow (ubuntu-
# latest) and a self-hosted workflow (label-targeted), RUNNER-SETUP.md and
# HARDENING.md guides, plus an ORG-level runner group (ghec-ch18-runners). Actual
# runner registration needs a real machine + token, so that stays a manual step.

RUNNER_GROUP="ghec-${CHID}-runners"

_ch18_repo_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch18_runner_group_id() {
  gh api "orgs/$ORG/actions/runner-groups" --jq \
    ".runner_groups[]? | select(.name==\"$RUNNER_GROUP\") | .id" 2>/dev/null | head -n1
}

_ch18_seed_repo() {
  log_step "seeding runner workflows + setup/hardening guides"

  gh_put_file "$ORG" "$REPO" "README.md" \
    "Add self-hosted runners overview" \
"$(cat <<EOF
# ghec-ch18 — Self-Hosted Runners

Practice repo for self-hosted runner setup, targeting, and hardening.

- \`.github/workflows/hosted.yml\` — baseline job on GitHub-hosted runners
- \`.github/workflows/self-hosted.yml\` — job targeted at a \`self-hosted\` label
- \`RUNNER-SETUP.md\` — register a runner into the \`$RUNNER_GROUP\` group
- \`HARDENING.md\` — runner security hardening checklist

Registering a runner requires a real machine + token — that is the manual step.
EOF
)"

  gh_put_file "$ORG" "$REPO" ".github/workflows/hosted.yml" \
    "Add GitHub-hosted baseline workflow" \
"$(cat <<'EOF'
name: Hosted Baseline
on:
  workflow_dispatch:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "running on a GitHub-hosted runner"
EOF
)"

  gh_put_file "$ORG" "$REPO" ".github/workflows/self-hosted.yml" \
    "Add self-hosted (label-targeted) workflow" \
"$(cat <<'EOF'
name: Self-Hosted Job
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  build:
    # Targets your registered self-hosted runner. Add custom labels as needed.
    runs-on: [self-hosted, linux, x64]
    steps:
      - uses: actions/checkout@v4
      - run: echo "running on a self-hosted runner: $(hostname)"
EOF
)"

  gh_put_file "$ORG" "$REPO" "RUNNER-SETUP.md" \
    "Add runner registration guide" \
"$(cat <<EOF
# Runner Setup — ghec-ch18

Register a self-hosted runner into the \`$RUNNER_GROUP\` org runner group.

1. Org Settings → Actions → Runners → **New runner** (or use a registration token).
2. On the runner host:
   \`\`\`
   ./config.sh --url https://github.com/$ORG --token <REGISTRATION_TOKEN> \\
     --runnergroup "$RUNNER_GROUP" --labels linux,x64
   ./run.sh
   \`\`\`
3. Trigger \`.github/workflows/self-hosted.yml\` and confirm it lands on your runner.
EOF
)"

  gh_put_file "$ORG" "$REPO" "HARDENING.md" \
    "Add runner hardening checklist" \
"$(cat <<'EOF'
# Runner Hardening Checklist — ghec-ch18

- [ ] Use ephemeral runners (`--ephemeral`) so each job starts clean.
- [ ] Never run self-hosted runners on public repos with untrusted PRs.
- [ ] Run as a low-privilege, dedicated user — not root.
- [ ] Restrict the runner group to specific repositories.
- [ ] Keep the runner host patched; rotate registration tokens.
- [ ] Isolate the host (network egress controls, no long-lived cloud creds).
EOF
)"
}

_ch18_seed_runner_group() {
  log_step "seeding org runner group: $RUNNER_GROUP"
  local id
  id="$(_ch18_runner_group_id)"
  if [[ -n "${id:-}" ]]; then
    log_ok "runner group '$RUNNER_GROUP' exists (#$id, skip)"
    return 0
  fi
  run_mutation gh api -X POST "orgs/$ORG/actions/runner-groups" \
    -f name="$RUNNER_GROUP" -f visibility=all
}

# ===========================================================================
ghec_provision() {
  gh_create_repo "$ORG" "$REPO" public
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch18_repo_full) missing after create — aborting seed"
  fi
  _ch18_seed_repo
  _ch18_seed_runner_group
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - register a self-hosted runner into the '$RUNNER_GROUP' group"
  log_info "  - run the self-hosted workflow and review HARDENING.md"
  log_warn "manual: runner registration needs a real machine + token — not automated."
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"

  local id
  id="$(_ch18_runner_group_id)"
  if [[ -n "${id:-}" ]]; then
    guard_prefix "$RUNNER_GROUP" "$CHID" || return 1
    run_mutation gh api -X DELETE "orgs/$ORG/actions/runner-groups/$id"
  else
    log_ok "runner group '$RUNNER_GROUP' absent (skip)"
  fi
  log_warn "manual: de-register any self-hosted runner you connected — teardown does not touch runner hosts."
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local grp
    grp="$(_ch18_runner_group_id)"
    if [[ -n "${grp:-}" ]]; then grp="present (#$grp)"; else grp="MISSING"; fi
    log_ok "repo $(_ch18_repo_full) present — runner group $grp"
  else
    log_info "repo $(_ch18_repo_full) not provisioned"
  fi
}
