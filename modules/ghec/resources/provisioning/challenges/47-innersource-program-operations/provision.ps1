# challenges/47-innersource-program-operations/provision.ps1
#
# Seeds an InnerSource hub repository with discoverability files, labels, and
# program-operation issues. Setup does not mutate access or branch protection.

$Global:GhecCh47HubRepo = "ghec-$($Global:GhecChid)-innersource-hub"

function _Ch47-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh47HubRepo)" }

function _Ch47-Readme {
@'
# InnerSource Hub

This sample hub is the operating surface for the ghec-ch47 InnerSource program activity.

Use it to record:

- program charter and owner
- participating repositories
- contribution-ready work
- maintainer response expectations
- adoption metrics and review cadence
'@
}

function _Ch47-Contributing {
@'
# Contributing

Thank you for contributing through the InnerSource program.

1. Pick an issue labeled `innersource: good-first-contribution` or `innersource: mentored`.
2. Comment with your intent and wait for maintainer confirmation when the issue requests it.
3. Open a pull request with tests or documentation evidence.
4. Maintainers target an initial response within the program SLA recorded in the charter.

Do not bypass repository branch protection, CODEOWNERS review, or data classification requirements.
'@
}

function _Ch47-Codeowners {
@'
# Replace this sample owner with the approved maintainer team during the activity.
* @octocat
'@
}

function _Ch47-Support {
@'
# Support Path

Record the approved support route here:

- program owner:
- maintainer escalation:
- response SLA:
- office hours or channel:
- next review date:
'@
}

function _Ch47-SeedFiles {
  Write-GhecStep 'seeding InnerSource hub files'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo -Path 'README.md' -Message 'Add InnerSource hub README' -Content (_Ch47-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo -Path 'CONTRIBUTING.md' -Message 'Add InnerSource contribution guide' -Content (_Ch47-Contributing)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo -Path '.github/CODEOWNERS' -Message 'Add sample CODEOWNERS' -Content (_Ch47-Codeowners)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo -Path 'SUPPORT.md' -Message 'Add InnerSource support path' -Content (_Ch47-Support)
}

function _Ch47-SeedLabels {
  Write-GhecStep 'seeding InnerSource labels'
  $existing = gh label list --repo (_Ch47-RepoFull) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'innersource: good-first-contribution|0e8a16|Ready for a first-time internal contributor',
    'innersource: mentored|1d76db|Maintainer has agreed to mentor this work',
    'innersource: maintainer-needed|fbca04|Needs maintainer routing or ownership',
    'innersource: blocked|d73a4a|Blocked by access, design, or ownership decision',
    'innersource: metrics|5319e7|Program metric or operating review item'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch47-RepoFull) --color $color --description $desc
    }
    $existing += $name
  }
}

function _Ch47-SeedIssues {
  Write-GhecStep 'seeding InnerSource program issues'
  $existing = gh issue list --repo (_Ch47-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  $issues = @(
    @{ Title = 'Draft InnerSource program charter'; Label = 'innersource: maintainer-needed'; Body = 'Define scope, owner, metrics, participating repositories, cadence, and exception process.' },
    @{ Title = 'Prepare first contribution-ready issue'; Label = 'innersource: good-first-contribution'; Body = 'Write acceptance criteria, owner, test guidance, and review route for a small pilot contribution.' },
    @{ Title = 'Set maintainer response SLA and office hours'; Label = 'innersource: mentored'; Body = 'Record response SLA, support channel, and maintainer rotation.' },
    @{ Title = 'Create adoption metrics baseline'; Label = 'innersource: metrics'; Body = 'Record ready issues, pilot repositories, response times, and merged cross-team pull requests.' }
  )
  foreach ($issue in $issues) {
    if ($existing -contains $issue.Title) { Write-GhecOk "issue '$($issue.Title)' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh issue create '$($issue.Title)'" -Action {
      gh issue create --repo (_Ch47-RepoFull) --title $issue.Title --label $issue.Label --body $issue.Body
    }
  }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo))) {
    Stop-Ghec "repo $(_Ch47-RepoFull) missing after create — aborting seed"
  }
  _Ch47-SeedFiles
  _Ch47-SeedLabels
  _Ch47-SeedIssues
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - replace sample CODEOWNERS with approved maintainer owners'
  Write-GhecInfo '  - complete the program charter and contribution-ready backlog'
  Write-GhecInfo '  - record metrics, owner, exception path, and next review'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh47HubRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh47HubRepo) {
    $issues = gh issue list --repo (_Ch47-RepoFull) --state all --limit 100 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch47-RepoFull) --limit 100 --json name --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch47-RepoFull) present — $issues issues, $labels labels"
  } else {
    Write-GhecInfo "repo $(_Ch47-RepoFull) not provisioned"
  }
}
