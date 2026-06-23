# challenges/ch07-teams-roles-permissions/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ORG-SCOPED. ch07: three seeded repos (frontend/backend/platform), a flat
# starter team with the current authenticated user as sole member and no repo
# grants yet, plus a printed access snapshot.

$Global:WthR07Fe   = "wth-$($Global:WthChid)-frontend"
$Global:WthR07Be   = "wth-$($Global:WthChid)-backend"
$Global:WthR07Pl   = "wth-$($Global:WthChid)-platform"
$Global:WthTeam07  = "wth-$($Global:WthChid)-engineering"

function _Ch07-SeedRepo {
  param([string]$Repo, [string]$Area)
  $o = $Global:WthOrg; $ch = $Global:WthChid
  Set-WthFile -Org $o -Repo $Repo -Path 'README.md' -Message "seed README (wth-$ch)" -Content @"
# $Repo

The $Area service, seeded by wth-$ch (Teams, Roles & Permissions).
No team has access yet — that's your job.
"@
  Set-WthFile -Org $o -Repo $Repo -Path 'src/index.js' -Message "seed src tree (wth-$ch)" -Content @"
console.log('$Area service — wth-$ch');
"@
}

# ===========================================================================
function Invoke-WthProvision {
  $o = $Global:WthOrg
  New-WthRepo -Org $o -Repo $Global:WthR07Fe -Visibility private
  New-WthRepo -Org $o -Repo $Global:WthR07Be -Visibility private
  New-WthRepo -Org $o -Repo $Global:WthR07Pl -Visibility private

  if (-not $Global:WthDryRun) {
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR07Fe) { _Ch07-SeedRepo -Repo $Global:WthR07Fe -Area 'frontend' }
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR07Be) { _Ch07-SeedRepo -Repo $Global:WthR07Be -Area 'backend' }
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR07Pl) { _Ch07-SeedRepo -Repo $Global:WthR07Pl -Area 'platform' }
  } else {
    Write-WthPlan "would seed README + src tree into the three service repos"
  }

  New-WthTeam -Org $o -Name $Global:WthTeam07 -Description "wth-$($Global:WthChid) flat starter team"
  $me = Get-WthLogin
  if ($me) {
    Add-WthTeamMember -Org $o -Team $Global:WthTeam07 -User $me -Role member
  } else {
    Write-WthWarn "could not resolve current login — add a member to '$($Global:WthTeam07)' manually"
  }

  Write-WthStep "team + repo access snapshot for '$o'"
  if ($Global:WthDryRun) {
    Write-WthPlan "would list org teams and per-repo grants for the wth-$($Global:WthChid) repos"
  } else {
    try {
      gh api "orgs/$o/teams" --jq '.[] | {slug, privacy, permission}'
    } catch {
      Write-WthWarn "could not list teams (needs read:org)"
    }
  }
}

function Invoke-WthTeardown {
  $o = $Global:WthOrg
  foreach ($r in @($Global:WthR07Fe, $Global:WthR07Be, $Global:WthR07Pl)) {
    if (-not (Confirm-WthPrefix -Name $r -Chid $Global:WthChid)) { return }
    Remove-WthRepo -Org $o -Repo $r
  }
  if (-not (Confirm-WthPrefix -Name $Global:WthTeam07 -Chid $Global:WthChid)) { return }
  Remove-WthTeam -Org $o -Team $Global:WthTeam07
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  $o = $Global:WthOrg
  foreach ($r in @($Global:WthR07Fe, $Global:WthR07Be, $Global:WthR07Pl)) {
    if (Test-WthRepoExists -Org $o -Repo $r) { Write-WthOk "repo $o/$r present" } else { Write-WthInfo "repo $o/$r absent" }
  }
  if (Test-WthTeamExists -Org $o -Team $Global:WthTeam07) { Write-WthOk "team $($Global:WthTeam07) present" } else { Write-WthInfo "team $($Global:WthTeam07) absent" }
}
