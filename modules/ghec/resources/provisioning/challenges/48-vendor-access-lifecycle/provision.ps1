# challenges/48-vendor-access-lifecycle/provision.ps1
#
# Seeds a vendor access register. Setup never invites or removes collaborators
# and never changes organization-wide collaborator settings.

$Global:GhecCh48RegisterRepo = "ghec-$($Global:GhecChid)-vendor-access-register"

function _Ch48-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh48RegisterRepo)" }

function _Ch48-Readme {
@'
# Vendor Access Register

Use this repository to track approved vendor and outside-collaborator access lifecycle evidence.

Required fields for each access record:

- vendor or partner name
- business sponsor
- repository scope
- requested permission
- start and end dates
- reviewer and review cadence
- offboarding trigger and evidence

Setup does not invite users, remove users, or change organization settings.
'@
}

function _Ch48-AccessForm {
@'
name: Vendor access request
description: Request scoped, time-bound outside collaborator access.
title: "Vendor access request: <vendor>"
labels:
  - "vendor-access: requested"
body:
  - type: input
    id: vendor
    attributes:
      label: Vendor or partner
    validations:
      required: true
  - type: input
    id: business_sponsor
    attributes:
      label: Business sponsor
    validations:
      required: true
  - type: textarea
    id: repository_scope
    attributes:
      label: Repository scope
      description: List repositories and why access is needed.
    validations:
      required: true
  - type: dropdown
    id: permission
    attributes:
      label: Requested permission
      options:
        - read
        - triage
        - write
    validations:
      required: true
  - type: input
    id: end_date
    attributes:
      label: Access end date
      placeholder: YYYY-MM-DD
    validations:
      required: true
  - type: textarea
    id: offboarding
    attributes:
      label: Offboarding trigger and evidence plan
    validations:
      required: true
'@
}

function _Ch48-ReviewForm {
@'
name: Vendor access review
description: Review active vendor access or record offboarding evidence.
title: "Vendor access review: <vendor or cohort>"
labels:
  - "vendor-access: review-due"
body:
  - type: textarea
    id: active_access
    attributes:
      label: Active access reviewed
    validations:
      required: true
  - type: textarea
    id: decision
    attributes:
      label: Review decision
      description: Continue, reduce, remove, or exception with owner/date.
    validations:
      required: true
  - type: textarea
    id: audit_evidence
    attributes:
      label: Audit evidence
      description: Link audit-log query, invitation, permission change, or removal evidence.
    validations:
      required: true
'@
}

function _Ch48-SeedFiles {
  Write-GhecStep 'seeding vendor access register files'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo -Path 'README.md' -Message 'Add vendor access register README' -Content (_Ch48-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo -Path '.github/ISSUE_TEMPLATE/vendor-access-request.yml' -Message 'Add vendor access request form' -Content (_Ch48-AccessForm)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo -Path '.github/ISSUE_TEMPLATE/vendor-access-review.yml' -Message 'Add vendor access review form' -Content (_Ch48-ReviewForm)
}

function _Ch48-SeedLabels {
  Write-GhecStep 'seeding vendor access labels'
  $existing = gh label list --repo (_Ch48-RepoFull) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'vendor-access: requested|fbca04|Access request awaiting review',
    'vendor-access: approved|0e8a16|Approved for explicit participant grant',
    'vendor-access: active|1d76db|Access is active and tracked',
    'vendor-access: review-due|d93f0b|Periodic access review is due',
    'vendor-access: offboarded|5319e7|Access removed or verified absent',
    'vendor-access: exception|d73a4a|Exception or risk acceptance required'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch48-RepoFull) --color $color --description $desc
    }
    $existing += $name
  }
}

function _Ch48-SeedIssue {
  Write-GhecStep 'seeding sample vendor access request'
  $title = 'Vendor access request: sample-docs-vendor'
  $existing = gh issue list --repo (_Ch48-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk 'sample vendor request exists (skip)'; return }
  $body = @'
### Vendor or partner
sample-docs-vendor

### Business sponsor
platform-governance

### Repository scope
ghec-ch48-vendor-access-register for sample documentation review only.

### Requested permission
read

### Access end date
YYYY-MM-DD

### Offboarding trigger and evidence plan
Remove repository collaborator access at end date and link audit-log evidence.

This is a sample request. Do not invite any user unless explicitly approved during the activity.
'@
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action {
    gh issue create --repo (_Ch48-RepoFull) --title $title --label 'vendor-access: requested' --body $body
  }
}

function _Ch48-PrintAccessSnapshots {
  Write-GhecStep "outside-collaborator snapshot for '$($Global:GhecOrg)'"
  if ($Global:GhecDryRun) { Write-GhecPlan "would read: gh api /orgs/$($Global:GhecOrg)/outside_collaborators and /orgs/$($Global:GhecOrg)/invitations"; return }
  gh api "/orgs/$($Global:GhecOrg)/outside_collaborators" --paginate --jq '[.[] | {login, type}]' 2>$null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read outside collaborators' }
  Write-GhecStep "pending organization invitation snapshot for '$($Global:GhecOrg)'"
  gh api "/orgs/$($Global:GhecOrg)/invitations" --paginate --jq '[.[] | {login: .login, role: .role}]' 2>$null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read pending invitations' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo))) {
    Stop-Ghec "repo $(_Ch48-RepoFull) missing after create — aborting seed"
  }
  _Ch48-SeedFiles
  _Ch48-SeedLabels
  _Ch48-SeedIssue
  _Ch48-PrintAccessSnapshots
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - inventory outside collaborators and pending invitations'
  Write-GhecInfo '  - complete the access register and approval path'
  Write-GhecInfo '  - grant or remove access only as explicit approved participant steps'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh48RegisterRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo
  Write-GhecWarn 'teardown only deletes the register repo; it never changes collaborator access'
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh48RegisterRepo) {
    $issues = gh issue list --repo (_Ch48-RepoFull) --state all --limit 100 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch48-RepoFull) --limit 100 --json name --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch48-RepoFull) present — $issues issues, $labels labels"
  } else {
    Write-GhecInfo "repo $(_Ch48-RepoFull) not provisioned"
  }
}
