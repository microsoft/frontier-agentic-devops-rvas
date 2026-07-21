#!/usr/bin/env bash
# shellcheck shell=bash
#
# Safe, standalone fallback provisioner for Ch33. It creates only a private
# decision-package repository; it never enables Copilot or an automation.
set -euo pipefail

ORG=""
REPO="ghec-ch33-copilot-automations"
TEARDOWN="false"

usage() {
  cat <<'EOF'
Usage: provision.sh --org <org> [--teardown]

Creates or reconciles the safe Ch33 private fallback repository. It does not
enable Copilot, create an automation, change policy, add a secret, or start a
cloud-agent session.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="${2:-}"; shift 2 ;;
    --teardown) TEARDOWN="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$ORG" ]] || { printf '%s\n' '--org is required' >&2; exit 1; }
command -v gh >/dev/null || { printf '%s\n' 'gh is required' >&2; exit 1; }

repo_full="$ORG/$REPO"
if [[ "$TEARDOWN" == "true" ]]; then
  [[ "$REPO" == ghec-ch33-* ]] || {
    printf '%s\n' 'Refusing to delete a non-ch33 repository' >&2
    exit 1
  }
  if gh repo view "$repo_full" >/dev/null 2>&1; then
    gh repo delete "$repo_full" --yes
    printf 'Deleted %s\n' "$repo_full"
  else
    printf 'Fallback repository already absent: %s\n' "$repo_full"
  fi
  exit 0
fi

if ! gh repo view "$repo_full" >/dev/null 2>&1; then
  if ! gh repo create "$repo_full" --private \
    --description 'Safe fallback for GHEC Ch33 Copilot Automations'; then
    printf '%s\n' "Unable to create private fallback '$repo_full'." >&2
    printf '%s\n' 'Do not use a public substitute; retain the decision package in the customer evidence location.' >&2
    exit 0
  fi
fi

put_file() {
  local path="$1" message="$2" content="$3" sha="" args
  sha="$(gh api "repos/$repo_full/contents/$path" --jq .sha 2>/dev/null || true)"
  args=(api --method PUT "repos/$repo_full/contents/$path"
    -f "message=$message"
    -f "content=$(printf '%s' "$content" | base64 | tr -d '\n')")
  [[ -n "$sha" ]] && args+=(-f "sha=$sha")
  gh "${args[@]}" >/dev/null
}

put_file "README.md" "Add Ch33 fallback overview" "$(cat <<'EOF'
# GHEC Ch33 — Copilot Automations decision-package fallback

This private `ghec-ch33-*` repository is a safe fallback. It does not create,
enable, or test a Copilot automation.

Use it only when an approved customer private/internal repository is not yet
available. Complete `docs/AUTOMATION-DECISION-PACKAGE.md`, then move the
approved operating model and evidence to the customer-owned target.

Do not place secrets in an automation prompt or this repository. Do not opt in
to untrusted event triggers. Copilot automations are configured in the GitHub
UI and their sessions, rather than this file, are the authoritative run record.
EOF
)"

put_file "docs/AUTOMATION-DECISION-PACKAGE.md" \
  "Add Ch33 automation decision package" "$(cat <<'EOF'
# Copilot Automations decision package

## Target and authority
- Customer repository URL and visibility:
- Repository owner:
- Automation creator:
- Independent reviewer:
- Security and Copilot owners:
- Approval and evidence location:

## Eligibility
- Copilot plan and evidence:
- Cloud-agent policy and evidence:
- Automations policy and evidence:
- Creator write access:
- Private/internal repository result:
- EMU eligibility result:

## Proposed bounded automation
- Task and accepted outcome:
- Schedule or event trigger:
- Event search/files filters and controlled match/non-match evidence:
- Prompt boundary and untrusted-content instruction:
- Requested tools and rejected higher-privilege tools:
- Data boundary, run-rate limit, and cost owner:

## Safety, evidence, and next decision
- Default untrusted-user-event guardrail retained:
- Independent-review and workflow-run approval posture:
- Session-log and audit-log evidence locations:
- Stop conditions and disable/rollback owner:
- Blocker, if any:
- Decision (`approved pilot`, `inspect-and-propose`, `unavailable`, or `not applicable`):
- Next decision owner and date:
EOF
)"

printf 'Safe fallback decision-package repository ready: %s\n' "$repo_full"
printf '%s\n' 'Next: record eligibility and approval decisions; do not enable an automation until the customer target is authorized.'
