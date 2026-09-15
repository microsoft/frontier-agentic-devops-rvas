#!/usr/bin/env bash
#
# Creates the live CodeQL fixture for ghas-admin-03 and ghas-admin-04.
# The advanced workflow stays on a recovery branch so participants must start
# with default setup. Teardown removes fixture artifacts, never the repository.

set -euo pipefail

ACTION="${1:-provision}"
[[ $# -gt 0 ]] && shift

ORG=""
REPO="ghas-admin-03-04-codeql-live-lab"
JUICE_SHOP_REF="v20.0.0"
DRY_RUN="false"
ASSUME_YES="false"

WORKFLOW_BRANCH="codeql/advanced-setup"
VULNERABLE_BRANCH="codeql/vulnerable-pr"
COVERAGE_PATH="tools/ghas_codeql_coverage_probe.py"
VULNERABLE_PATH="routes/ghasCodeqlLookup.js"
ISSUE_TITLE="GHAS CodeQL live lab: coverage, Autofix, and merge enforcement"
PR_TITLE="Add insecure product lookup for CodeQL enforcement test"

usage() {
  cat <<'EOF'
Usage:
  provision.sh <provision|status|teardown|render-workflow|render-fix> [options]

Options:
  --org <org>       Target organization
  --repo <repo>     Target repository (default: ghas-admin-03-04-codeql-live-lab)
  --ref <ref>       Juice Shop ref used when creating the repo (default: v20.0.0)
  --dry-run         Print mutations without running them
  --yes             Confirm fixture-artifact teardown
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --ref) JUICE_SHOP_REF="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --yes) ASSUME_YES="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

render_workflow() {
  cat <<'EOF'
name: CodeQL

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  merge_group:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:

permissions: {}

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    strategy:
      fail-fast: false
      matrix:
        language:
          - javascript-typescript
          - python
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v4
        with:
          languages: ${{ matrix.language }}
          build-mode: none
          queries: security-extended
      - name: Perform CodeQL analysis
        uses: github/codeql-action/analyze@v4
        with:
          category: /language:${{ matrix.language }}
EOF
}

render_coverage_probe() {
  cat <<'EOF'
"""Small source file used to verify that CodeQL covers the tools root."""


def normalized_name(value: str) -> str:
    return value.strip().lower()
EOF
}

render_vulnerability() {
  cat <<'EOF'
// ghas-admin-04 fixture. Deliberately vulnerable. Do not ship.
const express = require('express')
const sqlite3 = require('sqlite3')
const router = express.Router()

router.get('/ghas-codeql-lookup', (req, res) => {
  const db = new sqlite3.Database(':memory:')
  const query = "SELECT * FROM Products WHERE name = '" + req.query.name + "'"
  db.all(query, (err, rows) => {
    res.send('<h1>Results for ' + req.query.name + '</h1>' + JSON.stringify(rows || err))
  })
})

module.exports = router
EOF
}

render_fix() {
  cat <<'EOF'
const express = require('express')
const sqlite3 = require('sqlite3')
const router = express.Router()

router.get('/ghas-codeql-lookup', (req, res) => {
  const db = new sqlite3.Database(':memory:')
  db.all(
    'SELECT * FROM Products WHERE name = ?',
    [req.query.name],
    (err, rows) => {
      if (err) {
        res.status(500).json({ error: 'lookup failed' })
        return
      }
      res.json({ query: req.query.name, rows })
    }
  )
})

module.exports = router
EOF
}

render_issue() {
  cat <<EOF
This fixture supports \`ghas-admin-03\` and \`ghas-admin-04\`.

Repository state:

- \`main\` contains \`$COVERAGE_PATH\` and no advanced CodeQL workflow.
- \`$WORKFLOW_BRANCH\` contains the advanced-setup recovery workflow.
- \`$VULNERABLE_BRANCH\` contains \`$VULNERABLE_PATH\`.
- The open pull request from \`$VULNERABLE_BRANCH\` is the merge-enforcement test.

Start with CodeQL default setup. Configure JavaScript/TypeScript only for the first
run, find the missing Python coverage, add Python, and run CodeQL again.

Keep the vulnerable pull request unchanged during ghas-admin-03. In ghas-admin-04,
activate Require code scanning results, prove that the pull request is blocked, then
replace \`$VULNERABLE_PATH\` with the output of:

\`\`\`bash
bash provision.sh render-fix
\`\`\`

A workflow stored only on \`$WORKFLOW_BRANCH\` is a recovery fixture. It does not
count as a live scan until an administrator restores it to \`main\` and completes a
run.
EOF
}

if [[ "$ACTION" == "render-workflow" ]]; then render_workflow; exit 0; fi
if [[ "$ACTION" == "render-fix" ]]; then render_fix; exit 0; fi

case "$ACTION" in
  provision|status|teardown) ;;
  *) echo "Unknown action: $ACTION" >&2; usage >&2; exit 1 ;;
esac

[[ -n "$ORG" ]] || { echo "--org is required for $ACTION" >&2; exit 1; }

FULL_REPO="$ORG/$REPO"

for tool in gh git base64; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "Required tool not found: $tool" >&2
    exit 1
  }
done

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

repo_exists() {
  gh repo view "$FULL_REPO" >/dev/null 2>&1
}

create_repo_if_missing() {
  if repo_exists; then
    echo "Repository exists: $FULL_REPO"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN: import juice-shop/juice-shop@$JUICE_SHOP_REF into $FULL_REPO"
    return
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN
  git clone --quiet --depth 1 --branch "$JUICE_SHOP_REF" \
    https://github.com/juice-shop/juice-shop.git "$temp_dir"
  git -C "$temp_dir" checkout -q -B main
  git -C "$temp_dir" remote remove origin
  gh repo create "$FULL_REPO" --public --source "$temp_dir" --remote origin --push \
    --description "GHAS CodeQL live administration lab"
  rm -rf "$temp_dir"
  trap - RETURN
}

enable_security_features() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN: enable Actions and available security features on $FULL_REPO"
    return
  fi

  gh api -X PUT "repos/$FULL_REPO/actions/permissions" \
    -F enabled=true -f allowed_actions=all >/dev/null

  if ! gh api -X PATCH "repos/$FULL_REPO" \
    -F 'security_and_analysis[advanced_security][status]=enabled' >/dev/null 2>&1; then
    echo "Warning: GitHub did not accept the advanced-security update. Public repositories can still use CodeQL." >&2
  fi
}

branch_exists() {
  gh api "repos/$FULL_REPO/git/ref/heads/$1" >/dev/null 2>&1
}

ensure_branch() {
  local branch="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN: ensure branch $branch from main"
    return
  fi

  if branch_exists "$branch"; then
    echo "Branch exists: $branch"
    return
  fi

  local main_sha
  main_sha="$(gh api "repos/$FULL_REPO/git/ref/heads/main" --jq '.object.sha')"
  run gh api -X POST "repos/$FULL_REPO/git/refs" \
    -f "ref=refs/heads/$branch" -f "sha=$main_sha" >/dev/null
}

put_file() {
  local branch="$1" path="$2" message="$3" content="$4"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN: put $path on $branch"
    return
  fi

  local encoded sha
  encoded="$(printf '%s' "$content" | base64 | tr -d '\n')"
  sha="$(gh api "repos/$FULL_REPO/contents/$path?ref=$branch" --jq '.sha' 2>/dev/null || true)"

  local args=(-X PUT "repos/$FULL_REPO/contents/$path" -f "message=$message" -f "content=$encoded" -f "branch=$branch")
  [[ -n "$sha" ]] && args+=(-f "sha=$sha")
  gh api "${args[@]}" >/dev/null
}

find_issue_number() {
  gh issue list --repo "$FULL_REPO" --state all --limit 100 \
    --json number,title --jq ".[] | select(.title == \"$ISSUE_TITLE\") | .number" \
    | head -1
}

ensure_issue() {
  local issue_number
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "0"
    return
  fi

  issue_number="$(find_issue_number)"
  if [[ -n "$issue_number" ]]; then
    echo "$issue_number"
    return
  fi

  gh api -X POST "repos/$FULL_REPO/issues" \
    -f "title=$ISSUE_TITLE" -f "body=$(render_issue)" --jq '.number'
}

find_pr_number() {
  gh pr list --repo "$FULL_REPO" --state all --head "$VULNERABLE_BRANCH" \
    --json number --jq '.[0].number // empty'
}

ensure_pr() {
  local issue_number="$1" pr_number
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "0"
    return
  fi

  pr_number="$(find_pr_number)"
  if [[ -n "$pr_number" ]]; then
    echo "$pr_number"
    return
  fi

  gh api -X POST "repos/$FULL_REPO/pulls" \
    -f "base=main" -f "head=$VULNERABLE_BRANCH" -f "title=$PR_TITLE" \
    -f "body=Prepared vulnerable pull request for ghas-admin-04. Fixture details: #$issue_number" \
    --jq '.number'
}

delete_file() {
  local branch="$1" path="$2" message="$3" sha
  sha="$(gh api "repos/$FULL_REPO/contents/$path?ref=$branch" --jq '.sha' 2>/dev/null || true)"
  [[ -n "$sha" ]] || return 0
  run gh api -X DELETE "repos/$FULL_REPO/contents/$path" \
    -f "message=$message" -f "sha=$sha" -f "branch=$branch" >/dev/null
}

delete_branch() {
  local branch="$1"
  branch_exists "$branch" || return 0
  run gh api -X DELETE "repos/$FULL_REPO/git/refs/heads/$branch" >/dev/null
}

status() {
  repo_exists || { echo "Repository missing: $FULL_REPO"; return 1; }
  local failed=0

  echo "Repository: $FULL_REPO"
  for branch in main "$WORKFLOW_BRANCH" "$VULNERABLE_BRANCH"; do
    if branch_exists "$branch"; then
      echo "branch $branch: present"
    else
      echo "branch $branch: MISSING"
      failed=1
    fi
  done

  for item in \
    "main:$COVERAGE_PATH" \
    "$WORKFLOW_BRANCH:.github/workflows/codeql.yml" \
    "$VULNERABLE_BRANCH:$VULNERABLE_PATH"; do
    local branch="${item%%:*}" path="${item#*:}"
    if gh api "repos/$FULL_REPO/contents/$path?ref=$branch" >/dev/null 2>&1; then
      echo "$branch:$path: present"
    else
      echo "$branch:$path: MISSING"
      failed=1
    fi
  done

  local issue_number pr_number
  issue_number="$(find_issue_number || true)"
  pr_number="$(find_pr_number || true)"
  echo "issue: ${issue_number:-MISSING}"
  echo "pull request: ${pr_number:-MISSING}"
  [[ -n "$issue_number" ]] || failed=1
  [[ -n "$pr_number" ]] || failed=1
  return "$failed"
}

provision() {
  create_repo_if_missing
  [[ "$DRY_RUN" == "true" ]] || repo_exists
  enable_security_features

  put_file main "$COVERAGE_PATH" \
    "Add CodeQL coverage probe for GHAS admin lab" "$(render_coverage_probe)"

  ensure_branch "$WORKFLOW_BRANCH"
  put_file "$WORKFLOW_BRANCH" ".github/workflows/codeql.yml" \
    "Prepare CodeQL advanced setup recovery workflow" "$(render_workflow)"

  ensure_branch "$VULNERABLE_BRANCH"
  put_file "$VULNERABLE_BRANCH" "$VULNERABLE_PATH" \
    "Add insecure lookup for CodeQL merge test" "$(render_vulnerability)"

  local issue_number pr_number
  issue_number="$(ensure_issue)"
  pr_number="$(ensure_pr "$issue_number")"

  echo "Fixture ready: $FULL_REPO"
  echo "Issue: $issue_number"
  echo "Prepared pull request: $pr_number"
  echo "Start with CodeQL default setup on main."
}

teardown() {
  repo_exists || { echo "Repository missing: $FULL_REPO"; return 0; }
  [[ "$ASSUME_YES" == "true" ]] || {
    echo "Teardown requires --yes because it removes fixture branches and files." >&2
    return 2
  }

  local pr_number issue_number
  pr_number="$(find_pr_number)"
  issue_number="$(find_issue_number)"

  if [[ -n "$pr_number" && "$DRY_RUN" != "true" ]]; then
    gh pr close "$pr_number" --repo "$FULL_REPO" >/dev/null
  elif [[ -n "$pr_number" ]]; then
    echo "DRY RUN: close pull request $pr_number"
  fi

  delete_branch "$VULNERABLE_BRANCH"
  delete_branch "$WORKFLOW_BRANCH"
  delete_file main "$COVERAGE_PATH" "Remove GHAS CodeQL coverage probe"

  if [[ -n "$issue_number" && "$DRY_RUN" != "true" ]]; then
    gh issue close "$issue_number" --repo "$FULL_REPO" >/dev/null
  elif [[ -n "$issue_number" ]]; then
    echo "DRY RUN: close issue $issue_number"
  fi

  echo "Fixture artifacts removed. Repository preserved: $FULL_REPO"
}

case "$ACTION" in
  provision) provision ;;
  status) status ;;
  teardown) teardown ;;
esac
