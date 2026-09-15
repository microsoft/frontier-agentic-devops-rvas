#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared fixture for ghas-admin-01 and ghas-admin-06.
# Imports OWASP Juice Shop at a pinned tag and seeds a mixed GHAS alert corpus.

set -euo pipefail

COMMAND=""
ORG=""
JUICE_SHOP_REF="v20.0.0"
DRY_RUN="false"
ASSUME_YES="false"
PREFIX="ghas-admin-01-06-"
REPO="${PREFIX}security-operations"
CONFIG_BRANCH="ghas-admin-01-detachment-repair"
CAMPAIGN_BRANCH="ghas-admin-06-campaign-remediation"
UPSTREAM="https://github.com/juice-shop/juice-shop.git"
AWS_KEY_ID="AKIA""IOSFODNN7EXAMPLE"
AWS_SECRET="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLE""KEY"

usage() {
  cat <<'EOF'
Usage:
  provision.sh <provision|status|teardown> --org <org> [--ref <tag>] [--dry-run] [--yes]

The fixture owns only repositories whose names start with ghas-admin-01-06-.
EOF
}

log() { printf '[ghas-admin-01-06] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    provision|status|teardown) COMMAND="$1"; shift ;;
    --org) ORG="${2:-}"; shift 2 ;;
    --ref) JUICE_SHOP_REF="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --yes) ASSUME_YES="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$COMMAND" ]] || die "missing command"
[[ -n "$ORG" ]] || die "--org <org> is required"
[[ "$REPO" == "$PREFIX"* ]] || die "unsafe repository name: $REPO"

repo_exists() {
  gh repo view "$ORG/$REPO" >/dev/null 2>&1
}

branch_exists() {
  gh api "repos/$ORG/$REPO/git/ref/heads/$1" >/dev/null 2>&1
}

file_exists() {
  local path="$1" branch="${2:-main}"
  gh api "repos/$ORG/$REPO/contents/$path?ref=$branch" >/dev/null 2>&1
}

put_file() {
  local path="$1" message="$2" content="$3" branch="${4:-main}"
  if file_exists "$path" "$branch"; then
    log "file $path on $branch exists; skipping"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "would create $path on $branch"
    return
  fi
  local encoded
  encoded="$(printf '%s' "$content" | base64 | tr -d '\n')"
  gh api -X PUT "repos/$ORG/$REPO/contents/$path" \
    -f message="$message" -f content="$encoded" -f branch="$branch" >/dev/null
}

create_branch() {
  local branch="$1"
  if branch_exists "$branch"; then
    log "branch $branch exists; skipping"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "would create branch $branch from main"
    return
  fi
  local sha
  sha="$(gh api "repos/$ORG/$REPO/git/ref/heads/main" --jq '.object.sha')"
  gh api -X POST "repos/$ORG/$REPO/git/refs" \
    -f ref="refs/heads/$branch" -f sha="$sha" >/dev/null
}

create_issue() {
  local title="$1" body="$2"
  local found
  found="$(gh issue list --repo "$ORG/$REPO" --state all --limit 100 \
    --json title --jq ".[] | select(.title == \"$title\") | .title" 2>/dev/null || true)"
  if [[ "$found" == "$title" ]]; then
    log "issue '$title' exists; skipping"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "would create issue '$title'"
    return
  fi
  gh issue create --repo "$ORG/$REPO" --title "$title" --body "$body" >/dev/null
}

issue_exists() {
  local title="$1"
  gh issue list --repo "$ORG/$REPO" --state all --limit 100 \
    --json title --jq ".[] | select(.title == \"$title\") | .title" 2>/dev/null \
    | grep -Fxq "$title"
}

import_juice_shop() {
  if repo_exists; then
    log "repository $ORG/$REPO exists; skipping import"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "would import OWASP Juice Shop $JUICE_SHOP_REF into $ORG/$REPO"
    return
  fi

  (
    local work src
    work="$(mktemp -d)"
    src="$work/src"
    trap 'find "$work" -depth -delete 2>/dev/null || true' EXIT

    git clone --quiet --depth 1 --branch "$JUICE_SHOP_REF" "$UPSTREAM" "$src" \
      || die "failed to clone OWASP Juice Shop at $JUICE_SHOP_REF"
    [[ -f "$src/LICENSE" ]] || die "upstream LICENSE is missing"

    find "$src/.git" -depth -delete
    git -C "$src" init --quiet
    git -C "$src" symbolic-ref HEAD refs/heads/main
    git -C "$src" add -A
    git -C "$src" -c user.name="ghas-fixture-bot" \
      -c user.email="ghas-fixture-bot@users.noreply.github.com" \
      commit --quiet -m "Import OWASP Juice Shop $JUICE_SHOP_REF for GHAS admin labs"

    if ! gh repo create "$ORG/$REPO" --public \
      --description "GHAS admin 01 and 06 fixture; safe to delete with its provisioner" >/dev/null 2>&1; then
      log "public repository creation failed; trying private visibility"
      gh repo create "$ORG/$REPO" --private \
        --description "GHAS admin 01 and 06 fixture; safe to delete with its provisioner" >/dev/null
    fi

    gh auth setup-git >/dev/null
    git -C "$src" remote add origin "https://github.com/$ORG/$REPO.git"
    git -C "$src" push --quiet -u origin main
  )
  log "imported OWASP Juice Shop $JUICE_SHOP_REF into $ORG/$REPO"
}

