# shellcheck shell=bash
#
# challenges/ch07-teams-roles-permissions/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: wth_provision / wth_teardown / wth_status.
#
# ORG-SCOPED. ch07 builds three seeded repos (frontend/backend/platform), one
# flat starter team with the current authenticated user as its sole member and
# NO repo access yet, then prints an access snapshot. Designing the team tree
# and granting the right permissions is the challenge.

R_FE="wth-${CHID}-frontend"
R_BE="wth-${CHID}-backend"
R_PL="wth-${CHID}-platform"
TEAM="wth-${CHID}-engineering"

_ch07_seed_repo() {
  local repo="$1" area="$2"
  gh_put_file "$ORG" "$repo" "README.md" "seed README (wth-${CHID})" \
"# ${repo}

The ${area} service, seeded by wth-${CHID} (Teams, Roles & Permissions).
No team has access yet — that's your job."
  gh_put_file "$ORG" "$repo" "src/index.js" "seed src tree (wth-${CHID})" \
"console.log('${area} service — wth-${CHID}');
"
}

# ===========================================================================
wth_provision() {
  gh_create_repo "$ORG" "$R_FE" private
  gh_create_repo "$ORG" "$R_BE" private
  gh_create_repo "$ORG" "$R_PL" private

  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_FE" && _ch07_seed_repo "$R_FE" "frontend"
    gh_repo_exists "$ORG" "$R_BE" && _ch07_seed_repo "$R_BE" "backend"
    gh_repo_exists "$ORG" "$R_PL" && _ch07_seed_repo "$R_PL" "platform"
  else
    log_plan "would seed README + src tree into $R_FE, $R_BE, $R_PL"
  fi

  # flat starter team — current user only, no repo grants yet.
  gh_create_team "$ORG" "$TEAM" "wth-${CHID} flat starter team"
  local me; me="$(auth_login)"
  if [[ -n "$me" ]]; then
    gh_team_add_member "$ORG" "$TEAM" "$me" member
  else
    log_warn "could not resolve current login — add a member to '$TEAM' manually"
  fi

  # access snapshot.
  log_step "team + repo access snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would list org teams and per-repo grants for the wth-${CHID} repos"
  else
    gh api "orgs/$ORG/teams" --jq '.[] | {slug, privacy, permission}' 2>/dev/null \
      || log_warn "could not list teams (needs read:org)"
  fi
}

wth_teardown() {
  local r
  for r in "$R_FE" "$R_BE" "$R_PL"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
  guard_prefix "$TEAM" "$CHID" || return 1
  gh_delete_team "$ORG" "$TEAM"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  local r
  for r in "$R_FE" "$R_BE" "$R_PL"; do
    if gh_repo_exists "$ORG" "$r"; then log_ok "repo $ORG/$r present"; else log_info "repo $ORG/$r absent"; fi
  done
  if gh_team_exists "$ORG" "$TEAM"; then log_ok "team $TEAM present"; else log_info "team $TEAM absent"; fi
}
