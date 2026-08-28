# challenges/51-lfs-monorepo-governance/provision.ps1

function _Ch51-RepoFull { "$($Global:GhecOrg)/$($Global:GhecRepo)" }

function _Ch51-SeedScaffold {
  Write-GhecStep 'seeding LFS and monorepo governance scaffold'
  $readme = @'
# ghec-ch51 — LFS and Monorepo Governance Target

Use this repository to practice monorepo ownership boundaries and Git LFS
governance. The sample uses small placeholder files only; setup does not commit
large binaries, rewrite history, or change storage quotas.
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'README.md' -Message 'Add monorepo governance target overview' -Content $readme
  $attrs = @'
# Approved LFS patterns. Review before production rollout.
*.psd filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.gitattributes' -Message 'Add LFS tracking policy sample' -Content $attrs
  $owners = @'
# Replace sample owners with customer teams before enforcement.
/packages/web/ @octo-org/web-owners
/packages/api/ @octo-org/api-owners
/packages/shared/ @octo-org/platform-owners
/docs/ @octo-org/docs-owners
.gitattributes @octo-org/platform-owners
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.github/CODEOWNERS' -Message 'Add monorepo CODEOWNERS sample' -Content $owners
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'packages/web/README.md' -Message 'Add web package placeholder' -Content "# Web package`n`nOwner and review boundary for the web package.`n"
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'packages/api/README.md' -Message 'Add api package placeholder' -Content "# API package`n`nOwner and review boundary for the API package.`n"
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'packages/shared/README.md' -Message 'Add shared package placeholder' -Content "# Shared package`n`nOwner and review boundary for shared code.`n"
  $policy = @'
# LFS and monorepo governance

- Monorepo governance owner:
- Storage/quota owner:
- Package owner map:
- Approved LFS patterns:
- Prohibited direct-binary patterns:
- Large-file exception path:
- Exception expiry rules:
- History rewrite or migration approver:
- Review cadence:
- High-impact decisions requiring explicit approval:
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path 'docs/lfs-monorepo-governance.md' -Message 'Add LFS monorepo governance template' -Content $policy
  $form = @'
name: Large-file intake
description: Request approval for a large file pattern or LFS tracking change
title: "Large-file intake: <pattern>"
labels: ["lfs: review"]
body:
  - type: input
    id: pattern
    attributes:
      label: File pattern
      placeholder: "*.onnx"
    validations:
      required: true
  - type: input
    id: size
    attributes:
      label: Expected size and growth
    validations:
      required: true
  - type: textarea
    id: usage
    attributes:
      label: Usage, retention need, and consumers
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
    validations:
      required: true
  - type: input
    id: owner
    attributes:
      label: Owning team
    validations:
      required: true
'@
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecRepo -Path '.github/ISSUE_TEMPLATE/large-file-intake.yml' -Message 'Add large-file intake issue form' -Content $form
}

function _Ch51-SeedLabels {
  Write-GhecStep 'seeding LFS and monorepo labels'
  $existing = gh label list --repo (_Ch51-RepoFull) --limit 200 --json name --jq '.[].name' 2>$null
  $labels = @(
    'monorepo: ownership|1d76db|Ownership boundary or CODEOWNERS work',
    'lfs: review|fbca04|Large-file or LFS pattern requires review',
    'lfs: approved|0e8a16|Large-file or LFS pattern approved',
    'lfs: blocked|b60205|Large-file or LFS pattern blocked'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action { gh label create $name --repo (_Ch51-RepoFull) --color $color --description $desc }
    $existing += $name
  }
}

function _Ch51-SeedIssue {
  Write-GhecStep 'seeding sample large-file intake issue'
  $title = 'Large-file intake: sample-model-artifact'
  $existing = gh issue list --repo (_Ch51-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk "issue '$title' exists (skip)"; return }
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action {
    gh issue create --repo (_Ch51-RepoFull) --title $title --label 'lfs: review' --body 'Seeded by ghec-ch51. Replace with file pattern, expected size, update frequency, owner, alternatives, quota impact, and approval decision.'
  }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo))) { Stop-Ghec "repo $(_Ch51-RepoFull) missing after create — aborting seed" }
  _Ch51-SeedScaffold
  _Ch51-SeedLabels
  _Ch51-SeedIssue
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - gh repo view $(_Ch51-RepoFull) --json name,visibility,diskUsage,defaultBranchRef"
  Write-GhecInfo '  - git lfs track   # from a local clone, if git-lfs is installed'
  Write-GhecInfo '  - inspect repository size, LFS tracking, and ownership boundaries'
  Write-GhecInfo '  - replace sample CODEOWNERS entries with customer teams before enforcement'
  Write-GhecInfo '  - record LFS quota, migration, and history rewrite decisions explicitly'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecRepo
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecRepo) {
    $issues = gh issue list --repo (_Ch51-RepoFull) --state all --limit 200 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch51-RepoFull) --limit 200 --json name --jq 'length' 2>$null
    $size = gh repo view (_Ch51-RepoFull) --json diskUsage --jq '.diskUsage' 2>$null
    Write-GhecOk "repo $(_Ch51-RepoFull) present — $issues issues, $labels labels, diskUsage=${size}KB"
  } else { Write-GhecInfo "repo $(_Ch51-RepoFull) not provisioned" }
}
