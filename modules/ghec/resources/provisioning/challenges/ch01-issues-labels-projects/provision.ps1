# challenges/ch01-issues-labels-projects/provision.ps1
#
# REFERENCE per-challenge provisioner (PowerShell twin). Dot-sourced by
# scripts/setup.ps1, which sets these globals:
#   WthOrg WthChid WthSlug WthApp WthJuiceShopRef WthDryRun
#   WthAssumeYes WthNamespace WthRepo WthMeta
# and provides lib helpers: Write-Wth*, Invoke-WthMutation, *-WthRepo,
# Confirm-WthPrefix, Get-WthMeta*.
#
# CONTRACT — every challenge's provision.ps1 MUST define exactly:
#   Invoke-WthProvision | Invoke-WthTeardown | Invoke-WthStatus

$Global:WthProjectTitle = "wth-$($Global:WthChid)-board"

function _Ch01-RepoFull { "$($Global:WthOrg)/$($Global:WthRepo)" }

function _Ch01-SeedLabels {
  Write-WthStep 'seeding label taxonomy (intentionally incomplete)'
  $existing = gh label list --repo (_Ch01-RepoFull) --limit 200 --json name --jq '.[].name' 2>$null
  # name|hex|description (dup casing + dup colour are deliberate mess)
  $labels = @(
    'bug|d73a4a|Something is broken',
    'Bug|b60205|duplicate casing of bug — intentional mess',
    'enhancement|a2eeef|New feature or request',
    'urgent|e11d21|Drop everything',
    'wontfix|ffffff|This will not be worked on',
    'question|d876e3|Needs clarification',
    'backend|0e8a16|Server-side work',
    'frontend|0e8a16|duplicate colour of backend — intentional mess'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -icontains $name) { Write-WthOk "label '$name' exists (skip)"; continue }
    Invoke-WthMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch01-RepoFull) --color $color --description $desc
    }
    $existing += $name
  }
  Write-WthInfo "GAP by design: no priority scale, no 'triage', no 'good first issue', dup 'bug/Bug'."
}

function _Ch01-SeedMilestones {
  Write-WthStep 'seeding milestones'
  $existing = gh api "repos/$(_Ch01-RepoFull)/milestones?state=all" --jq '.[].title' 2>$null
  foreach ($t in @('Sprint 1', 'Sprint 2', 'Backlog Grooming')) {
    if ($existing -contains $t) { Write-WthOk "milestone '$t' exists (skip)"; continue }
    Invoke-WthMutation -Plan "gh api milestones POST '$t'" -Action {
      gh api -X POST "repos/$(_Ch01-RepoFull)/milestones" -f title="$t" -f state=open -f description='Seeded by wth-ch01 — re-assign issues as part of triage.'
    }
  }
}

function _Ch01-SeedIssues {
  Write-WthStep 'seeding messy issue backlog'
  $existing = gh issue list --repo (_Ch01-RepoFull) --state all --limit 300 --json title --jq '.[].title' 2>$null
  # 'title::labels' (comma-separated; empty = intentionally unlabeled)
  $issues = @(
    'Login button does nothing on Safari::bug',
    'app slow sometimes::',
    'Crash when uploading an avatar over 5MB::bug',
    'Add dark mode::enhancement',
    'URGENT: checkout page returns 500::urgent',
    'typo on about page::',
    'Make the logo bigger::enhancement',
    'Users report being logged out randomly::',
    'password reset email never arrives::bug',
    'Support German language::enhancement',
    'search returns no results for valid queries::bug',
    'improve performance of dashboard::',
    'Broken link in footer::',
    'Add export to CSV::enhancement',
    'API rate limit errors under load::',
    'Mobile layout overlaps on iPhone SE::bug',
    'Question: how do I rotate API keys?::question',
    'We should refactor the auth module::',
    'Cookie banner not GDPR compliant::urgent',
    'Add two-factor authentication::enhancement',
    'Flaky test in CI::',
    'Update dependencies::',
    'Profile picture not saving::bug',
    'wontfix: legacy IE11 support::wontfix',
    'Onboarding flow confusing for new users::',
    'Add webhook support::enhancement'
  )
  $body = 'Seeded by wth-ch01. This backlog is intentionally messy — triage, label, milestone, and add it to the board.'
  foreach ($entry in $issues) {
    $title, $labels = $entry -split '::', 2
    if ($existing -contains $title) { Write-WthOk "issue '$title' exists (skip)"; continue }
    $args = @('issue', 'create', '--repo', (_Ch01-RepoFull), '--title', $title, '--body', $body)
    if ($labels) { foreach ($l in ($labels -split ',')) { if ($l) { $args += @('--label', $l) } } }
    Invoke-WthMutation -Plan "gh issue create '$title'" -Action { gh @args }
  }
}

