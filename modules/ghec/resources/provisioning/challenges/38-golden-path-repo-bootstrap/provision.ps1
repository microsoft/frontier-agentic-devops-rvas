# challenges/38-golden-path-repo-bootstrap/provision.ps1

$Global:GhecCh38TemplateRepo = "ghec-$($Global:GhecChid)-golden-path-template"
$Global:GhecCh38CandidateRepo = "ghec-$($Global:GhecChid)-bootstrap-candidate"

function _Ch38-RepoFull { param([string]$Repo) "$($Global:GhecOrg)/$Repo" }
function _Ch38-Readme { @'
# Golden-Path Repository Template

This repository is a governed starter template candidate. Replace sample owners,
controls, and escalation paths with customer-approved values before production use.

## Baseline

- README with owner and purpose
- CODEOWNERS for review ownership
- Issue form for support and exceptions
- Pull request checklist
- Workflow guidance placeholder
'@ }
function _Ch38-Codeowners { @'
# Replace with the approved owning team before production rollout.
* @octo-org/platform-governance
'@ }
function _Ch38-IssueForm { @'
name: Bootstrap exception

description: Request an exception to the golden-path repository baseline.
title: "Bootstrap exception: <repository>"
labels:
  - "bootstrap: exception"
body:
  - type: input
    id: repository
    attributes:
      label: Repository
      placeholder: ghec-ch38-example-service
    validations:
      required: true
  - type: textarea
    id: exception
    attributes:
      label: Exception requested
      description: Describe the baseline control that cannot be met and the compensating control.
    validations:
      required: true
  - type: input
    id: owner
    attributes:
      label: Approving owner
      placeholder: platform-governance
    validations:
      required: true
'@ }
function _Ch38-PrTemplate { @'
## Repository bootstrap checklist

- [ ] Owner and purpose are documented
- [ ] CODEOWNERS has the approved owner
- [ ] Required labels/topics are present
- [ ] Secrets and Actions permissions are reviewed
- [ ] Exceptions are linked
'@ }
function _Ch38-Workflow { @'
name: Bootstrap guidance

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  guidance:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Replace this placeholder with approved bootstrap validation."
'@ }

function _Ch38-SeedLabels {
  Write-GhecStep 'seeding bootstrap labels'
  $existing = gh label list --repo (_Ch38-RepoFull $Global:GhecCh38TemplateRepo) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'bootstrap: exception|d73a4a|Approved or requested bootstrap exception',
    'bootstrap: ready|0e8a16|Repository baseline is ready for validation',
    'governance: review|fbca04|Governance review required'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch38-RepoFull $Global:GhecCh38TemplateRepo) --color $color --description $desc }
    $existing += $name
  }
}
function _Ch38-SeedTemplateFiles {
  Write-GhecStep 'seeding golden-path template files'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo -Path 'README.md' -Message 'Add golden-path template README' -Content (_Ch38-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo -Path '.github/CODEOWNERS' -Message 'Add CODEOWNERS baseline' -Content (_Ch38-Codeowners)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo -Path '.github/ISSUE_TEMPLATE/bootstrap-exception.yml' -Message 'Add bootstrap exception issue form' -Content (_Ch38-IssueForm)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo -Path '.github/pull_request_template.md' -Message 'Add bootstrap pull request template' -Content (_Ch38-PrTemplate)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo -Path '.github/workflows/bootstrap-guidance.yml' -Message 'Add bootstrap workflow guidance' -Content (_Ch38-Workflow)
}
function _Ch38-SeedCandidate {
  Write-GhecStep 'seeding bootstrap candidate README'
  $content = "# $($Global:GhecCh38CandidateRepo)`n`nValidation target for ghec-$($Global:GhecChid). Use this repository to compare against the approved golden path."
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh38CandidateRepo -Path 'README.md' -Message 'Add bootstrap candidate README' -Content $content
}
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh38CandidateRepo -Visibility private
  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh38TemplateRepo) { _Ch38-SeedTemplateFiles }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh38CandidateRepo) { _Ch38-SeedCandidate }
  } else { Write-GhecPlan "would seed baseline files into $($Global:GhecCh38TemplateRepo) and README into $($Global:GhecCh38CandidateRepo)" }
  _Ch38-SeedLabels
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - approve the golden-path baseline and owner'
  Write-GhecInfo "  - mark $($Global:GhecCh38TemplateRepo) as a template only after approval"
  Write-GhecInfo '  - create or reconcile a repository from the template and record validation evidence'
}
function Invoke-GhecTeardown {
  foreach ($r in @($Global:GhecCh38TemplateRepo, $Global:GhecCh38CandidateRepo)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $Global:GhecOrg -Repo $r
  }
}
function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  foreach ($r in @($Global:GhecCh38TemplateRepo, $Global:GhecCh38CandidateRepo)) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $r) {
      $labels = gh label list --repo (_Ch38-RepoFull $r) --limit 100 --json name --jq 'length' 2>$null
      Write-GhecOk "repo $($Global:GhecOrg)/$r present — $labels labels"
    } else { Write-GhecInfo "repo $($Global:GhecOrg)/$r absent" }
  }
}
