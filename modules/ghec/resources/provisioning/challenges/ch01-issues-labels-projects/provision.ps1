# challenges/ch01-issues-labels-projects/provision.ps1
#
# REFERENCE per-challenge provisioner (PowerShell twin). Dot-sourced by
# scripts/setup.ps1, which sets these globals:
#   GhecOrg GhecChid GhecSlug GhecApp GhecJuiceShopRef GhecDryRun
#   GhecAssumeYes GhecNamespace GhecRepo GhecMeta
# and provides lib helpers: Write-Ghec*, Invoke-GhecMutation, *-GhecRepo,
# Confirm-GhecPrefix, Get-GhecMeta*.
#
# CONTRACT — every challenge's provision.ps1 MUST define exactly:
#   Invoke-GhecProvision | Invoke-GhecTeardown | Invoke-GhecStatus

$Global:GhecProjectTitle = "ghec-$($Global:GhecChid)-board"

function _Ch01-RepoFull { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch01-SeedLabels {
  Write-GhecStep 'seeding label taxonomy (intentionally incomplete)'
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
    if ($existing -contains $name) {
      if ($Global:GhecForce) {
        Invoke-GhecMutation -Plan "gh label edit $name" -Action {
          gh label edit $name --repo (_Ch01-RepoFull) --color $color --description $desc
        }
      } else {
        Write-GhecOk "label '$name' exists (skip)"
      }
      continue
    }
    if ($existing -icontains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch01-RepoFull) --color $color --description $desc
    }
    $existing += $name
  }
  Write-GhecInfo "GAP by design: no priority scale, no 'triage', no 'good first issue', dup 'bug/Bug'."
}

function _Ch01-SeedMilestones {
  Write-GhecStep 'seeding milestones'
  $existing = gh api "repos/$(_Ch01-RepoFull)/milestones?state=all" --jq '.[].title' 2>$null
  foreach ($t in @('Sprint 1', 'Sprint 2', 'Backlog Grooming')) {
    if ($existing -contains $t) { Write-GhecOk "milestone '$t' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh api milestones POST '$t'" -Action {
      gh api -X POST "repos/$(_Ch01-RepoFull)/milestones" -f title="$t" -f state=open -f description='Seeded by ghec-ch01 — re-assign issues as part of triage.'
    }
  }
}

function _Ch01-SeedIssues {
  Write-GhecStep 'seeding messy issue backlog'
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
  $body = 'Seeded by ghec-ch01. This backlog is intentionally messy — triage, label, milestone, and add it to the board.'
  foreach ($entry in $issues) {
    $title, $labels = $entry -split '::', 2
    if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; continue }
    $args = @('issue', 'create', '--repo', (_Ch01-RepoFull), '--title', $title, '--body', $body)
    if ($labels) { foreach ($l in ($labels -split ',')) { if ($l) { $args += @('--label', $l) } } }
    Invoke-GhecMutation -Plan "gh issue create '$title'" -Action { gh @args }
  }
}

function _Ch01-ProjectNumber {
  $json = gh project list --owner $Global:GhecOrg --format json --limit 100 2>$null
  if (-not $json) { return $null }
  return ($json | ConvertFrom-Json).projects |
    Where-Object { $_.title -eq $Global:GhecProjectTitle } |
    Select-Object -First 1 -ExpandProperty number
}

function _Ch01-SeedProject {
  Write-GhecStep "seeding empty Project (v2): $($Global:GhecProjectTitle)"
  $num = _Ch01-ProjectNumber
  if ($num) { Write-GhecOk "project '$($Global:GhecProjectTitle)' exists (#$num, skip)"; return }
  Invoke-GhecMutation -Plan "gh project create $($Global:GhecProjectTitle)" -Action {
    gh project create --owner $Global:GhecOrg --title $Global:GhecProjectTitle
  }
}

# ===========================================================================
# CONTRACT FUNCTIONS
# ===========================================================================

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility public
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch01-RepoFull) missing after create — aborting seed"
  }
  _Ch01-SeedLabels
  _Ch01-SeedMilestones
  _Ch01-SeedIssues
  _Ch01-SeedProject
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - clean up the label taxonomy (priorities, triage, dedupe bug/Bug)'
  Write-GhecInfo '  - triage & label the backlog, assign milestones'
  Write-GhecInfo "  - add issues to the '$($Global:GhecProjectTitle)' board and build views"
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo

  $num = _Ch01-ProjectNumber
  if ($num) {
    if (-not (Confirm-GhecPrefix -Name $Global:GhecProjectTitle -Chid $Global:GhecChid)) { return }
    Invoke-GhecMutation -Plan "gh project delete $num" -Action {
      gh project delete $num --owner $Global:GhecOrg
    }
  } else {
    Write-GhecOk "project '$($Global:GhecProjectTitle)' absent (skip)"
  }
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $issues = gh issue list --repo (_Ch01-RepoFull) --state all --limit 500 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch01-RepoFull) --limit 200 --json name --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch01-RepoFull) present — $issues issues, $labels labels"
  } else {
    Write-GhecInfo "repo $(_Ch01-RepoFull) not provisioned"
  }
  $num = _Ch01-ProjectNumber
  if ($num) { Write-GhecOk "project '$($Global:GhecProjectTitle)' present (#$num)" }
  else { Write-GhecInfo "project '$($Global:GhecProjectTitle)' not provisioned" }
}
