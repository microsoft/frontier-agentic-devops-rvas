#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] && shift

ORG=""
REPO="ghas-admin-02-secret-operations"
VISIBILITY="private"
JUICE_SHOP_REF="v20.0.0"
DRY_RUN="false"
ASSUME_YES="false"
UPSTREAM="https://github.com/juice-shop/juice-shop.git"
ISSUE_TITLE="GHAS Admin 02: secret protection operations evidence"
WORK_DIR=""

usage() {
  cat <<'EOF'
Usage:
  provision.sh <provision|status|teardown> --org <org> [options]

Options:
  --repo <name>          Repository name; must start with ghas-admin-02-
  --visibility <value>  private, internal, or public (default: private)
  --ref <tag>            Juice Shop tag (default: v20.0.0)
  --dry-run              Print the plan without changing GitHub
  --yes                  Confirm teardown
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --visibility) VISIBILITY="${2:-}"; shift 2 ;;
    --ref) JUICE_SHOP_REF="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --yes) ASSUME_YES="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$COMMAND" =~ ^(provision|status|teardown)$ ]] || {
  usage >&2
  exit 2
}
[[ -n "$ORG" ]] || { printf 'error: --org is required\n' >&2; exit 2; }
[[ "$REPO" == ghas-admin-02-* ]] || {
  printf 'error: repository name must start with ghas-admin-02-\n' >&2
  exit 2
}
[[ "$VISIBILITY" =~ ^(private|internal|public)$ ]] || {
  printf 'error: visibility must be private, internal, or public\n' >&2
  exit 2
}

repo_exists() {
  gh repo view "$ORG/$REPO" >/dev/null 2>&1
}

file_exists() {
  local path="$1" ref="${2:-main}"
  gh api "repos/$ORG/$REPO/contents/$path?ref=$ref" >/dev/null 2>&1
}

branch_exists() {
  gh api "repos/$ORG/$REPO/git/ref/heads/$1" >/dev/null 2>&1
}

issue_exists() {
  gh issue list --repo "$ORG/$REPO" --state all --search "$ISSUE_TITLE in:title" \
    --json title --jq ".[] | select(.title == \"$ISSUE_TITLE\") | .title" |
    grep -Fxq "$ISSUE_TITLE"
}

require_tools() {
  local tool
  for tool in gh git; do
    command -v "$tool" >/dev/null 2>&1 || {
      printf 'error: %s is required\n' "$tool" >&2
      exit 1
    }
  done
  gh auth status >/dev/null 2>&1 || {
    printf 'error: authenticate GitHub CLI before provisioning\n' >&2
    exit 1
  }
}

cleanup() {
  [[ -z "$WORK_DIR" ]] || rm -rf -- "$WORK_DIR"
}

assert_fixture() {
  local failed="false"
  repo_exists || { printf 'missing: repository %s/%s\n' "$ORG" "$REPO"; failed="true"; }
  if [[ "$failed" == "false" ]]; then
    file_exists "SECRETS-MANIFEST.md" || { printf 'missing: SECRETS-MANIFEST.md\n'; failed="true"; }
    file_exists "config/aws-legacy.ini" || { printf 'missing: config/aws-legacy.ini\n'; failed="true"; }
    file_exists "config/aws-build.ini" || { printf 'missing: config/aws-build.ini\n'; failed="true"; }
    file_exists "fixtures/internal-token.txt" || { printf 'missing: fixtures/internal-token.txt\n'; failed="true"; }
    branch_exists "seed/push-protection-history" || {
      printf 'missing: seed/push-protection-history\n'
      failed="true"
    }
    file_exists "config/aws-branch.ini" "seed/push-protection-history" || {
      printf 'missing: config/aws-branch.ini on seed/push-protection-history\n'
      failed="true"
    }
    issue_exists || { printf 'missing: evidence issue\n'; failed="true"; }
  fi
  [[ "$failed" == "false" ]] || return 1
  printf 'fixture ready: %s/%s\n' "$ORG" "$REPO"
}

