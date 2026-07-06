# challenges/ch05-advanced-pr-automation/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ch05: seeded app + working 'build'-check CI, starter CODEOWNERS, placeholder
# PR template, and FOUR open PRs (clean / failing-ci / draft / needs-owner).

$Global:GhecBrClean = "ghec-$($Global:GhecChid)-clean"
$Global:GhecBrFail  = "ghec-$($Global:GhecChid)-failing-ci"
$Global:GhecBrDraft = "ghec-$($Global:GhecChid)-draft"
$Global:GhecBrOwner = "ghec-$($Global:GhecChid)-needs-owner"

function _Ch05-Full { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch05-SeedMain {
  Write-GhecStep 'seeding app + working CI on main'
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid

  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# ghec-$ch — Advanced PR Automation

A seeded app with a working CI workflow that publishes a ``build`` check on
every pull request. Four PRs are already open in different states. Your job is
to add automation: required status checks, required reviews from code owners,
auto-labelling, and a ruleset — without merging the broken ones by accident.
"@

  Set-GhecFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (ghec-$ch)" -Content @"
{
  "name": "ghec-$ch-app",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node test/app.test.js" }
}
"@

  Set-GhecFile -Org $o -Repo $r -Path 'src/math.js' -Message "seed src/math.js (ghec-$ch)" -Content @"
function add(a, b) { return a + b; }
module.exports = { add };
"@

  Set-GhecFile -Org $o -Repo $r -Path 'test/app.test.js' -Message "seed test (ghec-$ch)" -Content @"
const assert = require('assert');
const { add } = require('../src/math');
assert.strictEqual(add(2, 3), 5, 'add(2,3) should be 5');
console.log('ok - build check passed');
"@

  Set-GhecFile -Org $o -Repo $r -Path '.github/workflows/ci.yml' -Message "seed working build-check CI (ghec-$ch)" -Content @"
name: build
on:
  pull_request:
  push:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm test
"@

  Set-GhecFile -Org $o -Repo $r -Path '.github/CODEOWNERS' -Message "seed starter CODEOWNERS (ghec-$ch)" -Content @"
# ghec-$ch starter CODEOWNERS — replace the placeholder owner with a real
# team/user (e.g. @$o/maintainers) and wire required reviews via a ruleset.
/src/   @$o/PLACEHOLDER-OWNERS
"@

  Set-GhecFile -Org $o -Repo $r -Path '.github/pull_request_template.md' -Message "seed PR template placeholder (ghec-$ch)" -Content @"
<!-- ghec-$ch placeholder PR template -->

## Summary

## Risk / rollout

## Checklist
- [ ] build check green
- [ ] code owner review
"@
}

function _Ch05-PrClean {
  Write-GhecStep "PR (clean) from $($Global:GhecBrClean)"
  $o=$Global:GhecOrg; $r=$Global:GhecRepo; $ch=$Global:GhecChid; $b=$Global:GhecBrClean
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Set-GhecFile -Org $o -Repo $r -Path 'docs/notes.md' -Branch $b -Message "add notes (ghec-$ch)" -Content @"
# Notes

Clean change — no code touched, build stays green.
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main -Title 'Add docs notes (clean)' `
    -Body "Seeded by ghec-$ch. Clean PR — build check should pass."
}

function _Ch05-PrFailing {
  Write-GhecStep "PR (failing-ci) from $($Global:GhecBrFail)"
  $o=$Global:GhecOrg; $r=$Global:GhecRepo; $ch=$Global:GhecChid; $b=$Global:GhecBrFail
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Edit-GhecFile -Org $o -Repo $r -Path 'src/math.js' -Branch $b -Message "break add() to fail CI (ghec-$ch)" -Content @"
function add(a, b) { return a - b; } // BUG: should be a + b
module.exports = { add };
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main -Title 'Refactor add() (FAILS build)' `
    -Body "Seeded by ghec-$ch. This PR breaks the test — the build check should go red. Do not merge."
}

function _Ch05-PrDraft {
  Write-GhecStep "PR (draft) from $($Global:GhecBrDraft)"
  $o=$Global:GhecOrg; $r=$Global:GhecRepo; $ch=$Global:GhecChid; $b=$Global:GhecBrDraft
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Set-GhecFile -Org $o -Repo $r -Path 'docs/wip.md' -Branch $b -Message "wip notes (ghec-$ch)" -Content @"
# WIP

Work in progress — opened as a draft on purpose.
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main -Title 'WIP feature (draft)' -Draft `
    -Body "Seeded by ghec-$ch. Opened as a draft — should be excluded from auto-merge."
}

function _Ch05-PrOwner {
  Write-GhecStep "PR (needs-owner) from $($Global:GhecBrOwner)"
  $o=$Global:GhecOrg; $r=$Global:GhecRepo; $ch=$Global:GhecChid; $b=$Global:GhecBrOwner
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Edit-GhecFile -Org $o -Repo $r -Path 'src/math.js' -Branch $b -Message "add mul() under CODEOWNERS path (ghec-$ch)" -Content @"
function add(a, b) { return a + b; }
function mul(a, b) { return a * b; }
module.exports = { add, mul };
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main -Title 'Add mul() (needs code owner)' `
    -Body "Seeded by ghec-$ch. Touches /src (a CODEOWNERS path) — should require owner review once you wire it."
}

# ===========================================================================
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility public
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch05-Full) missing after create — aborting seed"
  }
  _Ch05-SeedMain
  _Ch05-PrClean
  _Ch05-PrFailing
  _Ch05-PrDraft
  _Ch05-PrOwner
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - require the 'build' status check on main"
  Write-GhecInfo '  - require code owner review (fix CODEOWNERS placeholder first)'
  Write-GhecInfo '  - add auto-labelling / auto-merge that respects draft + failing states'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $prs = gh pr list --repo (_Ch05-Full) --state open --json number --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch05-Full) present — $prs open PR(s)"
  } else {
    Write-GhecInfo "repo $(_Ch05-Full) not provisioned"
  }
}
