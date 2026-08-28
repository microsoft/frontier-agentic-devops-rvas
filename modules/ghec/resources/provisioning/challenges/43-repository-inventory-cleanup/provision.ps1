# challenges/43-repository-inventory-cleanup/provision.ps1

$Global:GhecCh43OwnedRepo = "ghec-$($Global:GhecChid)-owned-service"
$Global:GhecCh43OrphanRepo = "ghec-$($Global:GhecChid)-orphan-tool"
$Global:GhecCh43DuplicateRepo = "ghec-$($Global:GhecChid)-duplicate-api"

function _Ch43-RepoFull { param([string]$Repo) "$($Global:GhecOrg)/$Repo" }
function _Ch43-Readme { param([string]$Purpose, [string]$Owner) @"
# Inventory Sample

- Purpose: $Purpose
- Owner: $Owner
- Cleanup decision: pending participant review
"@ }
function _Ch43-SeedLabels {
  param([string]$Repo)
  Write-GhecStep "seeding inventory labels in $Repo"
  $existing = gh label list --repo (_Ch43-RepoFull $Repo) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'inventory: owner-needed|d73a4a|Repository needs an accountable owner',
    'inventory: duplicate-review|fbca04|Repository may duplicate another purpose',
    'inventory: keep|0e8a16|Repository should remain active',
    'governance: cleanup-decision|5319e7|Cleanup decision required'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists in $Repo (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch43-RepoFull $Repo) --color $color --description $desc }
    $existing += $name
  }
}
function _Ch43-SeedIssue {
  param([string]$Repo, [string]$Title, [string]$Label, [string]$Body)
  Write-GhecStep "seeding inventory review issue in $Repo"
  $existing = gh issue list --repo (_Ch43-RepoFull $Repo) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $Title) { Write-GhecOk "issue '$Title' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh issue create '$Title'" -Action { gh issue create --repo (_Ch43-RepoFull $Repo) --title $Title --label $Label --body $Body }
}
function _Ch43-SeedTopics {
  param([string]$Repo, [string[]]$Topics)
  Write-GhecStep "seeding topics for $Repo"
  if ($Global:GhecDryRun) { Write-GhecPlan "would set topics on ${Repo}: $($Topics -join ',')"; return }
  $args = @('api', '-X', 'PUT', "repos/$($Global:GhecOrg)/$Repo/topics", '-H', 'Accept: application/vnd.github+json')
  foreach ($topic in $Topics) { $args += @('-f', "names[]=$topic") }
  gh @args *> $null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn "could not set topics for $Repo" }
}
function _Ch43-SeedRepo {
  param([string]$Repo, [string]$Purpose, [string]$Owner, [string]$Title, [string]$Label, [string]$Body, [string[]]$Topics)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Repo -Path 'README.md' -Message 'Add inventory sample README' -Content (_Ch43-Readme $Purpose $Owner)
  _Ch43-SeedLabels $Repo
  _Ch43-SeedIssue $Repo $Title $Label $Body
  _Ch43-SeedTopics $Repo $Topics
}
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh43OwnedRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh43OrphanRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh43DuplicateRepo -Visibility private
  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh43OwnedRepo) { _Ch43-SeedRepo $Global:GhecCh43OwnedRepo 'Healthy owned service' 'payments-team' 'Inventory decision: keep' 'inventory: keep' 'Owner and purpose are known. Confirm review cadence.' @('inventory-sample','owner-known') }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh43OrphanRepo) { _Ch43-SeedRepo $Global:GhecCh43OrphanRepo 'Unclear legacy tool' 'owner-needed' 'Inventory decision: owner needed' 'inventory: owner-needed' 'Find owner or queue lifecycle decision with approval.' @('inventory-sample','owner-needed') }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh43DuplicateRepo) { _Ch43-SeedRepo $Global:GhecCh43DuplicateRepo 'Possible duplicate API' 'platform-governance' 'Inventory decision: duplicate review' 'inventory: duplicate-review' 'Compare purpose with existing APIs before merge/archive decisions.' @('inventory-sample','duplicate-review') }
  } else { Write-GhecPlan 'would seed README, labels, topics, and inventory review issues into ch43 sample repos' }
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - export repository inventory and classify cleanup decisions'
  Write-GhecInfo '  - apply safe metadata updates; archive/transfer/delete only with explicit approval'
}
function Invoke-GhecTeardown {
  foreach ($r in @($Global:GhecCh43OwnedRepo, $Global:GhecCh43OrphanRepo, $Global:GhecCh43DuplicateRepo)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $Global:GhecOrg -Repo $r
  }
}
function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  foreach ($r in @($Global:GhecCh43OwnedRepo, $Global:GhecCh43OrphanRepo, $Global:GhecCh43DuplicateRepo)) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $r) {
      $issues = gh issue list --repo (_Ch43-RepoFull $r) --state all --limit 100 --json number --jq 'length' 2>$null
      $labels = gh label list --repo (_Ch43-RepoFull $r) --limit 100 --json name --jq 'length' 2>$null
      Write-GhecOk "repo $($Global:GhecOrg)/$r present — $issues issues, $labels labels"
    } else { Write-GhecInfo "repo $($Global:GhecOrg)/$r absent" }
  }
}
