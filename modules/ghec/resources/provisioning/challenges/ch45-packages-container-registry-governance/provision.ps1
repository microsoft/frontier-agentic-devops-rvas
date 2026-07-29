# challenges/ch45-packages-container-registry-governance/provision.ps1

$Global:GhecCh45Repo = "ghec-$($Global:GhecChid)-container-governance"

function _Ch45-RepoFull { "$($Global:GhecOrg)/$($Global:GhecCh45Repo)" }

function _Ch45-Readme {
@'
# Container Registry Governance Sample

Use this repository to publish and govern a sample GHCR package under an approved namespace.

Participant-owned package steps:

1. Build and publish a sample image to `ghcr.io/<org>/ghec-ch45-container-governance:<tag>`.
2. Configure package visibility and repository/team access explicitly.
3. Record digest, tags, metadata, retention, and cleanup decisions.

Setup intentionally pushes no packages and changes no package permissions.
'@
}

function _Ch45-Containerfile {
@'
FROM alpine:3.20
LABEL org.opencontainers.image.title="ghec-ch45-container-governance"
LABEL org.opencontainers.image.description="Sample image for GHCR governance validation"
LABEL org.opencontainers.image.source="https://github.com/OWNER/REPOSITORY"
CMD ["/bin/sh", "-c", "echo ghec-ch45 sample container"]
'@
}

function _Ch45-Workflow {
@'
name: Publish sample container

on:
  workflow_dispatch:
    inputs:
      tag:
        description: Image tag to publish
        required: true
        default: lab

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and publish
        run: |
          IMAGE="ghcr.io/${{ github.repository_owner }}/ghec-ch45-container-governance:${{ inputs.tag }}"
          docker build -f Containerfile -t "$IMAGE" .
          docker push "$IMAGE"
          docker inspect "$IMAGE" --format='{{index .RepoDigests 0}}' || true
'@
}

function _Ch45-Policy {
@'
# Package Governance Register

| Package | Source repo | Visibility | Access model | Owner | Retention | Deletion approver | Evidence |
|---|---|---|---|---|---|---|
| ghcr.io/<org>/ghec-ch45-container-governance | ghec-ch45-container-governance | TBD | TBD | TBD | TBD | TBD | TBD |

## Required metadata

- Description
- Source repository link
- OCI labels
- Approved tags and digest
- Retention or cleanup decision
'@
}

function _Ch45-SeedFiles {
  Write-GhecStep 'seeding container governance sample'
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo -Path 'README.md' -Message 'Add container governance README' -Content (_Ch45-Readme)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo -Path 'Containerfile' -Message 'Add sample Containerfile' -Content (_Ch45-Containerfile)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo -Path '.github/workflows/publish-container.yml' -Message 'Add package publish workflow scaffold' -Content (_Ch45-Workflow)
  Set-GhecFile -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo -Path 'governance/package-register.md' -Message 'Add package governance register' -Content (_Ch45-Policy)
}

function _Ch45-PrintSnapshot {
  Write-GhecStep 'package governance discovery commands'
  Write-GhecInfo 'After publishing, inspect package settings in GitHub UI or via GraphQL/package APIs.'
  if ($Global:GhecDryRun) { Write-GhecPlan "would list workflows for $(_Ch45-RepoFull)"; return }
  gh workflow list --repo (_Ch45-RepoFull)
  if ($LASTEXITCODE -ne 0) { Write-GhecWarn 'could not list workflows' }
}

function Invoke-GhecProvision {
  New-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo -Visibility private
  if ((-not $Global:GhecDryRun) -and (-not (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo))) {
    Stop-Ghec "repo $(_Ch45-RepoFull) missing after create — aborting seed"
  }
  _Ch45-SeedFiles
  _Ch45-PrintSnapshot
  Write-Host ''
  Write-GhecInfo 'Next steps for the participant:'
  Write-GhecInfo "  - publish a sample image under ghcr.io/$($Global:GhecOrg)/$($Global:GhecCh45Repo)"
  Write-GhecInfo '  - configure package visibility/access explicitly'
  Write-GhecInfo '  - record digest, retention, and cleanup evidence'
}

function Invoke-GhecTeardown {
  if (-not (Confirm-GhecPrefix -Name $Global:GhecCh45Repo -Chid $Global:GhecChid)) { return }
  Remove-GhecRepo -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo
  Write-GhecWarn 'teardown does not delete GHCR packages; remove approved sample packages manually'
}

function Invoke-GhecStatus {
  Write-GhecStep "status — $($Global:GhecChid) in '$($Global:GhecOrg)'"
  if (Test-GhecRepoExists -Org $Global:GhecOrg -Repo $Global:GhecCh45Repo) {
    $workflows = @(gh workflow list --repo (_Ch45-RepoFull) 2>$null).Count
    Write-GhecOk "repo $(_Ch45-RepoFull) present — $workflows workflows"
  } else {
    Write-GhecInfo "repo $(_Ch45-RepoFull) not provisioned"
  }
}
