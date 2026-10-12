#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] && shift

ORG=""
REPO="ghas-admin-05-dependency-visibility-fixture"
JUICE_SHOP_REF="v20.0.0"
DRY_RUN="false"
ASSUME_YES="false"
UPSTREAM="https://github.com/juice-shop/juice-shop.git"

usage() {
  cat <<'EOF'
Usage:
  provision.sh <provision|status|teardown> --org <org> [options]

Options:
  --repo <name>   Repository name. Must start with ghas-admin-05-.
  --ref <tag>     Juice Shop tag. Default: v20.0.0.
  --dry-run       Print planned mutations.
  --yes           Confirm teardown without a prompt.
EOF
}

log() { printf '[%s] %s\n' "$1" "$2" >&2; }
die() { log fail "$1"; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --ref) JUICE_SHOP_REF="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --yes) ASSUME_YES="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ "$COMMAND" =~ ^(provision|status|teardown)$ ]] || { usage; exit 1; }
[[ -n "$ORG" ]] || die "--org is required"
[[ "$REPO" == ghas-admin-05-* ]] || die "repository must start with ghas-admin-05-"

FULL_REPO="$ORG/$REPO"

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log plan "$*"
    return 0
  fi
  "$@"
}

repo_exists() {
  gh repo view "$FULL_REPO" >/dev/null 2>&1
}

file_exists() {
  local path="$1" ref="${2:-main}"
  gh api "repos/$FULL_REPO/contents/$path?ref=$ref" >/dev/null 2>&1
}

put_file() {
  local path="$1" message="$2" content="$3" branch="${4:-main}" encoded
  if file_exists "$path" "$branch"; then
    log ok "$path already exists on $branch"
    return
  fi
  encoded="$(printf '%s' "$content" | base64 | tr -d '\n')"
  run gh api --method PUT "repos/$FULL_REPO/contents/$path" \
    -f message="$message" -f content="$encoded" -f branch="$branch" >/dev/null
}

branch_exists() {
  gh api "repos/$FULL_REPO/git/ref/heads/$1" >/dev/null 2>&1
}

create_branch() {
  local branch="$1" sha
  if branch_exists "$branch"; then
    log ok "$branch already exists"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log plan "create $branch from main"
    return
  fi
  sha="$(gh api "repos/$FULL_REPO/git/ref/heads/main" --jq '.object.sha')"
  gh api --method POST "repos/$FULL_REPO/git/refs" \
    -f ref="refs/heads/$branch" -f sha="$sha" >/dev/null
}

create_repo_with_fallback() {
  local output
  if run gh repo create "$FULL_REPO" --public \
    --description "GHAS dependency visibility fixture; safe to delete"; then
    return
  fi
  [[ "$DRY_RUN" == "true" ]] && return
  output="$(gh repo create "$FULL_REPO" --private \
    --description "GHAS dependency visibility fixture; safe to delete" 2>&1)" \
    || die "could not create public or private repository: $output"
  log warn "public repository creation failed; created private repository instead"
  log warn "private dependency review requires GitHub Code Security"
}

import_juice_shop() {
  local work src
  if repo_exists; then
    log ok "$FULL_REPO already exists"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log plan "import Juice Shop $JUICE_SHOP_REF from $UPSTREAM into $FULL_REPO"
    create_repo_with_fallback
    return
  fi

  work="$(mktemp -d)"
  src="$work/src"
  trap 'rm -rf "$work"; trap - RETURN' RETURN

  git clone --depth 1 --branch "$JUICE_SHOP_REF" "$UPSTREAM" "$src"
  [[ -f "$src/LICENSE" ]] || die "upstream Juice Shop license is missing"
  rm -rf "$src/.git"
  (
    cd "$src"
    git init -q
    git symbolic-ref HEAD refs/heads/main
    git add -A
    git -c user.name="ghas-fixture" \
      -c user.email="ghas-fixture@users.noreply.github.com" \
      commit -q -m "Import OWASP Juice Shop $JUICE_SHOP_REF for GHAS lab"
  )

  create_repo_with_fallback
  gh auth setup-git
  (
    cd "$src"
    git remote add origin "https://github.com/$FULL_REPO.git"
    git push --set-upstream origin main
  )
  log ok "imported Juice Shop $JUICE_SHOP_REF into $FULL_REPO"
}

vulnerable_package_json() {
  cat <<'EOF'
{
  "name": "ghas-admin-05-vulnerable-dependencies",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "bash ./build.sh"
  },
  "dependencies": {
    "lodash": "4.17.4",
    "marked": "0.3.6",
    "minimist": "0.0.8"
  }
}
EOF
}

