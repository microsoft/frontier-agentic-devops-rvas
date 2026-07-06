# challenges/ch09-audit-log-streaming/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ORG-SCOPED. ch09: a populated audit-target repo, an auditors team, and a
# printed sample of recent org audit events. Configuring a real audit-log
# STREAM endpoint is a documented manual step (not API-automatable).

$Global:GhecR09Target = "ghec-$($Global:GhecChid)-audit-target"
$Global:GhecTeam09    = "ghec-$($Global:GhecChid)-auditors"

function _Ch09-SeedTarget {
  $o = $Global:GhecOrg; $r = $Global:GhecR09Target; $ch = $Global:GhecChid
  Set-GhecFile -Org $o -Repo $r -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# $r

Seeded by ghec-$ch (Audit Log Streaming). Activity here (pushes, team
changes, settings edits) shows up in the org audit log. Set up streaming and
verify these events land in your sink.
"@
  Set-GhecFile -Org $o -Repo $r -Path 'src/index.js' -Message "seed src (ghec-$ch)" -Content @"
console.log('audit target — ghec-$ch');
"@
}

# ===========================================================================
function Invoke-GhecProvision {
  $o = $Global:GhecOrg
  New-GhecRepo -Org $o -Repo $Global:GhecR09Target -Visibility private
  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR09Target) { _Ch09-SeedTarget }
  } else {
    Write-GhecPlan "would seed README + src into $($Global:GhecR09Target)"
  }

  New-GhecTeam -Org $o -Name $Global:GhecTeam09 -Description "ghec-$($Global:GhecChid) auditors team"

  Write-GhecStep "recent org audit events sample for '$o'"
  if ($Global:GhecDryRun) {
    Write-GhecPlan "would read: gh api orgs/$o/audit-log (first few events)"
  } else {
    try {
      gh api "orgs/$o/audit-log`?per_page=5" --jq '.[] | {action, actor, created_at}'
    } catch {
      Write-GhecWarn "could not read the audit log — this API is GHEC-only and needs a token with 'read:audit_log' (admin:org)."
    }
  }

  Write-Host ''
  Write-GhecWarn "MANUAL STEP: configuring an audit-log STREAM endpoint (Azure Blob, S3, Splunk, Datadog, etc.) is not API-automatable — set it up under Org Settings -> Audit log -> Log streaming."
}

function Invoke-GhecTeardown {
  $o = $Global:GhecOrg
  if (-not (Confirm-GhecPrefix -Name $Global:GhecR09Target -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $o -Repo $Global:GhecR09Target
  if (-not (Confirm-GhecPrefix -Name $Global:GhecTeam09 -Chid $Global:GhecChid)) { return }
  Remove-GhecTeam -Org $o -Team $Global:GhecTeam09
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  $o = $Global:GhecOrg
  if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR09Target) { Write-GhecOk "repo $o/$($Global:GhecR09Target) present" } else { Write-GhecInfo "repo $o/$($Global:GhecR09Target) absent" }
  if (Test-GhecTeamExists -Org $o -Team $Global:GhecTeam09) { Write-GhecOk "team $($Global:GhecTeam09) present" } else { Write-GhecInfo "team $($Global:GhecTeam09) absent" }
}