function _Ch01-ProjectNumber {
  $json = gh project list --owner $Global:WthOrg --format json --limit 100 2>$null
  if (-not $json) { return $null }
  return ($json | ConvertFrom-Json).projects |
    Where-Object { $_.title -eq $Global:WthProjectTitle } |
    Select-Object -First 1 -ExpandProperty number
}

function _Ch01-SeedProject {
  Write-WthStep "seeding empty Project (v2): $($Global:WthProjectTitle)"
  $num = _Ch01-ProjectNumber
  if ($num) { Write-WthOk "project '$($Global:WthProjectTitle)' exists (#$num, skip)"; return }
  Invoke-WthMutation -Plan "gh project create $($Global:WthProjectTitle)" -Action {
    gh project create --owner $Global:WthOrg --title $Global:WthProjectTitle
  }
}

# ===========================================================================
# CONTRACT FUNCTIONS
# ===========================================================================

function Invoke-WthProvision {
  New-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo -Visibility public
  if ((-not $Global:WthDryRun) -and (-not (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo))) {
    Stop-Wth "repo $(_Ch01-RepoFull) missing after create — aborting seed"
  }
  _Ch01-SeedLabels
  _Ch01-SeedMilestones
  _Ch01-SeedIssues
  _Ch01-SeedProject
  Write-Host ''
  Write-WthInfo 'Next steps for the participant:'
  Write-WthInfo '  - clean up the label taxonomy (priorities, triage, dedupe bug/Bug)'
  Write-WthInfo '  - triage & label the backlog, assign milestones'
  Write-WthInfo "  - add issues to the '$($Global:WthProjectTitle)' board and build views"
}

function Invoke-WthTeardown {
  if (-not (Confirm-WthPrefix -Name $Global:WthRepo -Chid $Global:WthChid)) { return }
  Remove-WthRepo -Org $Global:WthOrg -Repo $Global:WthRepo

  $num = _Ch01-ProjectNumber
  if ($num) {
    if (-not (Confirm-WthPrefix -Name $Global:WthProjectTitle -Chid $Global:WthChid)) { return }
    Invoke-WthMutation -Plan "gh project delete $num" -Action {
      gh project delete $num --owner $Global:WthOrg
    }
  } else {
    Write-WthOk "project '$($Global:WthProjectTitle)' absent (skip)"
  }
}

function Invoke-WthStatus {
  Write-WthStep "status — $($Global:WthChid) in '$($Global:WthOrg)'"
  if (Test-WthRepoExists -Org $Global:WthOrg -Repo $Global:WthRepo) {
    $issues = gh issue list --repo (_Ch01-RepoFull) --state all --limit 500 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch01-RepoFull) --limit 200 --json name --jq 'length' 2>$null
    Write-WthOk "repo $(_Ch01-RepoFull) present — $issues issues, $labels labels"
  } else {
    Write-WthInfo "repo $(_Ch01-RepoFull) not provisioned"
  }
  $num = _Ch01-ProjectNumber
  if ($num) { Write-WthOk "project '$($Global:WthProjectTitle)' present (#$num)" }
  else { Write-WthInfo "project '$($Global:WthProjectTitle)' not provisioned" }
}
