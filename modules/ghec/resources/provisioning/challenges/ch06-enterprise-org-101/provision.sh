# shellcheck shell=bash
#
# challenges/ch06-enterprise-org-101/provision.sh
#
# Sourced by scripts/setup.sh. CONTRACT: wth_provision / wth_teardown / wth_status.
#
# ORG-SCOPED. ch06 builds three sample repos at different visibilities, a
# members team with one repo attached at the default permission, and prints a
# baseline snapshot of the org's member-privilege settings.
#
# NOTE: this challenge creates its OWN repo names (not the default $REPO) so it
# can demonstrate public/private/internal side by side.

R_PUB="wth-${CHID}-public-sample"
R_PRIV="wth-${CHID}-private-sample"
R_INT="wth-${CHID}-internal-sample"
TEAM="wth-${CHID}-members"

_ch06_seed_readme() {
  local repo="$1" vis="$2"
  gh_put_file "$ORG" "$repo" "README.md" "seed README (wth-${CHID})" \
"# ${repo}

A ${vis} sample repo seeded by wth-${CHID} (Enterprise Org 101).
Use it to explore visibility, base permissions, and member privileges."
}

# ===========================================================================
wth_provision() {
  # public + private created normally.
  gh_create_repo "$ORG" "$R_PUB" public
  gh_create_repo "$ORG" "$R_PRIV" private
  # internal requires an enterprise-owned org — tolerate failure with a warning.
  gh_create_repo_soft "$ORG" "$R_INT" internal

  if [[ "$DRY_RUN" != "true" ]]; then
    gh_repo_exists "$ORG" "$R_PUB"  && _ch06_seed_readme "$R_PUB"  "public"
    gh_repo_exists "$ORG" "$R_PRIV" && _ch06_seed_readme "$R_PRIV" "private"
    gh_repo_exists "$ORG" "$R_INT"  && _ch06_seed_readme "$R_INT"  "internal"
  else
    log_plan "would seed README into $R_PUB, $R_PRIV, $R_INT (when present)"
  fi

  # members team with the public sample attached at the default (pull) permission.
  gh_create_team "$ORG" "$TEAM" "wth-${CHID} sample members team"
  gh_team_add_repo "$ORG" "$TEAM" "$R_PUB" pull

  # baseline snapshot of org member-privilege settings.
  log_step "org member-privilege snapshot for '$ORG'"
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would read: gh api orgs/$ORG (default_repository_permission, members_can_create_repositories, ...)"
  else
    gh api "orgs/$ORG" \
      --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories, two_factor_requirement_enabled}' \
      2>/dev/null || log_warn "could not read org settings (needs admin:org / read:org)"
  fi
}

wth_teardown() {
  local r
  for r in "$R_PUB" "$R_PRIV" "$R_INT"; do
    guard_prefix "$r" "$CHID" || return 1
    gh_delete_repo "$ORG" "$r"
  done
  guard_prefix "$TEAM" "$CHID" || return 1
  gh_delete_team "$ORG" "$TEAM"
}

wth_status() {
  log_step "status — $CHID in '$ORG'"
  local r
  for r in "$R_PUB" "$R_PRIV" "$R_INT"; do
    if gh_repo_exists "$ORG" "$r"; then log_ok "repo $ORG/$r present"; else log_info "repo $ORG/$r absent"; fi
  done
  if gh_team_exists "$ORG" "$TEAM"; then log_ok "team $TEAM present"; else log_info "team $TEAM absent"; fi
}
