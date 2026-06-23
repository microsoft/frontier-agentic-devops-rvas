# challenges/ch02-pull-requests-code-review/provision.ps1
#
# Dot-sourced by scripts/setup.ps1 (globals: Wth*; lib: Write-Wth*,
# Invoke-WthMutation, *-WthRepo/File/Branch/Pr, Confirm-WthPrefix).
#
# CONTRACT — defines exactly: Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ch02: seeded multi-file app on main, PR template placeholder, src/+docs/
# layout for CODEOWNERS, and TWO open PRs (one clean, one engineered to conflict).

$Global:WthBrClean    = "wth-$($Global:WthChid)-clean-feature"
$Global:WthBrConflict = "wth-$($Global:WthChid)-conflict-feature"

function _Ch02-Full { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch02-SeedMain {
  Write-WthStep 'seeding app on main'
  $o = $Global:WthOrg; $r = $Global:WthRepo; $ch = $Global:WthChid

  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# wth-$ch — Pull Requests & Code Review

A deliberately small multi-file app. Use it to practise branches, pull
requests, reviews, CODEOWNERS, and resolving a merge conflict.

Layout (maps cleanly to CODEOWNERS paths):
- ``src/``  — application code
- ``docs/`` — documentation

Two PRs are already open: one is clean, one will conflict on ``main``.
"@

  Set-WthFile -Org $o -Repo $r -Path 'src/app.js' -Message "seed src/app.js (wth-$ch)" -Content @"
const { greeting } = require('./util');

function main() {
  console.log(greeting('world'));
}

main();
"@

  Set-WthFile -Org $o -Repo $r -Path 'src/util.js' -Message "seed src/util.js (wth-$ch)" -Content @"
function greeting(name) {
  return 'Hello, ' + name + '!';
}

module.exports = { greeting };
"@

  Set-WthFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (wth-$ch)" -Content @"
{
  "name": "wth-$ch-app",
  "version": "1.0.0",
  "private": true,
  "scripts": { "start": "node src/app.js" }
}
"@

  Set-WthFile -Org $o -Repo $r -Path 'docs/config.md' -Message "seed docs/config.md (wth-$ch)" -Content @"
# Configuration

release-channel: ORIGINAL
"@

  Set-WthFile -Org $o -Repo $r -Path '.github/pull_request_template.md' -Message "seed PR template placeholder (wth-$ch)" -Content @"
<!-- wth-$ch placeholder PR template — flesh this out as part of the challenge. -->

## What & why

## How to test

## Checklist
- [ ] Tests pass
- [ ] Reviewed by a code owner
"@
}

function _Ch02-CleanPr {
  Write-WthStep "opening CLEAN pr from $($Global:WthBrClean)"
  $o = $Global:WthOrg; $r = $Global:WthRepo; $ch = $Global:WthChid; $b = $Global:WthBrClean
  New-WthBranch -Org $o -Repo $r -Branch $b -Base main
  Set-WthFile -Org $o -Repo $r -Path 'src/feature.js' -Message "add feature module (wth-$ch)" -Branch $b -Content @"
// New, self-contained feature — merges cleanly.
function shout(name) {
  return 'HELLO, ' + String(name).toUpperCase() + '!';
}

module.exports = { shout };
"@
  New-WthPr -Org $o -Repo $r -Head $b -Base main -Title 'Add shout() helper (clean)' `
    -Body "Seeded by wth-$ch. A clean PR: adds src/feature.js with no overlap on main. Practise review + merge."
}

function _Ch02-ConflictPr {
  Write-WthStep "opening CONFLICT pr from $($Global:WthBrConflict)"
  $o = $Global:WthOrg; $r = $Global:WthRepo; $ch = $Global:WthChid; $b = $Global:WthBrConflict
  New-WthBranch -Org $o -Repo $r -Branch $b -Base main
  Edit-WthFile -Org $o -Repo $r -Path 'docs/config.md' -Branch $b -Message "branch: switch channel to beta (wth-$ch)" -Content @"
# Configuration

release-channel: BETA
"@
  New-WthPr -Org $o -Repo $r -Head $b -Base main -Title 'Switch release channel to beta (will conflict)' `
    -Body "Seeded by wth-$ch. This PR edits the same line in docs/config.md that main also changed — resolve the merge conflict."

  if (Test-WthFileContains -Org $o -Repo $r -Path 'docs/config.md' -Needle 'release-channel: STABLE' -Ref main) {
    Write-WthOk 'main already diverged (skip conflict edit)'
  } else {
    Write-WthStep 'diverging main to force the conflict'
    Edit-WthFile -Org $o -Repo $r -Path 'docs/config.md' -Branch main -Message "main: switch channel to stable (wth-$ch)" -Content @"
# Configuration

release-channel: STABLE
"@
  }
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility public
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch02-Full) missing after create — aborting seed"
  }
  _Ch02-SeedMain
  _Ch02-CleanPr
  _Ch02-ConflictPr
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - add a CODEOWNERS file mapping src/ and docs/ to reviewers'
  Write-WthInfo "  - review and merge the clean PR ($($Global:WthBrClean))"
  Write-WthInfo "  - resolve the merge conflict on the conflict PR ($($Global:WthBrConflict))"
  Write-WthInfo '  - turn on branch protection / required reviews on main'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $prs = gh pr list --repo (_Ch02-Full) --state open --json number --jq 'length' 2>$null
    Write-WthOk "repo $(_Ch02-Full) present — $prs open PR(s)"
  } else {
    Write-WthInfo "repo $(_Ch02-Full) not provisioned"
  }
}
