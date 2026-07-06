# challenges/ch04-actions-ci-fundamentals/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ch04: seeded Node app, passing suite + one flag-gated failing test
# (GHEC_FAIL=1), package.json test/build/lint scripts, echo-only starter ci.yml.

function _Ch04-Full { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch04-Seed {
  Write-GhecStep 'seeding Node app + tests + starter workflow'
  $o = $Global:GhecOrg; $r = $Global:GhecRepo; $ch = $Global:GhecChid

  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# ghec-$ch — GitHub Actions CI Fundamentals

A small Node app with a test suite. The starter workflow only echoes — replace
it with a real CI pipeline (install, lint, test, build, matrix, cache, artifacts).

## Scripts
- ``npm test``  — runs the suite (one test is gated on GHEC_FAIL=1 to demo red/green)
- ``npm run build`` — trivial build step
- ``npm run lint``  — trivial lint step

Set the repo/Actions variable ``GHEC_FAIL=1`` to make the suite fail on purpose.
"@

  Set-GhecFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (ghec-$ch)" -Content @"
{
  "name": "ghec-$ch-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node test/app.test.js",
    "build": "node -e \"console.log('build ok')\"",
    "lint": "node -e \"console.log('lint ok')\""
  }
}
"@

  Set-GhecFile -Org $o -Repo $r -Path 'src/math.js' -Message "seed src/math.js (ghec-$ch)" -Content @"
function add(a, b) { return a + b; }
function mul(a, b) { return a * b; }
module.exports = { add, mul };
"@

  Set-GhecFile -Org $o -Repo $r -Path 'test/app.test.js' -Message "seed test suite (ghec-$ch)" -Content @"
const assert = require('assert');
const { add, mul } = require('../src/math');

// Always-passing tests.
assert.strictEqual(add(2, 3), 5, 'add(2,3) should be 5');
assert.strictEqual(mul(2, 3), 6, 'mul(2,3) should be 6');
console.log('ok - core tests passed');

// Flag-gated failing test: flip CI red by setting GHEC_FAIL=1.
if (process.env.GHEC_FAIL === '1') {
  assert.strictEqual(add(2, 2), 5, 'intentional failure (GHEC_FAIL=1)');
} else {
  console.log('ok - skipping the flag-gated failure (set GHEC_FAIL=1 to enable)');
}
"@

  Set-GhecFile -Org $o -Repo $r -Path '.github/workflows/ci.yml' -Message "seed echo-only starter workflow (ghec-$ch)" -Content @"
name: ci
# ghec-$ch STARTER — echo only. Replace with a real pipeline:
# checkout -> setup-node -> npm ci -> lint -> test -> build (+ matrix, cache, artifacts).
on:
  push:
    branches: [ main ]
  pull_request:
  workflow_dispatch:
jobs:
  placeholder:
    runs-on: ubuntu-latest
    steps:
      - run: echo 'Replace me with real CI. See README.'
"@

  Set-GhecFile -Org $o -Repo $r -Path '.gitignore' -Message "seed .gitignore (ghec-$ch)" -Content @"
node_modules/
"@
}

# ===========================================================================
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility public
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch04-Full) missing after create — aborting seed"
  }
  _Ch04-Seed
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - replace .github/workflows/ci.yml with install/lint/test/build'
  Write-GhecInfo '  - add a matrix (Node versions), dependency caching, and an artifact upload'
  Write-GhecInfo '  - flip GHEC_FAIL=1 to watch the gate go red, then green again'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $runs = gh run list --repo (_Ch04-Full) --limit 100 --json status --jq 'length' 2>$null
    if (-not $runs) { $runs = 0 }
    Write-GhecOk "repo $(_Ch04-Full) present — $runs workflow run(s) recorded"
  } else {
    Write-GhecInfo "repo $(_Ch04-Full) not provisioned"
  }
}
