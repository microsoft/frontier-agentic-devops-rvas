# challenges/42-repository-lifecycle-governance/provision.ps1

$Global:GhecCh42ActiveRepo = "ghec-$($Global:GhecChid)-active-service"
$Global:GhecCh42DeprecatedRepo = "ghec-$($Global:GhecChid)-deprecated-service"
$Global:GhecCh42ArchiveRepo = "ghec-$($Global:GhecChid)-archive-candidate"

function _Ch42-RepoFull { param([string]$Repo) "$($Global:GhecOrg)/$Repo" }
function _Ch42-Readme { param([string]$State, [string]$Owner) @"
# $State

Lifecycle sample for ghec-$($Global:GhecChid).

- Lifecycle state: $State
- Proposed owner: $Owner
- Review required before archive, transfer, or delete actions.
"@ }
function _Ch42-SeedLabels {
  param([string]$Repo)
  Write-GhecStep "seeding lifecycle labels in $Repo"
  $existing = gh label list --repo (_Ch42-RepoFull $Repo) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'lifecycle: active|0e8a16|Repository is active',
    'lifecycle: deprecated|fbca04|Repository is deprecated or replaced',
    'lifecycle: archive-candidate|d73a4a|Repository needs archive approval',
    'governance: decision-needed|5319e7|Owner decision required'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists in $Repo (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch42-RepoFull $Repo) --color $color --description $desc }
    $existing += $name
  }
}
function _Ch42-SeedIssue {
  param([string]$Repo, [string]$State, [string]$Body, [string]$Label)
  Write-GhecStep "seeding lifecycle review issue in $Repo"
  $title = "Lifecycle review: $State"
  $existing = gh issue list --repo (_Ch42-RepoFull $Repo) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action { gh issue create --repo (_Ch42-RepoFull $Repo) --title $title --label $Label --body $Body }
}
function _Ch42-SeedRepo {
  param([string]$Repo, [string]$State, [string]$Owner, [string]$Label, [string]$Body)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Repo -Path 'README.md' -Message 'Add lifecycle sample README' -Content (_Ch42-Readme $State $Owner)
  _Ch42-SeedLabels $Repo
  _Ch42-SeedIssue $Repo $State $Body $Label
}
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh42ActiveRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh42DeprecatedRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh42ArchiveRepo -Visibility private
  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh42ActiveRepo) { _Ch42-SeedRepo $Global:GhecCh42ActiveRepo 'active' 'payments-team' 'lifecycle: active' 'Keep active. Confirm owner, purpose, and next review date.' }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh42DeprecatedRepo) { _Ch42-SeedRepo $Global:GhecCh42DeprecatedRepo 'deprecated' 'platform-governance' 'lifecycle: deprecated' 'Replacement exists. Confirm retention needs and deprecation notice.' }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh42ArchiveRepo) { _Ch42-SeedRepo $Global:GhecCh42ArchiveRepo 'archive candidate' 'owner-needed' 'lifecycle: archive-candidate' 'Archive only after explicit approval and retention review.' }
  } else { Write-GhecPlan 'would seed README, labels, and lifecycle review issues into ch42 sample repos' }
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - define lifecycle states, criteria, and approvers'
  Write-GhecInfo '  - apply safe markers first; archive/transfer/delete only with explicit approval'
}
function Invoke-GhecTeardown {
  foreach ($r in @($Global:GhecCh42ActiveRepo, $Global:GhecCh42DeprecatedRepo, $Global:GhecCh42ArchiveRepo)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $Global:GhecOrg -Repo $r
  }
}
function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  foreach ($r in @($Global:GhecCh42ActiveRepo, $Global:GhecCh42DeprecatedRepo, $Global:GhecCh42ArchiveRepo)) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $r) {
      $issues = gh issue list --repo (_Ch42-RepoFull $r) --state all --limit 100 --json number --jq 'length' 2>$null
      $labels = gh label list --repo (_Ch42-RepoFull $r) --limit 100 --json name --jq 'length' 2>$null
      Write-GhecOk "repo $($Global:GhecOrg)/$r present — $issues issues, $labels labels"
    } else { Write-GhecInfo "repo $($Global:GhecOrg)/$r absent" }
  }
}
