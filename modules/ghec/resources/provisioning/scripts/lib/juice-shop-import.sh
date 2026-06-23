# shellcheck shell=bash
# juice-shop-import.sh — import OWASP Juice Shop at a pinned tag into a fresh,
# history-stripped, PUBLIC repo in the participant's org.
#
# NEVER vendor Juice Shop into this repo. We pull from the official upstream at
# runtime, pinned to a tag from versions.lock / meta.yml. Juice Shop is MIT —
# its LICENSE travels with the shallow clone and is preserved in the push.

JUICE_SHOP_UPSTREAM="https://github.com/juice-shop/juice-shop.git"

# juice_shop_import <org> <repo> <ref>
# Requires the caller to have set CHID (for the namespace guard), DRY_RUN.
juice_shop_import() {
  local org="$1" repo="$2" ref="$3"

  guard_prefix "$repo" "$CHID" || return 1

  if gh_repo_exists "$org" "$repo"; then
    log_ok "juice-shop repo $org/$repo already exists (skip import)"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_plan "would shallow-clone $JUICE_SHOP_UPSTREAM @ $ref"
    log_plan "would strip history, fresh git init, and push to $org/$repo (public, MIT preserved)"
    return 0
  fi

  command -v git >/dev/null 2>&1 || die "git is required for the Juice Shop import"

  local work
  work="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN

  log_step "cloning Juice Shop @ $ref (shallow, single tag)"
  if ! git clone --depth 1 --branch "$ref" "$JUICE_SHOP_UPSTREAM" "$work/src" 2>/dev/null; then
    die "failed to clone Juice Shop at ref '$ref' — verify the tag exists upstream"
  fi

  [[ -f "$work/src/LICENSE" ]] || log_warn "upstream LICENSE not found — verify MIT attribution manually"

  log_step "stripping history and re-initialising"
  rm -rf "$work/src/.git"
  (
    cd "$work/src"
    git init -q
    git symbolic-ref HEAD refs/heads/main
    git add -A
    git -c user.name="wth-bot" -c user.email="wth-bot@users.noreply.github.com" \
        commit -q -m "Import OWASP Juice Shop ${ref} (MIT) for wth challenge"
  )

  log_step "creating public repo $org/$repo and pushing"
  gh repo create "$org/$repo" --public \
    --description "OWASP Juice Shop ${ref} (MIT) — wth challenge target, safe to delete" \
    >/dev/null

  (
    cd "$work/src"
    git remote add origin "https://github.com/$org/$repo.git"
    git push -u origin main >/dev/null 2>&1
  )

  log_ok "imported Juice Shop ${ref} -> $org/$repo (LICENSE preserved)"
}