seed_corpus() {
  local codeql dependabot credentials manifest config_note campaign_note expiry
  codeql='name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 6 * * 1"
permissions:
  contents: read
  security-events: write
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3'
  dependabot='version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"'
  credentials="; ghas-admin-06 planted NON-LIVE example secret
[default]
aws_access_key_id = $AWS_KEY_ID
aws_secret_access_key = $AWS_SECRET"
  manifest="$(cat <<'EOF'
# GHAS admin 01 and 06 alert corpus

This repository is a controlled training fixture.

| Source | Seed |
| --- | --- |
| Code scanning | CodeQL workflow plus OWASP Juice Shop source |
| Dependabot | Dependabot configuration plus the pinned Juice Shop dependency tree |
| Secret scanning | One non-live AWS example key in `config/aws-credentials.ini` |

Use `ghas-admin-01` for security configuration attachment work. Use `ghas-admin-06` for Security Overview, delegated triage, and a live campaign.
EOF
)"
  config_note="$(cat <<'EOF'
# Configuration attachment repair

Use this branch to record the observed attachment state, failure or detachment, repair, final state, and rollout decision for `ghas-admin-01`.
EOF
)"
  campaign_note="$(cat <<'EOF'
# Campaign remediation

Use this branch for reviewed fixes created during `ghas-admin-06`. Merge at least one alert fix to `main`, then wait for the scan before measuring burn-down.
EOF
)"

  put_file ".github/workflows/codeql.yml" "Add CodeQL alert corpus" "$codeql"
  put_file ".github/dependabot.yml" "Add Dependabot alert corpus" "$dependabot"
  put_file "config/aws-credentials.ini" "Add non-live secret scanning seed" "$credentials"
  put_file "SECURITY-CORPUS.md" "Document GHAS admin alert corpus" "$manifest"

  create_branch "$CONFIG_BRANCH"
  create_branch "$CAMPAIGN_BRANCH"
  put_file "GHAS-ADMIN-01-DETACHMENT-REPAIR.md" \
    "Add configuration repair worksheet" "$config_note" "$CONFIG_BRANCH"
  put_file "GHAS-ADMIN-06-CAMPAIGN-REMEDIATION.md" \
    "Add campaign remediation worksheet" "$campaign_note" "$CAMPAIGN_BRANCH"

  if date -u -d '+30 days' +%F >/dev/null 2>&1; then
    expiry="$(date -u -d '+30 days' +%F)"
  elif date -u -v+30d +%F >/dev/null 2>&1; then
    expiry="$(date -u -v+30d +%F)"
  else
    expiry="<set to 30 days from provisioning>"
  fi

  create_issue "ghas-admin-01: configuration attachment repair" \
"Record the live configuration ID, attachment status history, failure or detachment, repair, and final enforce-or-rollback decision.

Repository: $ORG/$REPO
Repair branch: $CONFIG_BRANCH"

  create_issue "ghas-admin-06: expiring exception and campaign burn-down" \
"Record the published campaign URL, developer access result, delegated decision, and measured burn-down.

Repository: $ORG/$REPO
Remediation branch: $CAMPAIGN_BRANCH
Exception expiry: $expiry
Replace this template date if the exception is created later."
}

provision() {
  import_juice_shop
  if [[ "$DRY_RUN" != "true" ]] && ! repo_exists; then
    die "repository is missing after import"
  fi
  seed_corpus
  log "next: enable the approved security features and wait for the alert corpus"
  log "next: run ghas-admin-01 before ghas-admin-06"
}

status() {
  if ! repo_exists; then
    log "repository $ORG/$REPO is absent"
    return 1
  fi
  local failed=0
  for path in \
    ".github/workflows/codeql.yml:main" \
    ".github/dependabot.yml:main" \
    "config/aws-credentials.ini:main" \
    "SECURITY-CORPUS.md:main" \
    "GHAS-ADMIN-01-DETACHMENT-REPAIR.md:$CONFIG_BRANCH" \
    "GHAS-ADMIN-06-CAMPAIGN-REMEDIATION.md:$CAMPAIGN_BRANCH"; do
    local file="${path%%:*}" branch="${path#*:}"
    if file_exists "$file" "$branch"; then
      log "$branch:$file present"
    else
      log "$branch:$file MISSING"
      failed=1
    fi
  done
  for branch in "$CONFIG_BRANCH" "$CAMPAIGN_BRANCH"; do
    branch_exists "$branch" || { log "branch $branch MISSING"; failed=1; }
  done
  for title in \
    "ghas-admin-01: configuration attachment repair" \
    "ghas-admin-06: expiring exception and campaign burn-down"; do
    issue_exists "$title" || { log "issue '$title' MISSING"; failed=1; }
  done
  [[ "$failed" -eq 0 ]] && log "fixture ready: $ORG/$REPO"
  return "$failed"
}

teardown() {
  if ! repo_exists; then
    log "repository $ORG/$REPO is absent"
    return
  fi
  if [[ "$ASSUME_YES" != "true" ]]; then
    die "teardown requires --yes"
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "would delete $ORG/$REPO"
    return
  fi
  gh repo delete "$ORG/$REPO" --yes
  log "deleted $ORG/$REPO"
}

if [[ "$DRY_RUN" != "true" ]]; then
  command -v gh >/dev/null 2>&1 || die "gh is required"
  command -v git >/dev/null 2>&1 || die "git is required"
  gh auth status >/dev/null 2>&1 || die "authenticate gh before running this fixture"
fi

case "$COMMAND" in
  provision) provision ;;
  status) status ;;
  teardown) teardown ;;
esac
