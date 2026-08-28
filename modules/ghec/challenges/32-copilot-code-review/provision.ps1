# ch32 provisioning contract: dot-sourced by the GHEC setup dispatcher and
# defines only Invoke-GhecProvision, Invoke-GhecTeardown, and Invoke-GhecStatus.

$Global:GhecReviewBranch = "ghec-$($Global:GhecChid)-review-candidate"

function _Ch32-Full { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch32-SeedMain {
  Write-GhecStep 'seeding isolated Copilot code review fallback'
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid

  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# ghec-$ch — Copilot Code Review fallback

This isolated repository is a safe review target. It does not enable Copilot,
configure a ruleset, or change human merge controls.

Use the open pull request to request a manual Copilot review, then record the
human triage and the automatic-review decision in docs/decision-package.md.
"@

  Set-GhecFile -Org $o -Repo $r -Path 'src/normalize.js' -Message "seed review target (ghec-$ch)" -Content @"
export function normalizeIdentifier(value) {
  return String(value).trim().toLowerCase().replaceAll(' ', '-');
}
"@

  Set-GhecFile -Org $o -Repo $r -Path 'test/normalize.test.js' -Message "seed test (ghec-$ch)" -Content @"
import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeIdentifier } from '../src/normalize.js';

test('normalizes a display identifier', () => {
  assert.equal(normalizeIdentifier('  Agentic DevSecOps  '), 'agentic-devsecops');
});
"@

  Set-GhecFile -Org $o -Repo $r -Path 'package.json' -Message "seed package metadata (ghec-$ch)" -Content @"
{
  "name": "ghec-$ch-copilot-code-review",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
"@

  Set-GhecFile -Org $o -Repo $r -Path '.github/copilot-instructions.md' -Message "seed review instructions (ghec-$ch)" -Content @"
When reviewing this repository, identify correctness, test, and input-handling
risks. Treat human review and CODEOWNERS as the approval authority. Do not
recommend adding secrets or weakening branch protections.
"@

  Set-GhecFile -Org $o -Repo $r -Path 'docs/decision-package.md' -Message "seed decision package (ghec-$ch)" -Content @"
# Copilot code review decision package

- Effective policy and availability evidence:
- Customer repository scope and owner:
- Manual review PR and human comment triage:
- Ruleset scope; new-push and draft-review decisions:
- Shared setup versus optional copilot-code-review.yml decision:
- Human review and CODEOWNERS controls retained:
- Preview options excluded or separately approved:
- Rollback executor, restore steps, and verification:
- Next decision, owner, and review date:
"@
}

function _Ch32-SeedReviewCandidate {
  Write-GhecStep 'opening a small review-candidate pull request'
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid; $b = $Global:GhecReviewBranch
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Set-GhecFile -Org $o -Repo $r -Path 'src/display-name.js' -Branch $b -Message "add display-name helper (ghec-$ch)" -Content @"
export function formatDisplayName(value) {
  return String(value).trim().replaceAll(/\s+/g, ' ');
}
"@
  Set-GhecFile -Org $o -Repo $r -Path 'test/display-name.test.js' -Branch $b -Message "test display-name helper (ghec-$ch)" -Content @"
import test from 'node:test';
import assert from 'node:assert/strict';
import { formatDisplayName } from '../src/display-name.js';

test('collapses whitespace in a display name', () => {
  assert.equal(formatDisplayName('  Agentic   DevSecOps  '), 'Agentic DevSecOps');
});
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main `
    -Title 'Add display-name formatter for review' `
    -Body 'Safe fallback PR for manual Copilot code review. Human reviewers must triage comments; do not treat Copilot as an approval.'
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch32-Full) missing after creation — aborting seed"
  }
  _Ch32-SeedMain
  _Ch32-SeedReviewCandidate
  Write-GhecInfo "Next steps: request a manual Copilot review on $($Global:GhecReviewBranch), retain human review, and record the automatic-review decision."
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $prs = gh pr list --repo (_Ch32-Full) --state open --json number --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch32-Full) present — $prs open PR(s)"
  } else {
    Write-GhecInfo "repo $(_Ch32-Full) not provisioned"
  }
}
