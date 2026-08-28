# shellcheck shell=bash
#
# ch32 provisioning contract: sourced by the GHEC setup dispatcher and defines
# only ghec_provision, ghec_teardown, and ghec_status.

REVIEW_BRANCH="ghec-${CHID}-review-candidate"

_ch32_full() { printf '%s/%s' "$ORG" "$REPO"; }

_ch32_seed_main() {
  log_step "seeding isolated Copilot code review fallback"
  gh_put_file "$ORG" "$REPO" "README.md" "seed README (ghec-${CHID})" \
"# ghec-${CHID} — Copilot Code Review fallback

This isolated repository is a safe review target. It does not enable Copilot,
configure a ruleset, or change human merge controls.

Use the open pull request to request a manual Copilot review, then record the
human triage and the automatic-review decision in docs/decision-package.md."

  gh_put_file "$ORG" "$REPO" "src/normalize.js" "seed review target (ghec-${CHID})" \
"export function normalizeIdentifier(value) {
  return String(value).trim().toLowerCase().replaceAll(' ', '-');
}
"

  gh_put_file "$ORG" "$REPO" "test/normalize.test.js" "seed test (ghec-${CHID})" \
"import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeIdentifier } from '../src/normalize.js';

test('normalizes a display identifier', () => {
  assert.equal(normalizeIdentifier('  Agentic DevSecOps  '), 'agentic-devsecops');
});
"

  gh_put_file "$ORG" "$REPO" "package.json" "seed package metadata (ghec-${CHID})" \
"{
  \"name\": \"ghec-${CHID}-copilot-code-review\",
  \"private\": true,
  \"type\": \"module\",
  \"scripts\": { \"test\": \"node --test\" }
}
"

  gh_put_file "$ORG" "$REPO" ".github/copilot-instructions.md" "seed review instructions (ghec-${CHID})" \
"When reviewing this repository, identify correctness, test, and input-handling
risks. Treat human review and CODEOWNERS as the approval authority. Do not
recommend adding secrets or weakening branch protections."

  gh_put_file "$ORG" "$REPO" "docs/decision-package.md" "seed decision package (ghec-${CHID})" \
"# Copilot code review decision package

- Effective policy and availability evidence:
- Customer repository scope and owner:
- Manual review PR and human comment triage:
- Ruleset scope; new-push and draft-review decisions:
- Shared setup versus optional copilot-code-review.yml decision:
- Human review and CODEOWNERS controls retained:
- Preview options excluded or separately approved:
- Rollback executor, restore steps, and verification:
- Next decision, owner, and review date:
"
}

_ch32_seed_review_candidate() {
  log_step "opening a small review-candidate pull request"
  gh_create_branch "$ORG" "$REPO" "$REVIEW_BRANCH" main
  gh_put_file "$ORG" "$REPO" "src/display-name.js" "add display-name helper (ghec-${CHID})" \
"export function formatDisplayName(value) {
  return String(value).trim().replaceAll(/\\s+/g, ' ');
}
" "$REVIEW_BRANCH"
  gh_put_file "$ORG" "$REPO" "test/display-name.test.js" "test display-name helper (ghec-${CHID})" \
"import test from 'node:test';
import assert from 'node:assert/strict';
import { formatDisplayName } from '../src/display-name.js';

test('collapses whitespace in a display name', () => {
  assert.equal(formatDisplayName('  Agentic   DevSecOps  '), 'Agentic DevSecOps');
});
" "$REVIEW_BRANCH"
  gh_open_pr "$ORG" "$REPO" "$REVIEW_BRANCH" main \
    "Add display-name formatter for review" \
    "Safe fallback PR for manual Copilot code review. Human reviewers must triage comments; do not treat Copilot as an approval."
}

ghec_provision() {
  gh_create_repo "$ORG" "$REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$REPO"; then
    die "repo $(_ch32_full) missing after creation — aborting seed"
  fi
  _ch32_seed_main
  _ch32_seed_review_candidate
  log_info "Next steps: request a manual Copilot review on $REVIEW_BRANCH, retain human review, and record the automatic-review decision."
}

ghec_teardown() {
  guard_prefix "$REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$REPO"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$REPO"; then
    local prs
    prs="$(gh pr list --repo "$(_ch32_full)" --state open --json number --jq 'length' 2>/dev/null || echo '?')"
    log_ok "repo $(_ch32_full) present — $prs open PR(s)"
  else
    log_info "repo $(_ch32_full) not provisioned"
  fi
}
