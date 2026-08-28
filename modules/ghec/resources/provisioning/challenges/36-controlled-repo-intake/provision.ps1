# challenges/ch36-controlled-repo-intake/provision.ps1

$Global:GhecCh36IntakeRepo = "ghec-$($Global:GhecChid)-repo-intake"

function _Ch36-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh36IntakeRepo)" }

function _Ch36-Readme {
@'
# Repository Intake

Use this repository to request and approve new repositories through a governed issue-form workflow.

## Flow

1. A requester opens a repository request issue.
2. A maintainer reviews ownership, purpose, visibility, and baseline requirements.
3. A maintainer applies `repo-intake: approved`.
4. The provisioning workflow creates the repository and comments back with evidence.

Configure `REPO_PROVISIONER_TOKEN` before applying the approval label.
'@
}

function _Ch36-IssueForm {
@'
name: Repository request
description: Request a new organization repository through the governed intake path.
title: "Repository request: <repo-name>"
labels:
  - "repo-intake: ready-for-review"
body:
  - type: input
    id: repository_name
    attributes:
      label: Repository name
      description: Use the approved sample prefix in this lab, for example ghec-ch36-payments-api.
      placeholder: ghec-ch36-payments-api
    validations:
      required: true
  - type: input
    id: owning_team
    attributes:
      label: Owning team
      placeholder: platform-engineering
    validations:
      required: true
  - type: textarea
    id: business_purpose
    attributes:
      label: Business purpose
      description: Explain why this repository is needed and what service or product owns it.
    validations:
      required: true
  - type: dropdown
    id: visibility
    attributes:
      label: Visibility
      options:
        - private
        - internal
    validations:
      required: true
  - type: dropdown
    id: data_classification
    attributes:
      label: Data classification
      options:
        - public
        - internal
        - confidential
    validations:
      required: true
  - type: textarea
    id: baseline_requirements
    attributes:
      label: Baseline requirements
      description: List required teams, labels, rulesets, custom properties, or CI defaults.
      value: |
        - README required
        - Organization label taxonomy required
        - Owner recorded in request issue
    validations:
      required: true
'@
}

function _Ch36-Workflow {
@'
name: Provision requested repository

on:
  issues:
    types: [labeled]

permissions:
  contents: read
  issues: write

jobs:
  provision:
    if: github.event.label.name == 'repo-intake: approved'
    runs-on: ubuntu-latest
    steps:
      - name: Provision repository
        uses: actions/github-script@v7
        env:
          PROVISIONER_TOKEN: ${{ secrets.REPO_PROVISIONER_TOKEN }}
          APPROVAL_LABEL: "repo-intake: approved"
          PROVISIONED_LABEL: "repo-intake: provisioned"
          FAILED_LABEL: "repo-intake: failed"
        with:
          github-token: ${{ github.token }}
          script: |
            const token = process.env.PROVISIONER_TOKEN
            const issue = context.payload.issue
            const org = context.repo.owner

            async function fail(message) {
              core.setFailed(message)
              await github.rest.issues.createComment({
                owner: org,
                repo: context.repo.repo,
                issue_number: issue.number,
                body: `Repository provisioning failed: ${message}`
              })
              await github.rest.issues.addLabels({
                owner: org,
                repo: context.repo.repo,
                issue_number: issue.number,
                labels: [process.env.FAILED_LABEL]
              })
            }

            if (!token) {
              await fail('missing REPO_PROVISIONER_TOKEN secret')
              return
            }

            const labels = issue.labels.map(label => label.name)
            if (!labels.includes(process.env.APPROVAL_LABEL)) {
              core.info('Approval label is not present; skipping.')
              return
            }

            const body = issue.body || ''
            const field = (label) => {
              const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
              const match = body.match(new RegExp(`### ${escaped}\\s+([^#]+)`, 'i'))
              return match ? match[1].trim() : ''
            }

            const repoName = field('Repository name')
            const ownerTeam = field('Owning team')
            const purpose = field('Business purpose')
            const visibility = field('Visibility') || 'private'

            if (!/^ghec-ch36-[a-z0-9][a-z0-9-]{2,80}$/.test(repoName)) {
              await fail(`invalid repository name "${repoName}". Use the ghec-ch36- sample prefix for this lab.`)
              return
            }
            if (!['private', 'internal'].includes(visibility)) {
              await fail(`visibility "${visibility}" is not allowed by this workflow`)
              return
            }
            if (!ownerTeam || !purpose) {
              await fail('owning team and business purpose are required')
              return
            }

            const provisioner = github.getOctokit(token)
            try {
              await provisioner.rest.repos.get({ owner: org, repo: repoName })
              await fail(`repository ${org}/${repoName} already exists`)
              return
            } catch (error) {
              if (error.status !== 404) throw error
            }

            const created = await provisioner.rest.repos.createInOrg({
              org,
              name: repoName,
              private: visibility === 'private',
              visibility,
              description: `Requested in ${context.repo.repo}#${issue.number} for ${ownerTeam}`,
              auto_init: true
            })

            for (const label of [
              ['type: chore', 'fef2c0', 'Operational or maintenance work'],
              ['priority: p2', 'cfd3d7', 'Normal priority'],
              ['status: needs-triage', 'fbca04', 'Needs initial triage']
            ]) {
              await provisioner.rest.issues.createLabel({
                owner: org,
                repo: repoName,
                name: label[0],
                color: label[1],
                description: label[2]
              }).catch(error => {
                if (error.status !== 422) throw error
              })
            }

            await github.rest.issues.createComment({
              owner: org,
              repo: context.repo.repo,
              issue_number: issue.number,
              body: `Provisioned ${created.data.html_url}\n\nOwner: ${ownerTeam}\nVisibility: ${visibility}\nWorkflow run: ${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`
            })
            await github.rest.issues.addLabels({
              owner: org,
              repo: context.repo.repo,
              issue_number: issue.number,
              labels: [process.env.PROVISIONED_LABEL]
            })
'@
}

