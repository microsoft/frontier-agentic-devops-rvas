# challenges/ch09-audit-log-streaming/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ORG-SCOPED. ch09: a populated audit-target repo, an auditors team, and a
# printed sample of recent org audit events. Configuring a real audit-log
# STREAM endpoint is a documented manual step (not API-automatable).

$Global:WthR09Target = "wth-$($Global:WthChid)-audit-target"
$Global:WthTeam09    = "wth-$($Global:WthChid)-auditors"

function _Ch09-SeedTarget {
  $o = $Global:WthOrg; $r = $Global:WthR09Target; $ch = $Global:WthChid
  Set-WthFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# $r

Seeded by wth-$ch (Audit Log Streaming). Activity here (pushes, team
changes, settings edits) shows up in the org audit log. Set up streaming and
verify these events land in your sink.
"@
  Set-WthFile -Org $o -Repo $r -Path 'src/index.js' -Message "seed src (wth-$ch)" -Content @"
console.log('audit target — wth-$ch');
"@
}

# ===========================================================================
function Invoke-WthProvision {
  $o = $Global:WthOrg
  New-WthRepo -Org $o -Repo $Global:WthR09Target -Visibility private
  if (-not $Global:WthDryRun) {
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR09Target) { _Ch09-SeedTarget }
  } else {
    Write-WthPlan "would seed README + src into $($Global:WthR09Target)"
  }

  New-WthTeam -Org $o -Name $Global:WthTeam09 -Description "wth-$($Global:WthChid) auditors team"

  Write-WthStep "recent org audit events sample for '$o'"
  if ($Global:WthDryRun) {
    Write-WthPlan "would read: gh api orgs/$o/audit-log (first few events)"
  } else {
    try {
      gh api "orgs/$o/audit-log`?per_page=5" --jq '.[] | {action, actor, created_at}'
    } catch {
      Write-WthWarn "could not read the audit log — this API is GHEC-only and needs a token with 'read:audit_log' (admin:org)."
    }
  }

  Write-Host ''
  Write-WthWarn "MANUAL STEP: configuring an audit-log STREAM endpoint (Azure Blob, S3, Splunk, Datadog, etc.) is not API-automatable — set it up under Org Settings -> Audit log -> Log streaming."
}

function Invoke-WthTeardown {
  $o = $Global:WthOrg
  if (-not (Confirm-WthPrefix -Name $Global:WthR09Target -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $o -Repo $Global:WthR09Target
  if (-not (Confirm-WthPrefix -Name $Global:WthTeam09 -Chid $Global:WthChid)) { return }
  Remove-WthTeam -Org $o -Team $Global:WthTeam09
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  $o = $Global:WthOrg
  if (Test-WthRepoExists -Org $o -Repo $Global:WthR09Target) { Write-WthOk "repo $o/$($Global:WthR09Target) present" } else { Write-WthInfo "repo $o/$($Global:WthR09Target) absent" }
  if (Test-WthTeamExists -Org $o -Team $Global:WthTeam09) { Write-WthOk "team $($Global:WthTeam09) present" } else { Write-WthInfo "team $($Global:WthTeam09) absent" }
}
