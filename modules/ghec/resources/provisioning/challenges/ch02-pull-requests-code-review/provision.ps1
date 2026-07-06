# challenges/ch02-pull-requests-code-review/provision.ps1
#
# Dot-sourced by scripts/setup.ps1 (globals: Ghec*; lib: Write-Ghec*,
# Invoke-GhecMutation, *-GhecRepo/File/Branch/Pr, Confirm-GhecPrefix).
#
# CONTRACT — defines exactly: Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ch02: seeded multi-file app on main, PR template placeholder, src/+docs/
# layout for CODEOWNERS, and TWO open PRs (one clean, one engineered to conflict).

$Global:GhecBrClean    = "ghec-$($Global:GhecChid)-clean-feature"
$Global:GhecBrConflict = "ghec-$($Global:GhecChid)-conflict-feature"

function _Ch02-Full { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch02-SeedMain {
  Write-GhecStep 'seeding app on main'
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid

  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# ghec-$ch — Pull Requests & Code Review

A deliberately small multi-file app. Use it to practise branches, pull
requests, reviews, CODEOWNERS, and resolving a merge conflict.

Layout (maps cleanly to CODEOWNERS paths):
- ``src/``  — application code
- ``docs/`` — documentation

Two PRs are already open: one is clean, one will conflict on ``main``.
"@

  Set-GhecFile -Org $o -Repo $r -Path 'src/app.js' -Message "seed src/app.js (ghec-$ch)" -Content @"
const { greeting } = require('./util');

function main() {
  console.log(greeting('world'));
}

main();
"@

  Set-GhecFile -Org $o -Repo $r -Path 'src/util.js' -Message "seed src/util.js (ghec-$ch)" -Content @"
function greeting(name) {
  return 'Hello, ' + name + '!';
}

module.exports = { greeting };
"@

  Set-GhecFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (ghec-$ch)" -Content @"
{
  "name": "ghec-$ch-app",
  "version": "1.0.0",
  "private": true,
  "scripts": { "start": "node src/app.js" }
}
"@

  Set-GhecFile -Org $o -Repo $r -Path 'docs/config.md' -Message "seed docs/config.md (ghec-$ch)" -Content @"
# Configuration

release-channel: ORIGINAL
"@

  Set-GhecFile -Org $o -Repo $r -Path '.github/pull_request_template.md' -Message "seed PR template placeholder (ghec-$ch)" -Content @"
<!-- ghec-$ch placeholder PR template — flesh this out as part of the challenge. -->

## What & why

## How to test

## Checklist
- [ ] Tests pass
- [ ] Reviewed by a code owner
"@
}

function _Ch02-CleanPr {
  Write-GhecStep "opening CLEAN pr from $($Global:GhecBrClean)"
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid; $b = $Global:GhecBrClean
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Set-GhecFile -Org $o -Repo $r -Path 'src/feature.js' -Message "add feature module (ghec-$ch)" -Branch $b -Content @"
// New, self-contained feature — merges cleanly.
function shout(name) {
  return 'HELLO, ' + String(name).toUpperCase() + '!';
}

module.exports = { shout };
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main -Title 'Add shout() helper (clean)' `
    -Body "Seeded by ghec-$ch. A clean PR: adds src/feature.js with no overlap on main. Practise review + merge."
}

function _Ch02-ConflictPr {
  Write-GhecStep "opening CONFLICT pr from $($Global:GhecBrConflict)"
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid; $b = $Global:GhecBrConflict
  New-GhecBranch -Org $o -Repo $r -Branch $b -Base main
  Edit-GhecFile -Org $o -Repo $r -Path 'docs/config.md' -Branch $b -Message "branch: switch channel to beta (ghec-$ch)" -Content @"
# Configuration

release-channel: BETA
"@
  New-GhecPr -Org $o -Repo $r -Head $b -Base main -Title 'Switch release channel to beta (will conflict)' `
    -Body "Seeded by ghec-$ch. This PR edits the same line in docs/config.md that main also changed — resolve the merge conflict."

  if (Test-GhecFileContains -Org $o -Repo $r -Path 'docs/config.md' -Needle 'release-channel: STABLE' -Ref main) {
    Write-GhecOk 'main already diverged (skip conflict edit)'
  } else {
    Write-GhecStep 'diverging main to force the conflict'
    Edit-GhecFile -Org $o -Repo $r -Path 'docs/config.md' -Branch main -Message "main: switch channel to stable (ghec-$ch)" -Content @"
# Configuration

release-channel: STABLE
"@
  }
}

# ===========================================================================
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility public
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch02-Full) missing after create — aborting seed"
  }
  _Ch02-SeedMain
  _Ch02-CleanPr
  _Ch02-ConflictPr
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - add a CODEOWNERS file mapping src/ and docs/ to reviewers'
  Write-GhecInfo "  - review and merge the clean PR ($($Global:GhecBrClean))"
  Write-GhecInfo "  - resolve the merge conflict on the conflict PR ($($Global:GhecBrConflict))"
  Write-GhecInfo '  - turn on branch protection / required reviews on main'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $prs = gh pr list --repo (_Ch02-Full) --state open --json number --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch02-Full) present — $prs open PR(s)"
  } else {
    Write-GhecInfo "repo $(_Ch02-Full) not provisioned"
  }
}
