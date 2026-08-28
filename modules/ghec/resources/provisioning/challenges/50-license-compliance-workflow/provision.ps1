# challenges/50-license-compliance-workflow/provision.ps1

function _Ch50-RepoFull { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch50-SeedScaffold {
  Write-GhecStep 'seeding license compliance scaffold'
  $readme = @'
# ghec-ch50 — License Compliance Workflow Target

Use this repository to practice dependency inventory, dependency review, and
license exception intake. Setup seeds manifests and workflow materials only; it
does not change enterprise or organization license policies.
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'README.md' -Message 'Add license compliance target overview' -Content $readme
  $package = @'
{
  "name": "ghec-ch50-license-compliance-workflow",
  "version": "0.1.0",
  "private": true,
  "license": "MIT",
  "dependencies": {
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.7.0"
  }
}
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'package.json' -Message 'Add sample npm manifest' -Content $package
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'requirements.txt' -Message 'Add sample Python manifest' -Content "requests==2.32.3`nPyYAML==6.0.2`n"
  $policy = @'
# License compliance policy

- Compliance owner:
- Legal/security approver:
- Allowed license families:
- Review-required license families:
- Prohibited license families:
- Exception path:
- Exception expiry rules:
- Remediation owner:
- Review cadence:
- High-impact policies requiring explicit approval:
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'docs/license-compliance-policy.md' -Message 'Add license compliance policy template' -Content $policy
  $dependabot = @'
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.github/dependabot.yml' -Message 'Add Dependabot scaffold' -Content $dependabot
  $form = @'
name: License exception
description: Request a time-bound exception for a dependency license
title: "License exception: <package>"
labels: ["license: review"]
body:
  - type: input
    id: package
    attributes:
      label: Package and version
    validations:
      required: true
  - type: input
    id: license
    attributes:
      label: Detected license
    validations:
      required: true
  - type: textarea
    id: usage
    attributes:
      label: Usage and distribution context
    validations:
      required: true
  - type: input
    id: owner
    attributes:
      label: Business owner
    validations:
      required: true
  - type: input
    id: expiry
    attributes:
      label: Exception expiry date
    validations:
      required: true
  - type: textarea
    id: remediation
    attributes:
      label: Remediation or replacement plan
    validations:
      required: true
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.github/ISSUE_TEMPLATE/license-exception.yml' -Message 'Add license exception issue form' -Content $form
}

function _Ch50-SeedLabels {
  Write-GhecStep 'seeding license labels'
  $existing = gh label list --repo (_Ch50-RepoFull) --limit 200 --json name --jq '.[].name' 2>$null
  $labels = @(
    'license: review|fbca04|Dependency license requires review',
    'license: approved|0e8a16|License use approved',
    'license: exception|1d76db|Time-bound license exception approved',
    'license: blocked|b60205|Dependency license is blocked'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch50-RepoFull) --color $color --description $desc }
    $existing += $name
  }
}

function _Ch50-SeedIssue {
  Write-GhecStep 'seeding sample license exception issue'
  $title = 'License exception: sample-transitive-package'
  $existing = gh issue list --repo (_Ch50-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action {
    gh issue create --repo (_Ch50-RepoFull) --title $title --label 'license: review' --body 'Seeded by ghec-ch50. Replace with package, license, usage, owner, legal/security decision, expiry, and remediation path.'
  }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) { Stop-Ghec "repo $(_Ch50-RepoFull) missing after create — aborting seed" }
  _Ch50-SeedScaffold
  _Ch50-SeedLabels
  _Ch50-SeedIssue
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - gh api repos/$(_Ch50-RepoFull)/dependency-graph/sbom --jq '.sbom.packages[]? | {name,versionInfo,licenseConcluded}'"
  Write-GhecInfo "  - gh api repos/$(_Ch50-RepoFull)/contents/package.json --jq '.download_url'"
  Write-GhecInfo '  - capture dependency inventory from dependency graph, manifests, or SBOM'
  Write-GhecInfo '  - classify allowed, review-required, and prohibited license families'
  Write-GhecInfo '  - record policy enforcement changes as explicit owner-approved steps'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $issues = gh issue list --repo (_Ch50-RepoFull) --state all --limit 200 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch50-RepoFull) --limit 200 --json name --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch50-RepoFull) present — $issues issues, $labels labels"
  } else { Write-GhecInfo "repo $(_Ch50-RepoFull) not provisioned" }
}