function _Ch36-SeedLabels {
  Write-GhecStep 'seeding intake labels'
  $existing = gh label list --repo (_Ch36-RepoFull) --limit 100 --json name --jq '.[].name' 2>$null
  $labels = @(
    'repo-intake: ready-for-review|fbca04|Request is ready for maintainer review',
    'repo-intake: approved|0e8a16|Maintainer approval to provision',
    'repo-intake: provisioned|1a7f37|Repository was provisioned',
    'repo-intake: failed|d73a4a|Provisioning failed',
    'repo-intake: rejected|57606a|Request was rejected'
  )
  foreach ($entry in $labels) {
    $name, $color, $desc = $entry -split '\|', 3
    if ($existing -contains $name) { Write-GhecOk "label '$name' exists (skip)"; continue }
    Invoke-GhecMutation -Plan "gh label create $name" -Action {
      gh label create $name --repo (_Ch36-RepoFull) --color $color --description $desc
    }
    $existing += $name
  }
}

function _Ch36-SeedFiles {
  Write-GhecStep 'seeding issue form and workflow'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo -Path 'README.md' -Message 'Add repository intake README' -Content (_Ch36-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo -Path '.github/ISSUE_TEMPLATE/repository-request.yml' -Message 'Add repository request issue form' -Content (_Ch36-IssueForm)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo -Path '.github/workflows/provision-repository.yml' -Message 'Add repository provisioning workflow scaffold' -Content (_Ch36-Workflow)
}

function _Ch36-SeedIssue {
  Write-GhecStep 'seeding sample repository request'
  $title = 'Repository request: ghec-ch36-sample-service'
  $existing = gh issue list --repo (_Ch36-RepoFull) --state all --limit 100 --json title --jq '.[].title' 2>$null
  if ($existing -contains $title) { Write-GhecOk 'sample request exists (skip)'; return }
  $body = @'
### Repository name
ghec-ch36-sample-service

### Owning team
platform-engineering

### Business purpose
Sample request used to validate controlled repository intake.

### Visibility
private

### Data classification
internal

### Baseline requirements
- README required
- Organization label taxonomy required
- Owner recorded in request issue
'@
  Invoke-GhecMutation -Plan "gh issue create '$title'" -Action {
    gh issue create --repo (_Ch36-RepoFull) --title $title --label 'repo-intake: ready-for-review' --body $body
  }
}

function _Ch36-PrintPolicy {
  Write-GhecStep "organization repository-creation policy snapshot for '$($Global:GhecOrg)'"
  if ($Global:GhecDryRun) { Write-GhecPlan "would read: gh api /orgs/$($Global:GhecOrg) repository-creation settings"; return }
  gh api "/orgs/$($Global:GhecOrg)" --jq '{members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories}' 2>$null
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not read org repository-creation settings (needs admin:org / read:org)' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo))) {
    Stop-Ghec "repo $(_Ch36-RepoFull) missing after create — aborting seed"
  }
  _Ch36-SeedLabels
  _Ch36-SeedFiles
  _Ch36-SeedIssue
  _Ch36-PrintPolicy
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - configure REPO_PROVISIONER_TOKEN on $($Global:GhecCh36IntakeRepo)"
  Write-GhecInfo '  - inspect or restrict member repository creation'
  Write-GhecInfo "  - apply 'repo-intake: approved' to the sample request when ready"
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh36IntakeRepo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo
  Write-GhecWarn "teardown does not delete repositories provisioned by the workflow unless they use the ghec-$($Global:GhecChid)- prefix and are removed manually"
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh36IntakeRepo) {
    $issues = gh issue list --repo (_Ch36-RepoFull) --state all --limit 200 --json number --jq 'length' 2>$null
    $labels = gh label list --repo (_Ch36-RepoFull) --limit 100 --json name --jq 'length' 2>$null
    Write-GhecOk "repo $(_Ch36-RepoFull) present — $issues issues, $labels labels"
  } else {
    Write-GhecInfo "repo $(_Ch36-RepoFull) not provisioned"
  }
}
