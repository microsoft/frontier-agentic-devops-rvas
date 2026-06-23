# challenges/ch05-advanced-pr-automation/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ch05: seeded app + working 'build'-check CI, starter CODEOWNERS, placeholder
# PR template, and FOUR open PRs (clean / failing-ci / draft / needs-owner).

$Global:WthBrClean = "wth-$($Global:WthChid)-clean"
$Global:WthBrFail  = "wth-$($Global:WthChid)-failing-ci"
$Global:WthBrDraft = "wth-$($Global:WthChid)-draft"
$Global:WthBrOwner = "wth-$($Global:WthChid)-needs-owner"

function _Ch05-Full { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch05-SeedMain {
  Write-WthStep 'seeding app + working CI on main'
  $o = $Global:WthOrg; $r = $Global:WthRepo; $ch = $Global:WthChid

  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# wth-$ch — Advanced PR Automation

A seeded app with a working CI workflow that publishes a ``build`` check on
every pull request. Four PRs are already open in different states. Your job is
to add automation: required status checks, required reviews from code owners,
auto-labelling, and a ruleset — without merging the broken ones by accident.
"@

  Set-WthFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (wth-$ch)" -Content @"
{
  "name": "wth-$ch-app",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node test/app.test.js" }
}
"@

  Set-WthFile -Org $o -Repo $r -Path 'src/math.js' -Message "seed src/math.js (wth-$ch)" -Content @"
function add(a, b) { return a + b; }
module.exports = { add };
"@

  Set-WthFile -Org $o -Repo $r -Path 'test/app.test.js' -Message "seed test (wth-$ch)" -Content @"
const assert = require('assert');
const { add } = require('../src/math');
assert.strictEqual(add(2, 3), 5, 'add(2,3) should be 5');
console.log('ok - build check passed');
"@

  Set-WthFile -Org $o -Repo $r -Path '.github/workflows/ci.yml' -Message "seed working build-check CI (wth-$ch)" -Content @"
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

  Set-WthFile -Org $o -Repo $r -Path '.github/CODEOWNERS' -Message "seed starter CODEOWNERS (wth-$ch)" -Content @"
# wth-$ch starter CODEOWNERS — replace the placeholder owner with a real
# team/user (e.g. @$o/maintainers) and wire required reviews via a ruleset.
/src/   @$o/PLACEHOLDER-OWNERS
"@

  Set-WthFile -Org $o -Repo $r -Path '.github/pull_request_template.md' -Message "seed PR template placeholder (wth-$ch)" -Content @"
<!-- wth-$ch placeholder PR template -->

## Summary

## Risk / rollout

## Checklist
- [ ] build check green
- [ ] code owner review
"@
}

function _Ch05-PrClean {
  Write-WthStep "PR (clean) from $($Global:WthBrClean)"
  $o=$Global:WthOrg; $r=$Global:WthRepo; $ch=$Global:WthChid; $b=$Global:WthBrClean
  New-WthBranch -Org $o -Repo $r -Branch $b -Base main
  Set-WthFile -Org $o -Repo $r -Path 'docs/notes.md' -Branch $b -Message "add notes (wth-$ch)" -Content @"
# Notes

Clean change — no code touched, build stays green.
"@
  New-WthPr -Org $o -Repo $r -Head $b -Base main -Title 'Add docs notes (clean)' `
    -Body "Seeded by wth-$ch. Clean PR — build check should pass."
}

function _Ch05-PrFailing {
  Write-WthStep "PR (failing-ci) from $($Global:WthBrFail)"
  $o=$Global:WthOrg; $r=$Global:WthRepo; $ch=$Global:WthChid; $b=$Global:WthBrFail
  New-WthBranch -Org $o -Repo $r -Branch $b -Base main
  Edit-WthFile -Org $o -Repo $r -Path 'src/math.js' -Branch $b -Message "break add() to fail CI (wth-$ch)" -Content @"
function add(a, b) { return a - b; } // BUG: should be a + b
module.exports = { add };
"@
  New-WthPr -Org $o -Repo $r -Head $b -Base main -Title 'Refactor add() (FAILS build)' `
    -Body "Seeded by wth-$ch. This PR breaks the test — the build check should go red. Do not merge."
}

function _Ch05-PrDraft {
  Write-WthStep "PR (draft) from $($Global:WthBrDraft)"
  $o=$Global:WthOrg; $r=$Global:WthRepo; $ch=$Global:WthChid; $b=$Global:WthBrDraft
  New-WthBranch -Org $o -Repo $r -Branch $b -Base main
  Set-WthFile -Org $o -Repo $r -Path 'docs/wip.md' -Branch $b -Message "wip notes (wth-$ch)" -Content @"
# WIP

Work in progress — opened as a draft on purpose.
"@
  New-WthPr -Org $o -Repo $r -Head $b -Base main -Title 'WIP feature (draft)' -Draft `
    -Body "Seeded by wth-$ch. Opened as a draft — should be excluded from auto-merge."
}

function _Ch05-PrOwner {
  Write-WthStep "PR (needs-owner) from $($Global:WthBrOwner)"
  $o=$Global:WthOrg; $r=$Global:WthRepo; $ch=$Global:WthChid; $b=$Global:WthBrOwner
  New-WthBranch -Org $o -Repo $r -Branch $b -Base main
  Edit-WthFile -Org $o -Repo $r -Path 'src/math.js' -Branch $b -Message "add mul() under CODEOWNERS path (wth-$ch)" -Content @"
function add(a, b) { return a + b; }
function mul(a, b) { return a * b; }
module.exports = { add, mul };
"@
  New-WthPr -Org $o -Repo $r -Head $b -Base main -Title 'Add mul() (needs code owner)' `
    -Body "Seeded by wth-$ch. Touches /src (a CODEOWNERS path) — should require owner review once you wire it."
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility public
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch05-Full) missing after create — aborting seed"
  }
  _Ch05-SeedMain
  _Ch05-PrClean
  _Ch05-PrFailing
  _Ch05-PrDraft
  _Ch05-PrOwner
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo "  - require the 'build' status check on main"
  Write-WthInfo '  - require code owner review (fix CODEOWNERS placeholder first)'
  Write-WthInfo '  - add auto-labelling / auto-merge that respects draft + failing states'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $prs = gh pr list --repo (_Ch05-Full) --state open --json number --jq 'length' 2>$null
    Write-WthOk "repo $(_Ch05-Full) present — $prs open PR(s)"
  } else {
    Write-WthInfo "repo $(_Ch05-Full) not provisioned"
  }
}
