# challenges/49-release-governance/provision.ps1

function _Ch49-RepoFull { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch49-SeedScaffold {
  Write-GhecStep 'seeding release governance scaffold'
  $readme = @'
# ghec-ch49 — Release Governance Target

Use this repository to practice release governance without changing production
organization settings. The sample contains release notes, a readiness issue
form, and a manual evidence workflow.
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'README.md' -Message 'Add release governance target overview' -Content $readme
  $changelog = @'
# Changelog

## v0.1.0 — Candidate

- Seeded release governance sample.
- Replace this section with customer-approved release notes before publishing.
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'CHANGELOG.md' -Message 'Add sample changelog' -Content $changelog
  $policy = @'
# Release governance policy

- Release owner:
- Approver group:
- Tag naming pattern:
- Required release note sections:
- Validation evidence required:
- Rollback owner:
- Exception path:
- Review cadence:
- High-impact controls requiring explicit approval:
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'docs/release-governance.md' -Message 'Add release governance policy template' -Content $policy
  $form = @'
name: Release readiness
description: Capture approval and evidence for a release candidate
title: "Release candidate: <tag>"
labels: ["release: candidate"]
body:
  - type: input
    id: tag
    attributes:
      label: Release tag
      placeholder: v0.1.0
    validations:
      required: true
  - type: textarea
    id: scope
    attributes:
      label: Scope and change summary
    validations:
      required: true
  - type: textarea
    id: validation
    attributes:
      label: Validation evidence
      description: Link workflow runs, test reports, or approval records.
    validations:
      required: true
  - type: input
    id: approver
    attributes:
      label: Approver
    validations:
      required: true
  - type: textarea
    id: rollback
    attributes:
      label: Rollback plan and owner
    validations:
      required: true
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.github/ISSUE_TEMPLATE/release-readiness.yml' -Message 'Add release readiness issue form' -Content $form
  $workflow = @'
name: Release evidence

on:
  workflow_dispatch:
    inputs:
      release_tag:
        description: Release tag under review
        required: true
      evidence_url:
        description: Evidence URL or record identifier
        required: true

permissions:
  contents: read

jobs:
  record:
    runs-on: ubuntu-latest
    steps:
      - name: Print evidence summary
        run: |
          echo "Release tag: ${{ inputs.release_tag }}"
          echo "Evidence: ${{ inputs.evidence_url }}"
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.github/workflows/release-evidence.yml' -Message 'Add release evidence workflow scaffold' -Content $workflow
}

function _Ch49-SeedLabels {
  Write-GhecStep 'seeding release labels'
  $existing = gh label list --repo (_Ch49-RepoFull) --limit 200 --json name --jq '.[].name' 2>$null
  $labels = @(
    'release: candidate|1d76db|Release candidate awaiting evidence and approval',
    'release: approved|0e8a16|Release approved for publication',
    'release: blocked|b60205|Release blocked pending remediation',
    'release: rollback-ready|fbca04|Rollback plan and owner confirmed'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch49-RepoFull) --color $color --description $desc }
    $existing += $name
  }
}

function _Ch49-SeedIssue {
  Write-GhecStep 'seeding sample release candidate issue'
  $title = 'Release candidate: v0.1.0'
  $existing = gh issue list --repo (_Ch49-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action {
    gh issue create --repo (_Ch49-RepoFull) --title $title --label 'release: candidate' --body 'Seeded by ghec-ch49. Replace this with customer release scope, validation evidence, approver, and rollback owner.'
  }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) { Stop-Ghec "repo $(_Ch49-RepoFull) missing after create — aborting seed" }
  _Ch49-SeedScaffold
  _Ch49-SeedLabels
  _Ch49-SeedIssue
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - gh release list --repo $(_Ch49-RepoFull) --limit 20"
  Write-GhecInfo "  - gh api repos/$(_Ch49-RepoFull)/rulesets --jq '.[]? | {name,target,enforcement}'"
  Write-GhecInfo "  - gh api repos/$(_Ch49-RepoFull)/environments --jq '.environments[]? | {name,protection_rules}'"
  Write-GhecInfo '  - inspect release, ruleset, and environment settings before changing anything'
  Write-GhecInfo '  - complete docs/release-governance.md with owners and approval boundaries'
  Write-GhecInfo '  - use the release candidate issue to capture approval evidence'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $issues = gh issue list --repo (_Ch49-RepoFull) --state all --limit 200 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch49-RepoFull) --limit 200 --json name --jq 'length' 2>$null
    $releases = gh release list --repo (_Ch49-RepoFull) --limit 100 --json tagName --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch49-RepoFull) present — $issues issues, $labels labels, $releases releases"
  } else { Write-GhecInfo "repo $(_Ch49-RepoFull) not provisioned" }
}
