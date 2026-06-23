# challenges/ch10-billing-cost-centers/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ORG-SCOPED. ch10: a usage-generator repo (workflow_dispatch usage.yml) and a
# cost-report repo (reconcile.js + REPORT.md), plus a printed Actions usage
# snapshot. Cost-center creation/assignment is a documented manual step.

$Global:WthR10Gen = "wth-$($Global:WthChid)-usage-generator"
$Global:WthR10Rpt = "wth-$($Global:WthChid)-cost-report"

function _Ch10-SeedGenerator {
  $o = $Global:WthOrg; $r = $Global:WthR10Gen; $ch = $Global:WthChid
  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# $r

Seeded by wth-$ch (Billing & Cost Centers). Run the 'usage' workflow
(Actions -> Run workflow) a few times to generate Actions minutes, then watch
them show up in billing and your cost-report reconciliation.
"@
  Set-WthFile -Org $o -Repo $r -Path '.github/workflows/usage.yml' -Message "seed usage workflow (wth-$ch)" -Content @"
name: usage
# wth-$ch — manually triggered to burn a little Actions usage.
on:
  workflow_dispatch:
    inputs:
      seconds:
        description: 'How long to sleep (sim work)'
        default: '5'
jobs:
  burn:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Generating usage for wth-$ch..."
          sleep "`${{ inputs.seconds }}"
          echo 'done'
"@
}

function _Ch10-SeedReport {
  $o = $Global:WthOrg; $r = $Global:WthR10Rpt; $ch = $Global:WthChid
  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# $r

Seeded by wth-$ch. A starting point for reconciling Actions/usage against
cost centers. Flesh out ``reconcile.js`` to pull billing data and group spend.
"@
  Set-WthFile -Org $o -Repo $r -Path 'reconcile.js' -Message "seed reconciliation script (wth-$ch)" -Content @"
#!/usr/bin/env node
// wth-$ch starter reconciliation. Replace the sample with real billing data
// from: gh api orgs/<org>/settings/billing/actions
const sample = { included_minutes: 3000, total_minutes_used: 0, cost_centers: {} };
console.log('wth-$ch usage reconciliation');
console.table(sample);
"@
  Set-WthFile -Org $o -Repo $r -Path 'REPORT.md' -Message "seed REPORT.md (wth-$ch)" -Content @"
# Cost Report (wth-$ch)

| Cost center | Repos | Actions minutes | Notes |
|-------------|-------|-----------------|-------|
| _unassigned_ | $($Global:WthR10Gen), $($Global:WthR10Rpt) | TBD | fill in after running usage |

> Update this after assigning repos to cost centers and running the generator.
"@
}

# ===========================================================================
function Invoke-WthProvision {
  $o = $Global:WthOrg
  New-WthRepo -Org $o -Repo $Global:WthR10Gen -Visibility private
  New-WthRepo -Org $o -Repo $Global:WthR10Rpt -Visibility private

  if (-not $Global:WthDryRun) {
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR10Gen) { _Ch10-SeedGenerator }
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR10Rpt) { _Ch10-SeedReport }
  } else {
    Write-WthPlan "would seed usage workflow into $($Global:WthR10Gen) and reconcile.js + REPORT.md into $($Global:WthR10Rpt)"
  }

  Write-WthStep "current Actions usage snapshot for '$o'"
  if ($Global:WthDryRun) {
    Write-WthPlan "would read: gh api orgs/$o/settings/billing/actions"
  } else {
    try {
      gh api "orgs/$o/settings/billing/actions" --jq '{total_minutes_used, included_minutes, total_paid_minutes_used}'
    } catch {
      Write-WthWarn "could not read billing — needs a token with 'read:org' / billing access (GHEC org billing manager)."
    }
  }

  Write-Host ''
  Write-WthWarn "MANUAL STEP: creating cost centers and assigning repos/users to them is done in Enterprise billing settings (and the Billing Platform API where available) — it is not fully automatable here."
}

function Invoke-WthTeardown {
  $o = $Global:WthOrg
  foreach ($r in @($Global:WthR10Gen, $Global:WthR10Rpt)) {
    if (-not (Confirm-WthPrefix -Name $r -Chid $Global:WthChid)) { return }
    Remove-WthRepo -Org $o -Repo $r
  }
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  $o = $Global:WthOrg
  foreach ($r in @($Global:WthR10Gen, $Global:WthR10Rpt)) {
    if (Test-WthRepoExists -Org $o -Repo $r) { Write-WthOk "repo $o/$r present" } else { Write-WthInfo "repo $o/$r absent" }
  }
}
