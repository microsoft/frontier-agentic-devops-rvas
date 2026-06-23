# challenges/ch08-rulesets-repo-properties/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ORG-SCOPED. ch08: four populated repos, each with a working 'build'-check CI,
# plus a printed inventory. No custom properties or rulesets yet.

$Global:WthR08 = @(
  "wth-$($Global:WthChid)-prod-payments",
  "wth-$($Global:WthChid)-prod-identity",
  "wth-$($Global:WthChid)-internal-tools",
  "wth-$($Global:WthChid)-sandbox"
)

function _Ch08-SeedRepo {
  param([string]$Repo)
  $o = $Global:WthOrg; $ch = $Global:WthChid
  Set-WthFile -Org $o -Repo $Repo -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# $Repo

Seeded by wth-$ch (Rulesets & Repo Properties). CI publishes a ``build``
check on every push/PR. No custom properties or rulesets are set yet.
"@
  Set-WthFile -Org $o -Repo $Repo -Path 'package.json' -Message "seed package.json (wth-$ch)" -Content @"
{
  "name": "$Repo",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node test/app.test.js" }
}
"@
  Set-WthFile -Org $o -Repo $Repo -Path 'src/index.js' -Message "seed src (wth-$ch)" -Content @"
module.exports = { ok: true };
"@
  Set-WthFile -Org $o -Repo $Repo -Path 'test/app.test.js' -Message "seed test (wth-$ch)" -Content @"
const assert = require('assert');
assert.strictEqual(require('../src/index').ok, true);
console.log('ok - build check passed');
"@
  Set-WthFile -Org $o -Repo $Repo -Path '.github/workflows/ci.yml' -Message "seed build-check CI (wth-$ch)" -Content @"
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
}

# ===========================================================================
function Invoke-WthProvision {
  $o = $Global:WthOrg
  foreach ($r in $Global:WthR08) { New-WthRepo -Org $o -Repo $r -Visibility private }

  if (-not $Global:WthDryRun) {
    foreach ($r in $Global:WthR08) {
      if (Test-WthRepoExists -Org $o -Repo $r) { _Ch08-SeedRepo -Repo $r }
    }
  } else {
    Write-WthPlan "would seed app + build-check CI into the four repos"
  }

  Write-WthStep "repo inventory for '$o' (wth-$($Global:WthChid))"
  foreach ($r in $Global:WthR08) {
    if ($Global:WthDryRun) {
      Write-WthPlan "would read: gh api repos/$o/$r (visibility, default_branch)"
    } elseif (Test-WthRepoExists -Org $o -Repo $r) {
      try { gh api "repos/$o/$r" --jq '"\(.full_name)\tvisibility=\(.visibility)\tdefault_branch=\(.default_branch)"' }
      catch { Write-WthWarn "could not read $o/$r" }
    }
  }
}

function Invoke-WthTeardown {
  $o = $Global:WthOrg
  foreach ($r in $Global:WthR08) {
    if (-not (Confirm-WthPrefix -Name $r -Chid $Global:WthChid)) { return }
    Remove-WthRepo -Org $o -Repo $r
  }
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  $o = $Global:WthOrg
  foreach ($r in $Global:WthR08) {
    if (Test-WthRepoExists -Org $o -Repo $r) { Write-WthOk "repo $o/$r present" } else { Write-WthInfo "repo $o/$r absent" }
  }
}
