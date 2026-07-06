# challenges/ch10-billing-cost-centers/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ORG-SCOPED. ch10: a usage-generator repo (workflow_dispatch usage.yml) and a
# cost-report repo (reconcile.js + REPORT.md), plus a printed Actions usage
# snapshot. Cost-center creation/assignment is a documented manual step.

$Global:GhecR10Gen = "ghec-$($Global:GhecChid)-usage-generator"
$Global:GhecR10Rpt = "ghec-$($Global:GhecChid)-cost-report"

function _Ch10-SeedGenerator {
  $o = $Global:GhecOrg; $r = $Global:GhecR10Gen; $ch = $Global:GhecChid
  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# $r

Seeded by ghec-$ch (Billing & Cost Centers). Run the 'usage' workflow
(Actions -> Run workflow) a few times to generate Actions minutes, then watch
them show up in billing and your cost-report reconciliation.
"@
  Set-GhecFile -Org $o -Repo $r -Path '.github/workflows/usage.yml' -Message "seed usage workflow (ghec-$ch)" -Content @"
name: usage
# ghec-$ch — manually triggered to burn a little Actions usage.
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
          echo "Generating usage for ghec-$ch..."
          sleep "`${{ inputs.seconds }}"
          echo 'done'
"@
}

function _Ch10-SeedReport {
  $o = $Global:GhecOrg; $r = $Global:GhecR10Rpt; $ch = $Global:GhecChid
  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# $r

Seeded by ghec-$ch. A starting point for reconciling Actions/usage against
cost centers. Flesh out ``reconcile.js`` to pull billing data and group spend.
"@
  Set-GhecFile -Org $o -Repo $r -Path 'reconcile.js' -Message "seed reconciliation script (ghec-$ch)" -Content @"
#!/usr/bin/env node
// ghec-$ch starter reconciliation. Replace the sample with real billing data
// from: gh api orgs/<org>/settings/billing/actions
const sample = { included_minutes: 3000, total_minutes_used: 0, cost_centers: {} };
console.log('ghec-$ch usage reconciliation');
console.table(sample);
"@
  Set-GhecFile -Org $o -Repo $r -Path 'REPORT.md' -Message "seed REPORT.md (ghec-$ch)" -Content @"
# Cost Report (ghec-$ch)

| Cost center | Repos | Actions minutes | Notes |
|-------------|-------|-----------------|-------|
| _unassigned_ | $($Global:GhecR10Gen), $($Global:GhecR10Rpt) | TBD | fill in after running usage |

> Update this after assigning repos to cost centers and running the generator.
"@
}

# ===========================================================================
function Invoke-GhecProvision {
  $o = $Global:GhecOrg
  New-GhecRepo -Org $o -Repo $Global:GhecR10Gen -Visibility private
  New-GhecRepo -Org $o -Repo $Global:GhecR10Rpt -Visibility private

  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR10Gen) { _Ch10-SeedGenerator }
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR10Rpt) { _Ch10-SeedReport }
  } else {
    Write-GhecPlan "would seed usage workflow into $($Global:GhecR10Gen) and reconcile.js + REPORT.md into $($Global:GhecR10Rpt)"
  }

  Write-GhecStep "current Actions usage snapshot for '$o'"
  if ($Global:GhecDryRun) {
    Write-GhecPlan "would read: gh api orgs/$o/settings/billing/actions"
  } else {
    try {
      gh api "orgs/$o/settings/billing/actions" --jq '{total_minutes_used, included_minutes, total_paid_minutes_used}'
    } catch {
      Write-GhecWarn "could not read billing — needs a token with 'read:org' / billing access (GHEC org billing manager)."
    }
  }

  Write-Host ''
  Write-GhecWarn "MANUAL STEP: creating cost centers and assigning repos/users to them is done in Enterprise billing settings (and the Billing Platform API where available) — it is not fully automatable here."
}

function Invoke-GhecTeardown {
  $o = $Global:GhecOrg
  foreach ($r in @($Global:GhecR10Gen, $Global:GhecR10Rpt)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $o -Repo $r
  }
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  $o = $Global:GhecOrg
  foreach ($r in @($Global:GhecR10Gen, $Global:GhecR10Rpt)) {
    if (Test-GhecRepoExists -Org $o -Repo $r) { Write-GhecOk "repo $o/$r present" } else { Write-GhecInfo "repo $o/$r absent" }
  }
}
