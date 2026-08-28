# challenges/ch16-rest-graphql-automation/provision.ps1
#
# PowerShell twin of ch16 — large messy automation target.

$Global:GhecProjectTitle = "ghec-$($Global:GhecChid)-board"

function _Ch16-RepoFull { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch16-SeedScaffold {
  Write-GhecStep 'seeding src/ + docs/ scaffold'
  $readme = @"
# ghec-ch16 — REST & GraphQL Automation Target

A deliberately large, messy backlog to automate against. Use the REST and
GraphQL APIs to triage, label, and organise the issues in this repo.

- ``src/`` — placeholder service code
- ``docs/`` — placeholder docs
- ~60 seeded issues (mixed open/closed, mostly unlabeled)
- empty board: ``$($Global:GhecProjectTitle)``
"@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'README.md' -Message 'Add automation target overview' -Content $readme

  $app = @'
// ghec-ch16 placeholder service — the code is not the point; the backlog is.
module.exports = function app () {
  return { status: 'ok' }
}
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'src/app.js' -Message 'Add placeholder service entrypoint' -Content $app

  $docs = @'
# API (placeholder)

Document the endpoints here as part of the automation exercise.
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'docs/API.md' -Message 'Add placeholder API docs' -Content $docs
}

function _Ch16-SeedLabels {
  Write-GhecStep 'seeding starter labels (intentionally incomplete)'
  $existing = gh label list --repo (_Ch16-RepoFull) --limit 200 --json name --jq '.[].name' 2>$null
  $labels = @(
    'bug|d73a4a|Something is broken',
    'enhancement|a2eeef|New feature or request',
    'triage|fbca04|Needs triage',
    'area:backend|0e8a16|Backend work',
    'area:docs|0052cc|Documentation work'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch16-RepoFull) --color $color --description $desc
    }
  }
  Write-GhecInfo "GAP by design: no priority scale, no 'good first issue' — automation fills these."
}

function _Ch16-SeedIssues {
  Write-GhecStep 'seeding ~60 issues (mixed open/closed, mostly unlabeled)'
  $existing = gh issue list --repo (_Ch16-RepoFull) --state all --limit 500 --json title --jq '.[].title' 2>$null
  $topics = @('login flow','search endpoint','rate limiting','pagination','webhook retries',
              'CSV export','audit logging','cache invalidation','error messages','timezone handling')
  $body = 'Seeded by ghec-ch16 — messy backlog at scale. Triage, label, and organise via REST/GraphQL.'
  for ($i = 1; $i -le 60; $i++) {
    $n = '{0:000}' -f $i
    $topic = $topics[($i - 1) % $topics.Count]
    $title = "Backlog ${n}: review $topic"

    $label = switch ($i % 4) { 0 { 'bug' } 2 { 'enhancement' } default { '' } }
    $state = if ($i % 3 -eq 0) { 'closed' } else { 'open' }

    if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; continue }

    $args = @('issue', 'create', '--repo', (_Ch16-RepoFull), '--title', $title, '--body', $body)
    if ($label) { $args += @('--label', $label) }
    $url = Invoke-GhecMutation -Plan "gh issue create '$title'" -Action { gh @args }
    if ($state -eq 'closed' -and $url) {
      Invoke-GhecMutation -Plan "gh issue close '$title'" -Action { gh issue close $url }
    }
  }
}

function _Ch16-ProjectNumber {
  $json = gh project list --owner $Global:GhecOrg --format json --limit 100 2>$null
  if (-not $json) { return $null }
  return ($json | ConvertFrom-Json).projects |
    Where-Object { $_.title -eq $Global:GhecProjectTitle } |
    Select-Object -First 1 -ExpandProperty number
}

function _Ch16-SeedProject {
  Write-GhecStep "seeding empty Project (v2): $($Global:GhecProjectTitle)"
  $num = _Ch16-ProjectNumber
  if ($num) { Write-GhecOk "project '$($Global:GhecProjectTitle)' exists (#$num, skip)"; return }
  Invoke-GhecMutation -Plan "gh project create $($Global:GhecProjectTitle)" -Action {
    gh project create --owner $Global:GhecOrg --title $Global:GhecProjectTitle
  }
}

# ===========================================================================
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility public
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) {
    Stop-Ghec "repo $(_Ch16-RepoFull) missing after create — aborting seed"
  }
  _Ch16-SeedScaffold
  _Ch16-SeedLabels
  _Ch16-SeedIssues
  _Ch16-SeedProject
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - script bulk triage/labeling over the backlog with REST + GraphQL'
  Write-GhecInfo "  - add issues to the '$($Global:GhecProjectTitle)' board programmatically"
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo

  $num = _Ch16-ProjectNumber
  if ($num) {
    if (-not (Confirm-GhecPrefix -Name $Global:GhecProjectTitle -Chid $Global:GhecChid)) { return }
    Invoke-GhecMutation -Plan "gh project delete $num" -Action { gh project delete $num --owner $Global:GhecOrg }
  } else {
    Write-GhecOk "project '$($Global:GhecProjectTitle)' absent (skip)"
  }
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $issues = gh issue list --repo (_Ch16-RepoFull) --state all --limit 500 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch16-RepoFull) --limit 200 --json name --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch16-RepoFull) present — $issues issues, $labels labels"
  } else {
    Write-GhecInfo "repo $(_Ch16-RepoFull) not provisioned"
  }
}
