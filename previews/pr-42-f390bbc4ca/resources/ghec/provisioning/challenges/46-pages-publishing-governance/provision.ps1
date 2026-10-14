# challenges/46-pages-publishing-governance/provision.ps1
#
# Seeds a Pages candidate repo with static content and a governance issue.
# Organization Pages publication settings are participant-controlled governance
# changes, not setup mutations.

$Global:GhecCh46PagesRepo = "ghec-$($Global:GhecChid)-pages-site"

function _Ch46-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh46PagesRepo)" }

function _Ch46-Readme {
@'
# Pages Publishing Governance Sample

This repository is a safe sample for the ghec-ch46 Pages publishing governance activity.

Use `docs/` as the candidate Pages source after the organization publishing policy is approved.
Setup does not enable Pages or mutate organization-wide Pages settings.
'@
}

function _Ch46-Index {
@'
# Governed Pages Site

This sample page exists so participants can configure a repository-level GitHub Pages source after approval.

Evidence to capture:

- organization Pages publication policy decision
- repository Pages source or workflow run
- published URL and visibility
- rollback owner and next review
'@
}

function _Ch46-SeedFiles {
  Write-GhecStep 'seeding Pages candidate content'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh46PagesRepo -Path 'README.md' -Message 'Add Pages governance sample README' -Content (_Ch46-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh46PagesRepo -Path 'docs/index.md' -Message 'Add Pages sample content' -Content (_Ch46-Index)
}

function _Ch46-SeedLabels {
  Write-GhecStep 'seeding Pages governance labels'
  $existing = gh label list --repo (_Ch46-RepoFull) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'pages-governance: decision-needed|fbca04|Org Pages policy decision is needed',
    'pages-governance: approved|0e8a16|Publishing decision approved',
    'pages-governance: exception|d93f0b|Approved exception or risk acceptance',
    'pages-governance: rollback-ready|0052cc|Rollback owner and path recorded'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch46-RepoFull) --color $color --description $desc
    }
    $existing += $name
  }
}

function _Ch46-SeedIssue {
  Write-GhecStep 'seeding Pages governance decision issue'
  $title = 'Pages publication governance decision'
  $existing = gh issue list --repo (_Ch46-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk 'governance decision issue exists (skip)'; return }
  $body = @'
Record the approved Pages publishing decision before enabling the site.

Required evidence:
- organization Pages policy snapshot
- approved publisher scope and visibility
- repository source or workflow choice
- site owner and content owner
- rollback owner and review cadence

Setup intentionally did not enable Pages or change org-wide Pages settings.
'@
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action {
    gh issue create --repo (_Ch46-RepoFull) --title $title --label 'pages-governance: decision-needed' --body $body
  }
}

function _Ch46-PrintPagesPolicy {
  Write-GhecStep "organization Pages policy snapshot for '$($Global:GhecOrg)'"
  if ($Global:GhecDryRun) { Write-GhecPlan "would read: gh api /orgs/$($Global:GhecOrg) Pages settings"; return }
  gh api "/orgs/$($Global:GhecOrg)" --jq '{members_can_create_pages, members_can_create_public_pages, members_can_create_private_pages}' 2>$null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read org Pages settings; capture them from Organization settings > Pages' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh46PagesRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh46PagesRepo))) {
    Stop-Ghec "repo $(_Ch46-RepoFull) missing after create — aborting seed"
  }
  _Ch46-SeedFiles
  _Ch46-SeedLabels
  _Ch46-SeedIssue
  _Ch46-PrintPagesPolicy
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - approve the organization Pages publishing policy'
  Write-GhecInfo "  - configure repository-level Pages for $($Global:GhecCh46PagesRepo) only after approval"
  Write-GhecInfo '  - capture site URL, source/workflow evidence, rollback owner, and next review'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh46PagesRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh46PagesRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh46PagesRepo) {
    $issues = gh issue list --repo (_Ch46-RepoFull) --state all --limit 100 --json number --jq 'length' 2>$null
    $pagesState = gh api "repos/$(_Ch46-RepoFull)/pages" --jq '.status // .html_url // "configured"' 2>$null
    if (-not $pagesState) { $pagesState = 'not configured' }
    Write-GhecOk "repo $(_Ch46-RepoFull) present — $issues issues, Pages: $pagesState"
  } else {
    Write-GhecInfo "repo $(_Ch46-RepoFull) not provisioned"
  }
}