write_seed_history() {
  local src="$1"
  local aws_id_one aws_secret_one aws_id_two aws_secret_two aws_id_branch aws_secret_branch
  aws_id_one='AKIA''IOSFODNN7EXAMPLE'
  aws_secret_one='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLE''KEY'
  aws_id_two='AKIA''ADMIN02SEED00001'
  aws_secret_two='Admin02SeedSecretValue000000000000000000'
  aws_id_branch='AKIA''ADMIN02BRANCH001'
  aws_secret_branch='Admin02BranchSecretValue0000000000000000'

  (
    cd "$src"
    git init -q
    git symbolic-ref HEAD refs/heads/main
    git add -A
    git -c user.name="ghas-admin-02-fixture" \
      -c user.email="ghas-admin-02-fixture@users.noreply.github.com" \
      commit -q -m "Import OWASP Juice Shop $JUICE_SHOP_REF for GHAS Admin 02"

    mkdir -p config
    cat > config/aws-legacy.ini <<EOF
; Synthetic GHAS Admin 02 fixture. Never issued.
[legacy-uploader]
aws_access_key_id = $aws_id_one
aws_secret_access_key = $aws_secret_one
EOF
    git add config/aws-legacy.ini
    git -c user.name="ghas-admin-02-fixture" \
      -c user.email="ghas-admin-02-fixture@users.noreply.github.com" \
      commit -q -m "Seed legacy credential history for GHAS Admin 02"

    cat > config/aws-build.ini <<EOF
; Synthetic GHAS Admin 02 fixture. Never issued.
[build-publisher]
aws_access_key_id = $aws_id_two
aws_secret_access_key = $aws_secret_two
EOF
    git add config/aws-build.ini
    git -c user.name="ghas-admin-02-fixture" \
      -c user.email="ghas-admin-02-fixture@users.noreply.github.com" \
      commit -q -m "Seed build credential history for GHAS Admin 02"

    mkdir -p fixtures
    printf '%s\n' 'RVAS_DEMO_ADMIN02HISTORYSEED01' > fixtures/internal-token.txt
    git add fixtures/internal-token.txt
    git -c user.name="ghas-admin-02-fixture" \
      -c user.email="ghas-admin-02-fixture@users.noreply.github.com" \
      commit -q -m "Seed custom pattern candidate for GHAS Admin 02"

    cat > SECRETS-MANIFEST.md <<'EOF'
# GHAS Admin 02 secrets manifest

All values are synthetic and were never issued. Reconcile each row with GitHub.

| Row | Location | Expected detection | Ref | Closure |
| --- | --- | --- | --- | --- |
| 1 | `config/aws-legacy.ini` | AWS credential pair | `main` history | `used_in_tests` |
| 2 | `config/aws-build.ini` | AWS credential pair | `main` history | `used_in_tests` |
| 3 | `fixtures/internal-token.txt` | `RVAS Admin 02 demo token` after publication | `main` | `used_in_tests` |
| 4 | `config/aws-branch.ini` | AWS credential pair | `seed/push-protection-history` | `used_in_tests` |

Do not copy detected values into issues, chat, or incident records.
EOF
    git add SECRETS-MANIFEST.md
    git -c user.name="ghas-admin-02-fixture" \
      -c user.email="ghas-admin-02-fixture@users.noreply.github.com" \
      commit -q -m "Add GHAS Admin 02 secrets manifest"

    git switch -q -c seed/push-protection-history
    cat > config/aws-branch.ini <<EOF
; Synthetic GHAS Admin 02 fixture. Never issued.
[branch-uploader]
aws_access_key_id = $aws_id_branch
aws_secret_access_key = $aws_secret_branch
EOF
    git add config/aws-branch.ini
    git -c user.name="ghas-admin-02-fixture" \
      -c user.email="ghas-admin-02-fixture@users.noreply.github.com" \
      commit -q -m "Seed branch credential history for GHAS Admin 02"
    git switch -q main
  )
}

provision() {
  require_tools
  if repo_exists; then
    printf 'repository exists; checking the fixture instead of changing it\n'
    assert_fixture
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'would import Juice Shop %s into %s/%s (%s)\n' \
      "$JUICE_SHOP_REF" "$ORG" "$REPO" "$VISIBILITY"
    printf 'would seed provider-pattern history, manifest, custom-pattern candidate, branch, and evidence issue\n'
    return
  fi

  local work src visibility_flag
  work="$(mktemp -d)"
  WORK_DIR="$work"
  trap cleanup EXIT
  src="$work/src"

  printf 'cloning Juice Shop %s\n' "$JUICE_SHOP_REF"
  git clone --quiet --depth 1 --branch "$JUICE_SHOP_REF" "$UPSTREAM" "$src"
  [[ -f "$src/LICENSE" ]] || {
    printf 'error: upstream LICENSE is missing\n' >&2
    exit 1
  }
  rm -rf "$src/.git"
  write_seed_history "$src"

  case "$VISIBILITY" in
    private) visibility_flag="--private" ;;
    internal) visibility_flag="--internal" ;;
    public) visibility_flag="--public" ;;
  esac

  (
    cd "$src"
    gh repo create "$ORG/$REPO" "$visibility_flag" \
      --description "Synthetic GHAS Admin 02 secret protection lab; safe to delete" \
      --source=. --remote=origin --push
    git push origin seed/push-protection-history
  )

  gh issue create --repo "$ORG/$REPO" --title "$ISSUE_TITLE" --body "$(cat <<'EOF'
Record evidence without pasting secret values.

- [ ] Secret scanning and push protection enabled
- [ ] SECRETS-MANIFEST.md reconciled to alert numbers
- [ ] Seeded alerts resolved with explicit reasons
- [ ] Clean push accepted
- [ ] Synthetic provider-pattern push blocked
- [ ] Delegated bypass reviewed by a different account
- [ ] Bypass alert verified through the API
- [ ] Custom pattern published and live alert verified
- [ ] Final UI and API alert state agree
- [ ] Real credential rotation, revocation, or incident handoff complete, if required

Mark a licensed feature blocked when GitHub does not make it available. A tabletop does not satisfy that item.
EOF
)"

  assert_fixture
}

status() {
  require_tools
  assert_fixture
}

teardown() {
  require_tools
  if ! repo_exists; then
    printf 'repository already absent: %s/%s\n' "$ORG" "$REPO"
    return
  fi
  [[ "$ASSUME_YES" == "true" ]] || {
    printf 'error: teardown requires --yes\n' >&2
    exit 2
  }
  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'would delete %s/%s\n' "$ORG" "$REPO"
    return
  fi
  gh repo delete "$ORG/$REPO" --yes
}

case "$COMMAND" in
  provision) provision ;;
  status) status ;;
  teardown) teardown ;;
esac
