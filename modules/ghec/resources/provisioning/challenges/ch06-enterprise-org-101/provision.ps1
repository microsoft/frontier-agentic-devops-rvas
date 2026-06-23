# challenges/ch06-enterprise-org-101/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-WthProvision / Invoke-WthTeardown / Invoke-WthStatus
#
# ORG-SCOPED. ch06: three sample repos (public/private/internal-soft), a
# members team with one repo attached at default permission, and a printed
# baseline snapshot of the org's member-privilege settings.

$Global:WthR06Pub  = "wth-$($Global:WthChid)-public-sample"
$Global:WthR06Priv = "wth-$($Global:WthChid)-private-sample"
$Global:WthR06Int  = "wth-$($Global:WthChid)-internal-sample"
$Global:WthTeam06  = "wth-$($Global:WthChid)-members"

function _Ch06-SeedReadme {
  param([string]$Repo, [string]$Vis)
  Set-WthFile -Org $Global:WthOrg -Repo $Repo -Path 'README.md' -Message "seed README (wth-$($Global:WthChid))" -Content @"
# $Repo

A $Vis sample repo seeded by wth-$($Global:WthChid) (Enterprise Org 101).
Use it to explore visibility, base permissions, and member privileges.
"@
}

# ===========================================================================
function Invoke-WthProvision {
  $o = $Global:WthOrg
  New-WthRepo -Org $o -Repo $Global:WthR06Pub  -Visibility public
  New-WthRepo -Org $o -Repo $Global:WthR06Priv -Visibility private
  New-WthRepoSoft -Org $o -Repo $Global:WthR06Int -Visibility internal

  if (-not $Global:WthDryRun) {
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR06Pub)  { _Ch06-SeedReadme -Repo $Global:WthR06Pub  -Vis 'public' }
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR06Priv) { _Ch06-SeedReadme -Repo $Global:WthR06Priv -Vis 'private' }
    if (Test-WthRepoExists -Org $o -Repo $Global:WthR06Int)  { _Ch06-SeedReadme -Repo $Global:WthR06Int  -Vis 'internal' }
  } else {
    Write-WthPlan "would seed README into the three sample repos (when present)"
  }

  New-WthTeam -Org $o -Name $Global:WthTeam06 -Description "wth-$($Global:WthChid) sample members team"
  Add-WthTeamRepo -Org $o -Team $Global:WthTeam06 -Repo $Global:WthR06Pub -Permission pull

  Write-WthStep "org member-privilege snapshot for '$o'"
  if ($Global:WthDryRun) {
    Write-WthPlan "would read: gh api orgs/$o (default_repository_permission, members_can_create_repositories, ...)"
  } else {
    try {
      gh api "orgs/$o" --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories, two_factor_requirement_enabled}'
    } catch {
      Write-WthWarn "could not read org settings (needs admin:org / read:org)"
    }
  }
}

function Invoke-WthTeardown {
  $o = $Global:WthOrg
  foreach ($r in @($Global:WthR06Pub, $Global:WthR06Priv, $Global:WthR06Int)) {
    if (-not (Confirm-WthPrefix -Name $r -Chid $Global:WthChid)) { return }
    Remove-WthRepo -Org $o -Repo $r
  }
  if (-not (Confirm-WthPrefix -Name $Global:WthTeam06 -Chid $Global:WthChid)) { return }
  Remove-WthTeam -Org $o -Team $Global:WthTeam06
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  $o = $Global:WthOrg
  foreach ($r in @($Global:WthR06Pub, $Global:WthR06Priv, $Global:WthR06Int)) {
    if (Test-WthRepoExists -Org $o -Repo $r) { Write-WthOk "repo $o/$r present" } else { Write-WthInfo "repo $o/$r absent" }
  }
  if (Test-WthTeamExists -Org $o -Team $Global:WthTeam06) { Write-WthOk "team $($Global:WthTeam06) present" } else { Write-WthInfo "team $($Global:WthTeam06) absent" }
}
