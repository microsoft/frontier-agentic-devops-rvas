# shellcheck shell=bash
# gh.sh — thin, idempotent wrappers over the gh CLI.
# Every wrapper is check-then-act so re-running setup reconciles instead of
# erroring, and every mutation is routed through run_mutation (dry-run aware).

gh_repo_exists() {
  gh repo view "$1/$2" >/dev/null 2>&1
}

# gh_create_repo <org> <repo> [visibility=public]
gh_create_repo() {
  local org="$1" repo="$2" vis="${3:-public}"
  if gh_repo_exists "$org" "$repo"; then
    log_ok "repo $org/$repo already exists (skip)"
    return 0
  fi
  run_mutation gh repo create "$org/$repo" "--$vis" \
    --description "wth challenge artifact — safe to delete via teardown"
}

# gh_delete_repo <org> <repo>
gh_delete_repo() {
  local org="$1" repo="$2"
  if ! gh_repo_exists "$org" "$repo"; then
    log_ok "repo $org/$repo absent (skip)"
    return 0
  fi
  run_mutation gh repo delete "$org/$repo" --yes
}

# gh_file_exists <org> <repo> <path> [ref] -> 0 if the file exists on that ref.
gh_file_exists() {
  local org="$1" repo="$2" path="$3" ref="${4:-}"
  local url="repos/$org/$repo/contents/$path"
  [[ -n "$ref" ]] && url="$url?ref=$ref"
  gh api "$url" >/dev/null 2>&1
}

# gh_put_file <org> <repo> <path> <message> <content> [branch]
# create-if-absent (idempotent): commits a new file via the Contents API, but
# skips when the path already exists on the target ref. dry-run aware.
gh_put_file() {
  local org="$1" repo="$2" path="$3" message="$4" content="$5" branch="${6:-}"
  if gh_file_exists "$org" "$repo" "$path" "$branch"; then
    log_ok "file '$path'${branch:+ on $branch} exists (skip)"
    return 0
  fi
  local b64
  b64="$(printf '%s' "$content" | base64 | tr -d '\n')"
  local args=(gh api -X PUT "repos/$org/$repo/contents/$path"
    -f message="$message" -f content="$b64")
  [[ -n "$branch" ]] && args+=(-f branch="$branch")
  run_mutation "${args[@]}"
}

# gh_branch_exists <org> <repo> <branch> -> 0 if the branch ref exists.
gh_branch_exists() {
  gh api "repos/$1/$2/git/ref/heads/$3" >/dev/null 2>&1
}

# gh_create_branch <org> <repo> <branch> [base=main]
# create-if-absent: cuts <branch> from <base>'s current tip. dry-run aware.
gh_create_branch() {
  local org="$1" repo="$2" branch="$3" base="${4:-main}"
  if gh_branch_exists "$org" "$repo" "$branch"; then
    log_ok "branch '$branch' exists (skip)"
    return 0
  fi
  local sha
  sha="$(gh api "repos/$org/$repo/git/ref/heads/$base" --jq '.object.sha' 2>/dev/null || true)"
  if [[ -z "$sha" ]]; then
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      log_plan "would create branch '$branch' from '$base'"
      return 0
    fi
    log_warn "cannot resolve '$base' tip — skipping branch '$branch'"
    return 0
  fi
  run_mutation gh api -X POST "repos/$org/$repo/git/refs" \
    -f ref="refs/heads/$branch" -f sha="$sha"
}

# gh_upsert_file <org> <repo> <path> <message> <content> <branch>
# create-OR-update a file on <branch> via the Contents API (fetches the blob
# sha when the path already exists). Used to engineer divergence/conflicts.
# Routed through run_mutation; dry-run aware.
gh_upsert_file() {
  local org="$1" repo="$2" path="$3" message="$4" content="$5" branch="$6"
  local b64 sha
  b64="$(printf '%s' "$content" | base64 | tr -d '\n')"
  sha="$(gh api "repos/$org/$repo/contents/$path?ref=$branch" --jq '.sha' 2>/dev/null || true)"
  local args=(gh api -X PUT "repos/$org/$repo/contents/$path"
    -f message="$message" -f content="$b64" -f branch="$branch")
  [[ -n "$sha" ]] && args+=(-f sha="$sha")
  run_mutation "${args[@]}"
}