vulnerable_lock_json() {
  cat <<'EOF'
{
  "name": "ghas-admin-05-vulnerable-dependencies",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "ghas-admin-05-vulnerable-dependencies",
      "version": "1.0.0",
      "dependencies": {
        "lodash": "4.17.4",
        "marked": "0.3.6",
        "minimist": "0.0.8"
      }
    },
    "node_modules/lodash": {
      "version": "4.17.4",
      "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.4.tgz",
      "integrity": "sha512-6X37Sq9KCpLSXEh8uM12AKYlviHPNNk4RxiGBn4cmKGJinbXBneWIV7iE/nXkM928O7ytHcHb6+X6Svl0f4hXg=="
    },
    "node_modules/marked": {
      "version": "0.3.6",
      "resolved": "https://registry.npmjs.org/marked/-/marked-0.3.6.tgz",
      "integrity": "sha512-gE75oL01YUIxaBqgeGBuNNd8u0L+H1N6xeW/s+O57o5EC31aPX1M1lD4W9eGyHFJGTwOgMkqzYODZ4yp5w20gQ==",
      "bin": {
        "marked": "bin/marked"
      }
    },
    "node_modules/minimist": {
      "version": "0.0.8",
      "resolved": "https://registry.npmjs.org/minimist/-/minimist-0.0.8.tgz",
      "integrity": "sha512-miQKw5Hv4NS1Psg2517mV4e4dYNaO3++hjAvLOAzKqZ61rH8NS1SK+vbfBWZ5PY/Me/bEWhUwqMghEW5Fb9T7Q=="
    }
  }
}
EOF
}

risky_package_json() {
  cat <<'EOF'
{
  "name": "ghas-admin-05-risky-change",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "lodash": "4.17.4"
  }
}
EOF
}

risky_lock_json() {
  cat <<'EOF'
{
  "name": "ghas-admin-05-risky-change",
  "version": "1.0.0",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "ghas-admin-05-risky-change",
      "version": "1.0.0",
      "dependencies": {
        "lodash": "4.17.4"
      }
    },
    "node_modules/lodash": {
      "version": "4.17.4",
      "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.4.tgz",
      "integrity": "sha512-6X37Sq9KCpLSXEh8uM12AKYlviHPNNk4RxiGBn4cmKGJinbXBneWIV7iE/nXkM928O7ytHcHb6+X6Svl0f4hXg=="
    }
  }
}
EOF
}

seed_fixture() {
  put_file "dependency-lab/package.json" \
    "Add vulnerable dependency fixture" "$(vulnerable_package_json)"
  put_file "dependency-lab/package-lock.json" \
    "Lock vulnerable dependency fixture" "$(vulnerable_lock_json)"
  put_file "dependency-lab/build.sh" \
    "Add build-resolved dependency" \
    $'#!/usr/bin/env bash\nset -euo pipefail\nnpx --yes cowsay@1.6.0 "GHAS dependency fixture build"\n'
  put_file "dependency-lab/build-resolved-components.json" \
    "Record build-resolved dependency" \
    $'{\n  "components": [\n    {\n      "name": "cowsay",\n      "version": "1.6.0",\n      "package_url": "pkg:npm/cowsay@1.6.0",\n      "scope": "development"\n    }\n  ]\n}\n'

  create_branch "feature/risky-dependency"
  put_file "risky-dependency/package.json" \
    "Add risky dependency for dependency review" "$(risky_package_json)" \
    "feature/risky-dependency"
  put_file "risky-dependency/package-lock.json" \
    "Lock risky dependency for dependency review" "$(risky_lock_json)" \
    "feature/risky-dependency"
}

status() {
  if ! repo_exists; then
    log fail "$FULL_REPO is missing"
    return 1
  fi

  local failed=0 path
  for path in \
    dependency-lab/package.json \
    dependency-lab/package-lock.json \
    dependency-lab/build.sh \
    dependency-lab/build-resolved-components.json; do
    if file_exists "$path"; then
      log ok "$path is present"
    else
      log fail "$path is missing"
      failed=1
    fi
  done

  if branch_exists "feature/risky-dependency" &&
    file_exists "risky-dependency/package.json" "feature/risky-dependency" &&
    file_exists "risky-dependency/package-lock.json" "feature/risky-dependency"; then
    log ok "feature/risky-dependency is ready"
  else
    log fail "feature/risky-dependency is incomplete"
    failed=1
  fi
  return "$failed"
}

teardown() {
  if ! repo_exists; then
    log ok "$FULL_REPO is already absent"
    return
  fi
  if [[ "$ASSUME_YES" != "true" ]]; then
    die "teardown requires --yes"
  fi
  run gh repo delete "$FULL_REPO" --yes
}

for tool in gh git jq; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is required"
done

case "$COMMAND" in
  provision)
    if [[ "$DRY_RUN" != "true" ]]; then
      gh auth status >/dev/null 2>&1 || die "authenticate GitHub CLI first"
    fi
    import_juice_shop
    seed_fixture
    if [[ "$DRY_RUN" == "true" ]]; then
      log ok "dry-run complete for $FULL_REPO"
      exit 0
    fi
    status
    log ok "fixture ready: $FULL_REPO"
    ;;
  status)
    status
    ;;
  teardown)
    teardown
    ;;
esac
