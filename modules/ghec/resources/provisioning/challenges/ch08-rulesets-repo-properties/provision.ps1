# challenges/ch08-rulesets-repo-properties/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ORG-SCOPED. ch08: four populated repos, each with a working 'build'-check CI,
# plus a printed inventory. No custom properties or rulesets yet.

$Global:GhecR08 = @(
  "ghec-$($Global:GhecChid)-prod-payments",
  "ghec-$($Global:GhecChid)-prod-identity",
  "ghec-$($Global:GhecChid)-internal-tools",
  "ghec-$($Global:GhecChid)-sandbox"
)

function _Ch08-SeedRepo {
  param([string]$Repo)
  $o = $Global:GhecOrg; $ch = $Global:GhecChid
  Set-GhecFile -Org $o -Repo $Repo -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# $Repo

Seeded by ghec-$ch (Rulesets & Repo Properties). CI publishes a ``build``
check on every push/PR. No custom properties or rulesets are set yet.
"@
  Set-GhecFile -Org $o -Repo $Repo -Path 'package.json' -Message "seed package.json (ghec-$ch)" -Content @"
{
  "name": "$Repo",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node test/app.test.js" }
}
"@
  Set-GhecFile -Org $o -Repo $Repo -Path 'src/index.js' -Message "seed src (ghec-$ch)" -Content @"
module.exports = { ok: true };
"@
  Set-GhecFile -Org $o -Repo $Repo -Path 'test/app.test.js' -Message "seed test (ghec-$ch)" -Content @"
const assert = require('assert');
assert.strictEqual(require('../src/index').ok, true);
console.log('ok - build check passed');
"@
  Set-GhecFile -Org $o -Repo $Repo -Path '.github/workflows/ci.yml' -Message "seed build-check CI (ghec-$ch)" -Content @"
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
function Invoke-GhecProvision {
  $o = $Global:GhecOrg
  foreach ($r in $Global:GhecR08) { New-GhecRepo -Org $o -Repo $r -Visibility private }

  if (-not $Global:GhecDryRun) {
    foreach ($r in $Global:GhecR08) {
      if (Test-GhecRepoExists -Org $o -Repo $r) { _Ch08-SeedRepo -Repo $r }
    }
  } else {
    Write-GhecPlan "would seed app + build-check CI into the four repos"
  }

  Write-GhecStep "repo inventory for '$o' (ghec-$($Global:GhecChid))"
  foreach ($r in $Global:GhecR08) {
    if ($Global:GhecDryRun) {
      Write-GhecPlan "would read: gh api repos/$o/$r (visibility, default_branch)"
    } elseif (Test-GhecRepoExists -Org $o -Repo $r) {
      try { gh api "repos/$o/$r" --jq '"\(.full_name)\tvisibility=\(.visibility)\tdefault_branch=\(.default_branch)"' }
      catch { Write-GhecWarn "could not read $o/$r" }
    }
  }
}

function Invoke-GhecTeardown {
  $o = $Global:GhecOrg
  foreach ($r in $Global:GhecR08) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $o -Repo $r
  }
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  $o = $Global:GhecOrg
  foreach ($r in $Global:GhecR08) {
    if (Test-GhecRepoExists -Org $o -Repo $r) { Write-GhecOk "repo $o/$r present" } else { Write-GhecInfo "repo $o/$r absent" }
  }
}
