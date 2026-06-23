# challenges/ch04-actions-ci-fundamentals/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ch04: seeded Node app, passing suite + one flag-gated failing test
# (WTH_FAIL=1), package.json test/build/lint scripts, echo-only starter ci.yml.

function _Ch04-Full { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch04-Seed {
  Write-WthStep 'seeding Node app + tests + starter workflow'
  $o = $Global:WthOrg; $r = $Global:WthRepo; $ch = $Global:WthChid

  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# wth-$ch — GitHub Actions CI Fundamentals

A small Node app with a test suite. The starter workflow only echoes — replace
it with a real CI pipeline (install, lint, test, build, matrix, cache, artifacts).

## Scripts
- ``npm test``  — runs the suite (one test is gated on WTH_FAIL=1 to demo red/green)
- ``npm run build`` — trivial build step
- ``npm run lint``  — trivial lint step

Set the repo/Actions variable ``WTH_FAIL=1`` to make the suite fail on purpose.
"@

  Set-WthFile -Org $o -Repo $r -Path 'package.json' -Message "seed package.json (wth-$ch)" -Content @"
{
  "name": "wth-$ch-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node test/app.test.js",
    "build": "node -e \"console.log('build ok')\"",
    "lint": "node -e \"console.log('lint ok')\""
  }
}
"@

  Set-WthFile -Org $o -Repo $r -Path 'src/math.js' -Message "seed src/math.js (wth-$ch)" -Content @"
function add(a, b) { return a + b; }
function mul(a, b) { return a * b; }
module.exports = { add, mul };
"@

  Set-WthFile -Org $o -Repo $r -Path 'test/app.test.js' -Message "seed test suite (wth-$ch)" -Content @"
const assert = require('assert');
const { add, mul } = require('../src/math');

// Always-passing tests.
assert.strictEqual(add(2, 3), 5, 'add(2,3) should be 5');
assert.strictEqual(mul(2, 3), 6, 'mul(2,3) should be 6');
console.log('ok - core tests passed');

// Flag-gated failing test: flip CI red by setting WTH_FAIL=1.
if (process.env.WTH_FAIL === '1') {
  assert.strictEqual(add(2, 2), 5, 'intentional failure (WTH_FAIL=1)');
} else {
  console.log('ok - skipping the flag-gated failure (set WTH_FAIL=1 to enable)');
}
"@

  Set-WthFile -Org $o -Repo $r -Path '.github/workflows/ci.yml' -Message "seed echo-only starter workflow (wth-$ch)" -Content @"
name: ci
# wth-$ch STARTER — echo only. Replace with a real pipeline:
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

  Set-WthFile -Org $o -Repo $r -Path '.gitignore' -Message "seed .gitignore (wth-$ch)" -Content @"
node_modules/
"@
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility public
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch04-Full) missing after create — aborting seed"
  }
  _Ch04-Seed
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - replace .github/workflows/ci.yml with install/lint/test/build'
  Write-WthInfo '  - add a matrix (Node versions), dependency caching, and an artifact upload'
  Write-WthInfo '  - flip WTH_FAIL=1 to watch the gate go red, then green again'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $runs = gh run list --repo (_Ch04-Full) --limit 100 --json status --jq 'length' 2>$null
    if (-not $runs) { $runs = 0 }
    Write-WthOk "repo $(_Ch04-Full) present — $runs workflow run(s) recorded"
  } else {
    Write-WthInfo "repo $(_Ch04-Full) not provisioned"
  }
}
