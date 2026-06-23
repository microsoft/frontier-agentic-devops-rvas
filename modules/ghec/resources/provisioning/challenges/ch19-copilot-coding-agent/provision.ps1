# challenges/ch19-copilot-coding-agent/provision.ps1
#
# PowerShell twin of ch19 — small buggy repo sized for the Copilot cloud agent.

$Global:WthIssueTitle = 'Fix sum() so it adds instead of subtracting'

function _Ch19-RepoFull { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch19-SeedRepo {
  Write-WthStep 'seeding tiny buggy app + failing test + CI'
  $org = $Global:WthOrg
  $repo = $Global:WthRepo

  $readme = @"
# wth-ch19 — Copilot Cloud Agent Task

A deliberately tiny repo with ONE clear bug. The failing test pins it; the
seeded issue describes the fix with acceptance criteria — ready to hand to the
Copilot cloud agent.

- ``src/math.js`` — contains the bug
- ``test/math.test.js`` — failing test that pins the bug
- ``.github/workflows/ci.yml`` — runs the test on every push/PR

> Copilot cloud agent must be enabled for your org/account (manual prerequisite).
"@
  Set-WthFile -Org $org -Repo $repo -Path 'README.md' -Message 'Add Copilot cloud agent task overview' -Content $readme

  $pkg = @'
{
  "name": "wth-ch19-coding-agent",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "node test/math.test.js"
  }
}
'@
  Set-WthFile -Org $org -Repo $repo -Path 'package.json' -Message 'Add minimal package.json' -Content $pkg

  $math = @'
// wth-ch19 — BUG: sum() subtracts instead of adding. Fix me.
function sum (a, b) {
  return a - b
}
module.exports = { sum }
'@
  Set-WthFile -Org $org -Repo $repo -Path 'src/math.js' -Message 'Add math module (with deliberate bug)' -Content $math

  $test = @'
// wth-ch19 — fails until sum() is fixed to add.
const assert = require('assert')
const { sum } = require('../src/math')

assert.strictEqual(sum(2, 3), 5, 'sum(2, 3) should be 5')
assert.strictEqual(sum(10, 5), 15, 'sum(10, 5) should be 15')
console.log('all tests passed')
'@
  Set-WthFile -Org $org -Repo $repo -Path 'test/math.test.js' -Message 'Add failing test that pins the bug' -Content $test

  $ci = @'
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
permissions:
  contents: read
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - run: npm test
'@
  Set-WthFile -Org $org -Repo $repo -Path '.github/workflows/ci.yml' -Message 'Add CI workflow' -Content $ci
}

function _Ch19-SeedIssue {
  Write-WthStep 'seeding the Copilot-ready issue'
  $existing = gh issue list --repo (_Ch19-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $Global:WthIssueTitle) { Write-WthOk "issue '$($Global:WthIssueTitle)' exists (skip)"; return }
  $body = @'
## Problem
`src/math.js` exports `sum(a, b)` but it currently returns `a - b`, so addition
is wrong and the test suite fails.

## Repro
```
npm test
```
You'll see `sum(2, 3) should be 5` fail.

## Acceptance criteria
- [ ] `sum(2, 3)` returns `5`
- [ ] `sum(10, 5)` returns `15`
- [ ] `npm test` passes
- [ ] No unrelated changes

Hand this issue to the Copilot cloud agent and review its PR.
'@
  Invoke-WthMutation -Plan "gh issue create '$($Global:WthIssueTitle)'" -Action {
    gh issue create --repo (_Ch19-RepoFull) --title $Global:WthIssueTitle --body $body
  }
}

# ===========================================================================
function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility 'public'
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch19-RepoFull) missing after create — aborting seed"
  }
  _Ch19-SeedRepo
  _Ch19-SeedIssue
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - assign the seeded issue to the Copilot cloud agent'
  Write-WthInfo "  - review the agent's PR and confirm CI goes green"
  Write-WthWarn 'manual: enable the Copilot cloud agent for your org/account first (EMU-incompatible challenge).'
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $test = if (Test-WthFileExists -Org $Global:WthOrg -Repo $Global:WthRepo -Path 'test/math.test.js') { 'present' } else { 'MISSING' }
    $issues = gh issue list --repo (_Ch19-RepoFull) --state all --limit 100 --json number --jq 'length' 2>$null
    Write-WthOk "repo $(_Ch19-RepoFull) present — failing test $test, $issues issue(s)"
  } else {
    Write-WthInfo "repo $(_Ch19-RepoFull) not provisioned"
  }
}
