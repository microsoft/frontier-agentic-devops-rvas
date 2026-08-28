# challenges/35-org-label-standards/provision.ps1

$Global:GhecCh35ExistingRepo = "ghec-$($Global:GhecChid)-existing-service"
$Global:GhecCh35NewRepo = "ghec-$($Global:GhecChid)-new-service"

function _Ch35-RepoFull {
  param([string]$Repo)
  "$($Global:GhecOrg)/$Repo"
}

function _Ch35-SeedReadme {
  param([string]$Repo, [string]$Purpose)
  $content = @"
# $Repo

$Purpose

Seeded by ghec-$($Global:GhecChid). Use this repository only for the organization label standards activity.
"@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Repo -Path 'README.md' -Message 'Add label governance sample README' -Content $content
}

function _Ch35-SeedInconsistentLabels {
  Write-GhecStep "seeding inconsistent labels in $($Global:GhecCh35ExistingRepo)"
  $existing = gh label list --repo (_Ch35-RepoFull $Global:GhecCh35ExistingRepo) --limit 200 --json name --jq '.[].name' 2>$null
  $labels = @(
    'bug|d73a4a|Something is broken',
    'Bug|b60205|Duplicate casing of bug',
    'urgent|e11d21|Drop everything',
    'sev1|fbca04|High severity, unclear mapping',
    'backend|0e8a16|Backend area',
    'needs review|d876e3|Needs review with non-standard spacing',
    'enhancement|a2eeef|New feature or request'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    if ($existing -icontains $name) { Write-GhecOk "label '$name' exists with different casing (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch35-RepoFull $Global:GhecCh35ExistingRepo) --color $color --description $desc
    }
    $existing += $name
  }
}

function _Ch35-SeedIssues {
  Write-GhecStep 'seeding issues that need label reconciliation'
  $existing = gh issue list --repo (_Ch35-RepoFull $Global:GhecCh35ExistingRepo) --state all --limit 100 --json title --jq '.[].title' 2>$null
  $issues = @(
    'Checkout API intermittently returns 500::bug,urgent,backend',
    'Docs typo in onboarding guide::enhancement,needs review',
    'Login outage for pilot users::Bug,sev1',
    'Add platform health endpoint::enhancement,backend'
  )
  foreach ($entry in $issues) {
    $title, $labels = $entry -split '::', 2
    if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; continue }
    $args = @('issue', 'create', '--repo', (_Ch35-RepoFull $Global:GhecCh35ExistingRepo), '--title', $title, '--body', 'Seeded by ghec-ch35. Reconcile this issue from local labels to the approved organization taxonomy.')
    foreach ($l in ($labels -split ',')) { if ($l) { $args += @('--label', $l) } }
    Invoke-GhecMutation -Plan "gh issue create '$title'" -Action { gh @args }
  }
}

function _Ch35-PrintOrgLabels {
  Write-GhecStep "organization default-label snapshot for '$($Global:GhecOrg)'"
  if ($Global:GhecDryRun) { Write-GhecPlan "would read: gh api /orgs/$($Global:GhecOrg)/labels"; return }
  gh api "/orgs/$($Global:GhecOrg)/labels" --paginate --jq '.[] | {name, color, description}' 2>$null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read organization default labels (needs org owner/admin scope)' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh35ExistingRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh35NewRepo -Visibility private

  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh35ExistingRepo) { _Ch35-SeedReadme $Global:GhecCh35ExistingRepo 'Brownfield service with inconsistent repository-local labels.' }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh35NewRepo) { _Ch35-SeedReadme $Global:GhecCh35NewRepo 'Clean validation target for organization default-label inheritance.' }
  } else {
    Write-GhecPlan "would seed README files into $($Global:GhecCh35ExistingRepo) and $($Global:GhecCh35NewRepo)"
  }

  _Ch35-SeedInconsistentLabels
  _Ch35-SeedIssues
  _Ch35-PrintOrgLabels

  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - approve an organization label taxonomy'
  Write-GhecInfo '  - configure organization default labels'
  Write-GhecInfo "  - verify a new repo inherits them and reconcile $($Global:GhecCh35ExistingRepo)"
}

function Invoke-GhecTeardown {
  foreach ($r in @($Global:GhecCh35ExistingRepo, $Global:GhecCh35NewRepo)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $Global:GhecOrg -Repo $r
  }
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  foreach ($r in @($Global:GhecCh35ExistingRepo, $Global:GhecCh35NewRepo)) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $r) {
      $labels = gh label list --repo (_Ch35-RepoFull $r) --limit 200 --json name --jq 'length' 2>$null
      $issues = gh issue list --repo (_Ch35-RepoFull $r) --state all --limit 200 --json number --jq 'length' 2>$null
      Write-GhecOk "repo $($Global:GhecOrg)/$r present — $labels labels, $issues issues"
    } else {
      Write-GhecInfo "repo $($Global:GhecOrg)/$r absent"
    }
  }
}