# gh_file_contains <org> <repo> <path> <needle> [ref] -> 0 if <needle> is in file.
# Read-only; returns non-zero (false) when the file/repo is absent (e.g. dry-run).
gh_file_contains() {
  local org="$1" repo="$2" path="$3" needle="$4" ref="${5:-}"
  local url="repos/$org/$repo/contents/$path" content
  [[ -n "$ref" ]] && url="$url?ref=$ref"
  content="$(gh api "$url" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)"
  printf '%s' "$content" | grep -q -- "$needle"
}

# gh_open_pr <org> <repo> <head> <base> <title> <body> [--draft]
# create-if-absent: skips when a PR already exists for <head>. dry-run aware.
gh_open_pr() {
  local org="$1" repo="$2" head="$3" base="$4" title="$5" body="$6" draft="${7:-}"
  local existing
  existing="$(gh pr list --repo "$org/$repo" --head "$head" --state all \
    --json number --jq 'length' 2>/dev/null || echo 0)"
  if [[ "${existing:-0}" != "0" ]]; then
    log_ok "PR for head '$head' exists (skip)"
    return 0
  fi
  local args=(gh pr create --repo "$org/$repo" --head "$head" --base "$base"
    --title "$title" --body "$body")
  [[ "$draft" == "--draft" ]] && args+=(--draft)
  run_mutation "${args[@]}"
}

# gh_create_repo_soft <org> <repo> [visibility=public]
# Like gh_create_repo but TOLERATES failure (e.g. --internal needs an
# enterprise-owned org). Emits a manual-step warning instead of aborting.
gh_create_repo_soft() {
  local org="$1" repo="$2" vis="${3:-public}"
  if gh_repo_exists "$org" "$repo"; then
    log_ok "repo $org/$repo already exists (skip)"
    return 0
  fi
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_plan "would create $vis repo $org/$repo"
    return 0
  fi
  if gh repo create "$org/$repo" "--$vis" \
      --description "wth challenge artifact — safe to delete via teardown" 2>/dev/null; then
    log_ok "created $vis repo $org/$repo"
  else
    log_warn "could not create '$vis' repo $org/$repo — visibility '$vis' may require an enterprise-owned org (MANUAL STEP)"
  fi
}

# ---- teams -----------------------------------------------------------------
# gh_team_exists <org> <team-slug> -> 0 if the team exists.
gh_team_exists() {
  gh api "orgs/$1/teams/$2" >/dev/null 2>&1
}

# gh_create_team <org> <name> [description] — create-if-absent. dry-run aware.
gh_create_team() {
  local org="$1" name="$2" desc="${3:-wth challenge team — safe to delete via teardown}"
  if gh_team_exists "$org" "$name"; then
    log_ok "team '$name' exists (skip)"
    return 0
  fi
  run_mutation gh api -X POST "orgs/$org/teams" \
    -f name="$name" -f description="$desc" -f privacy=closed
}

# gh_delete_team <org> <team-slug> — delete-if-present. dry-run aware.
gh_delete_team() {
  local org="$1" name="$2"
  if ! gh_team_exists "$org" "$name"; then
    log_ok "team '$name' absent (skip)"
    return 0
  fi
  run_mutation gh api -X DELETE "orgs/$org/teams/$name"
}

# gh_team_add_repo <org> <team-slug> <repo> [permission=pull]
gh_team_add_repo() {
  local org="$1" team="$2" repo="$3" perm="${4:-pull}"
  run_mutation gh api -X PUT "orgs/$org/teams/$team/repos/$org/$repo" \
    -f permission="$perm"
}

# gh_team_add_member <org> <team-slug> <username> [role=member]
gh_team_add_member() {
  local org="$1" team="$2" user="$3" role="${4:-member}"
  run_mutation gh api -X PUT "orgs/$org/teams/$team/memberships/$user" \
    -f role="$role"
}

# gh_version -> prints the numeric gh version (e.g. 2.62.0)
gh_version() {
  gh --version 2>/dev/null | awk 'NR==1{print $3}'
}

# version_ge <a> <b> -> 0 if a >= b (dotted semver compare)
version_ge() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}
