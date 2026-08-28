# challenges/ch44-policy-drift-detection/provision.ps1

$Global:GhecCh44BaselineRepo = "ghec-$($Global:GhecChid)-policy-baseline"
$Global:GhecCh44DriftRepo = "ghec-$($Global:GhecChid)-drifted-service"

function _Ch44-RepoFull { param([string]$Repo) "$($Global:GhecOrg)/$Repo" }
function _Ch44-Readme { @'
# Policy Baseline Sample

This repository represents a sample repository policy contract.

Required baseline:

- README exists
- CODEOWNERS exists
- Pull request template exists
- Issue template exists
- Labels: status: needs-triage, type: bug, priority: p2
- Topics: policy-baseline, owner-known
'@ }
function _Ch44-Codeowners { @'
* @octo-org/platform-governance
'@ }
function _Ch44-IssueForm { @'
name: Policy exception

description: Request a time-bound exception to repository policy.
title: "Policy exception: <control>"
labels:
  - "policy: exception"
body:
  - type: input
    id: control
    attributes:
      label: Control
    validations:
      required: true
  - type: textarea
    id: reason
    attributes:
      label: Reason and compensating control
    validations:
      required: true
'@ }
function _Ch44-PrTemplate { @'
## Policy baseline checklist

- [ ] Owner evidence remains current
- [ ] Required files are present
- [ ] Required labels/topics remain present
- [ ] Drift exceptions are linked and time-bound
'@ }
function _Ch44-DriftReadme { @'
# Drifted Service

This repository intentionally misses parts of the baseline. Use it to test drift detection.
'@ }
function _Ch44-SeedLabels {
  param([string]$Repo, [string]$Mode)
  Write-GhecStep "seeding policy labels in $Repo"
  $existing = gh label list --repo (_Ch44-RepoFull $Repo) --limit 100 --json name --jq '.[].name' 2>$null
  if ($Mode -eq 'drifted') { $labels = @('type: bug|b60205|Defect in existing behavior') }
  else { $labels = @('status: needs-triage|fbca04|Needs initial triage', 'type: bug|b60205|Defect in existing behavior', 'priority: p2|cfd3d7|Normal priority', 'policy: exception|d73a4a|Approved policy exception') }
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists in $Repo (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch44-RepoFull $Repo) --color $color --description $desc }
    $existing += $name
  }
}
function _Ch44-SeedTopics {
  param([string]$Repo, [string[]]$Topics)
  Write-GhecStep "seeding topics for $Repo"
  if ($Global:GhecDryRun) { Write-GhecPlan "would set topics on ${Repo}: $($Topics -join ',')"; return }
  $args = @('api', '-X', 'PUT', "repos/$($Global:GhecOrg)/$Repo/topics", '-H', 'Accept: application/vnd.github+json')
  foreach ($topic in $Topics) { $args += @('-f', "names[]=$topic") }
  gh @args *> $null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn "could not set topics for $Repo" }
}
function _Ch44-SeedBaselineFiles {
  Write-GhecStep 'seeding baseline policy files'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh44BaselineRepo -Path 'README.md' -Message 'Add policy baseline README' -Content (_Ch44-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh44BaselineRepo -Path '.github/CODEOWNERS' -Message 'Add baseline CODEOWNERS' -Content (_Ch44-Codeowners)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh44BaselineRepo -Path '.github/ISSUE_TEMPLATE/policy-exception.yml' -Message 'Add policy exception issue form' -Content (_Ch44-IssueForm)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh44BaselineRepo -Path '.github/pull_request_template.md' -Message 'Add policy pull request template' -Content (_Ch44-PrTemplate)
}
function _Ch44-SeedDriftFiles {
  Write-GhecStep 'seeding intentionally drifted files'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh44DriftRepo -Path 'README.md' -Message 'Add drifted service README' -Content (_Ch44-DriftReadme)
}
function _Ch44-SeedDriftIssue {
  Write-GhecStep 'seeding drift review issue'
  $title = 'Policy drift review: missing baseline controls'
  $existing = gh issue list --repo (_Ch44-RepoFull $Global:GhecCh44DriftRepo) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action { gh issue create --repo (_Ch44-RepoFull $Global:GhecCh44DriftRepo) --title $title --body 'Detect missing CODEOWNERS, PR template, labels, and required topics. Record remediation or exception.' }
}
function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh44BaselineRepo -Visibility private
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh44DriftRepo -Visibility private
  if (-not $Global:GhecDryRun) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh44BaselineRepo) {
      _Ch44-SeedBaselineFiles
      _Ch44-SeedLabels $Global:GhecCh44BaselineRepo baseline
      _Ch44-SeedTopics $Global:GhecCh44BaselineRepo @('policy-baseline','owner-known')
    }
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh44DriftRepo) {
      _Ch44-SeedDriftFiles
      _Ch44-SeedLabels $Global:GhecCh44DriftRepo drifted
      _Ch44-SeedTopics $Global:GhecCh44DriftRepo @('drift-sample','owner-needed')
      _Ch44-SeedDriftIssue
    }
  } else { Write-GhecPlan 'would seed baseline and intentionally drifted repository content' }
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo '  - define the policy baseline and drift severities'
  Write-GhecInfo "  - compare $($Global:GhecCh44DriftRepo) against $($Global:GhecCh44BaselineRepo)"
  Write-GhecInfo '  - remediate safely or record approved exceptions'
}
function Invoke-GhecTeardown {
  foreach ($r in @($Global:GhecCh44BaselineRepo, $Global:GhecCh44DriftRepo)) {
    if (-not (Confirm-GhecPrefix -Name $r -Chid $Global:GhecChid)) { return }
    Remove-GhecRepo -Org $Global:GhecOrg -Repo $r
  }
}
function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  foreach ($r in @($Global:GhecCh44BaselineRepo, $Global:GhecCh44DriftRepo)) {
    if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $r) {
      $issues = gh issue list --repo (_Ch44-RepoFull $r) --state all --limit 100 --json number --jq 'length' 2>$null
      $labels = gh label list --repo (_Ch44-RepoFull $r) --limit 100 --json name --jq 'length' 2>$null
      Write-GhecOk "repo $($Global:GhecOrg)/$r present — $issues issues, $labels labels"
    } else { Write-GhecInfo "repo $($Global:GhecOrg)/$r absent" }
  }
}
