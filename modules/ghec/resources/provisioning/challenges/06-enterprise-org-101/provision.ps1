# challenges/ch06-enterprise-org-101/provision.ps1
#
# Dot-sourced by scripts/setup.ps1. CONTRACT:
#   Invoke-GhecProvision / Invoke-GhecTeardown / Invoke-GhecStatus
#
# ORG-SCOPED. ch06: sample repos for visibility governance, a members team
# with one repo attached at default permission, and a printed baseline snapshot
# of the org's member-privilege settings.

$Global:GhecR06Pub  = "ghec-$($Global:GhecChid)-public-sample"
$Global:GhecR06Priv = "ghec-$($Global:GhecChid)-private-sample"
$Global:GhecR06Int  = "ghec-$($Global:GhecChid)-internal-sample"
$Global:GhecTeam06  = "ghec-$($Global:GhecChid)-members"

function _Ch06-SeedReadme {
  param([string]$Repo, [string]$Vis)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Repo -Path 'README.md' -Message "seed README (ghec-$($Global:GhecChid))" -Content @"
# $Repo

A $Vis sample repo seeded by ghec-$($Global:GhecChid) (Enterprise Org 101).
Use it to explore visibility, base permissions, and member privileges.
"@
}

function _Ch06-RepoVisibility {
  param([string]$Repo)
  $v = gh repo view "$($Global:GhecOrg)/$Repo" --json visibility --jq '.visibility' 2>$null
  if ($v) { return $v.ToLowerInvariant() }
  return ''
}

# ===========================================================================
function Invoke-GhecProvision {
  $o = $Global:GhecOrg
  # Public creation is retried as private by the shared helper on EMU, where
  # public repositories are platform-blocked.
  New-GhecRepo -Org $o -Repo $Global:GhecR06Pub  -Visibility public
  New-GhecRepo -Org $o -Repo $Global:GhecR06Priv -Visibility private
  New-GhecRepoSoft -Org $o -Repo $Global:GhecR06Int -Visibility internal

  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR06Pub)  {
      $pubVis = _Ch06-RepoVisibility -Repo $Global:GhecR06Pub
      if ($pubVis -ne 'public') { Write-GhecWarn "$($Global:GhecR06Pub) was requested as public but is '$pubVis' (expected on EMU)" }
      $pubLabel = if ($pubVis) { $pubVis } else { 'public-requested' }
      _Ch06-SeedReadme -Repo $Global:GhecR06Pub -Vis $pubLabel
    }
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR06Priv) { _Ch06-SeedReadme -Repo $Global:GhecR06Priv -Vis (_Ch06-RepoVisibility -Repo $Global:GhecR06Priv) }
    if (Test-GhecRepoExists -Org $o -Repo $Global:GhecR06Int)  { _Ch06-SeedReadme -Repo $Global:GhecR06Int -Vis (_Ch06-RepoVisibility -Repo $Global:GhecR06Int) }
  } else {
    Write-GhecPlan "would seed README into the three sample repos (when present)"
  }

  New-GhecTeam -Org $o -Name $Global:GhecTeam06 -Description "ghec-$($Global:GhecChid) sample members team"
  Add-GhecTeamRepo -Org $o -Team $Global:GhecTeam06 -Repo $Global:GhecR06Pub -Permission pull

  Write-GhecStep "org member-privilege snapshot for '$o'"
  if ($Global:GhecDryRun) {
    Write-GhecPlan "would read: gh api orgs/$o (default_repository_permission, members_can_create_repositories, ...)"
  } else {
    try {
      gh api "orgs/$o" --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories, two_factor_requirement_enabled}'
    } catch {
      Write-GhecWarn "could not read org settings (needs admin:org / read:org)"
    }
  }
}

function Invoke-GhecTeardown {
  $o = $Global:GhecOrg
  foreach ($r in @($Global:GhecR06Pub, $Global:GhecR06Priv, $Global:GhecR06Int)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $o -Repo $r
  }
  if (-not (Confirm-GhecPrefix -Name $Global:GhecTeam06 -Chid $Global:GhecChid)) { return }
  Remove-GhecTeam -Org $o -Team $Global:GhecTeam06
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  $o = $Global:GhecOrg
  foreach ($r in @($Global:GhecR06Pub, $Global:GhecR06Priv, $Global:GhecR06Int)) {
    if (Test-GhecRepoExists -Org $o -Repo $r) { Write-GhecOk "repo $o/$r present — visibility=$(_Ch06-RepoVisibility -Repo $r)" } else { Write-GhecInfo "repo $o/$r absent" }
  }
  if (Test-GhecTeamExists -Org $o -Team $Global:GhecTeam06) { Write-GhecOk "team $($Global:GhecTeam06) present" } else { Write-GhecInfo "team $($Global:GhecTeam06) absent" }
}
