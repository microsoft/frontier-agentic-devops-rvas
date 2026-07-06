# challenges/ch07-teams-roles-permissions/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ORG-SCOPED. ch07: three seeded repos (frontend/backend/platform), a flat
# starter team with the current authenticated user as sole member and no repo
# grants yet, plus a printed access snapshot.

$Global:GhecR07Fe   = "ghec-$($Global:GhecChid)-frontend"
$Global:GhecR07Be   = "ghec-$($Global:GhecChid)-backend"
$Global:GhecR07Pl   = "ghec-$($Global:GhecChid)-platform"
$Global:GhecTeam07  = "ghec-$($Global:GhecChid)-engineering"

function _Ch07-SeedRepo {
  param([string]$Repo, [string]$Area)
  $o = $Global:GhecOrg; $ch = $Global:GhecChid
  Set-GhecFile -Org $o -Repo $Repo -Path 'README.md' -Message "seed README (ghec-$ch)" -Content @"
# $Repo

The $Area service, seeded by ghec-$ch (Teams, Roles & Permissions).
No team has access yet — that's your job.
"@
  Set-GhecFile -Org $o -Repo $Repo -Path 'src/index.js' -Message "seed src tree (ghec-$ch)" -Content @"
console.log('$Area service — ghec-$ch');
"@
}

# ===========================================================================
function Invoke-GhecProvision {
  $o = $Global:GhecOrg
  New-GhecRepo -Org $o -Repo $Global:GhecR07Fe -Visibility private
  New-GhecRepo -Org $o -Repo $Global:GhecR07Be -Visibility private
  New-GhecRepo -Org $o -Repo $Global:GhecR07Pl -Visibility private

  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR07Fe) { _Ch07-SeedRepo -Repo $Global:GhecR07Fe -Area 'frontend' }
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR07Be) { _Ch07-SeedRepo -Repo $Global:GhecR07Be -Area 'backend' }
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR07Pl) { _Ch07-SeedRepo -Repo $Global:GhecR07Pl -Area 'platform' }
  } else {
    Write-GhecPlan "would seed README + src tree into the three service repos"
  }

  New-GhecTeam -Org $o -Name $Global:GhecTeam07 -Description "ghec-$($Global:GhecChid) flat starter team"
  $me = Get-GhecLogin
  if ($me) {
    Add-GhecTeamMember -Org $o -Team $Global:GhecTeam07 -User $me -Role member
  } else {
    Write-GhecWarn "could not resolve current login — add a member to '$($Global:GhecTeam07)' manually"
  }

  Write-GhecStep "team + repo access snapshot for '$o'"
  if ($Global:GhecDryRun) {
    Write-GhecPlan "would list org teams and per-repo grants for the ghec-$($Global:GhecChid) repos"
  } else {
    try {
      gh api "orgs/$o/teams" --jq '.[] | {slug, privacy, permission}'
    } catch {
      Write-GhecWarn "could not list teams (needs read:org)"
    }
  }
}

function Invoke-GhecTeardown {
  $o = $Global:GhecOrg
  foreach ($r in @($Global:GhecR07Fe, $Global:GhecR07Be, $Global:GhecR07Pl)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $o -Repo $r
  }
  if (-not (Confirm-GhecPrefix -Name $Global:GhecTeam07 -Chid $Global:GhecChid)) { return }
  Remove-GhecTeam -Org $o -Team $Global:GhecTeam07
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  $o = $Global:GhecOrg
  foreach ($r in @($Global:GhecR07Fe, $Global:GhecR07Be, $Global:GhecR07Pl)) {
    if (Test-GhecRepoExists -Org $o -Repo $r) { Write-GhecOk "repo $o/$r present" } else { Write-GhecInfo "repo $o/$r absent" }
  }
  if (Test-GhecTeamExists -Org $o -Team $Global:GhecTeam07) { Write-GhecOk "team $($Global:GhecTeam07) present" } else { Write-GhecInfo "team $($Global:GhecTeam07) absent" }
}
