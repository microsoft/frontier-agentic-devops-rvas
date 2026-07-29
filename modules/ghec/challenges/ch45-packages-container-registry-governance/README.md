# Ch45 — Packages and Container Registry Governance

> Govern GitHub Packages and GHCR container images with approved naming, visibility, access, retention, provenance, and cleanup evidence.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Intermediate |
| Duration | ~3 hrs total, multi-session |
| Minimum input | An org + package and repository admin rights. |
| App | Provisioned container sample repository |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: prevent unmanaged package sprawl and accidental container exposure.
- Customer-tenant target: one package namespace with approved access, visibility, metadata, and retention decisions.
- Approval and safety boundary: package visibility changes, deletes, restores, and team access changes are explicit participant steps.
- Records to keep: package owner, source repository, visibility, access grants, retention rule, provenance evidence, and cleanup decision.
- Adoption owner / handover: platform engineering or supply-chain owner accepts package governance.
- Next action and owner: apply the standard to the next package family.

## Prerequisites

- GitHub organization package admin and repository admin rights.
- `gh >= 2.x`, `git`, `jq`.
- Docker or Podman for publishing the validation image.
- Do not pass package tokens or container registry credentials to setup scripts.

## Scenario

A customer publishes containers to GHCR, but visibility, ownership, and retention are inconsistent. You will define a package governance standard, publish a sample image under an approved namespace, connect package access to the intended repository/team, and record retention or cleanup evidence.

> [!IMPORTANT]
> Use an approved customer package if one exists. If not, use the sample `ghec-ch45-*` namespace and avoid changing production package visibility or deleting production packages.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch45 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch45 -Org <org>
```

Setup creates `ghec-ch45-container-governance` with a `Containerfile`, workflow scaffold, and governance checklist. It does not push packages or change package visibility/access.

## Tasks

### Part A — Define the package standard

1. Record the approved naming pattern, owner, source repository, visibility, access model, retention period, and deletion/restore approver.
2. Decide which metadata is required: README, description, OCI labels, source link, license, and provenance.
3. Decide whether packages inherit repository permissions or use package-specific grants.

### Part B — Publish a sample container

4. Build the sample image locally or through the seeded workflow.
5. Authenticate to GHCR using an approved token path and publish `ghcr.io/<org>/ghec-ch45-container-governance:<tag>`.
6. Capture package URL, digest, tags, and source repository link.

### Part C — Govern access and visibility

7. Set package visibility explicitly and document why it is private, internal, or public.
8. Connect package access to the intended repository or team.
9. Verify a non-authorized user or repository cannot pull or publish if that is part of the standard.

### Part D — Retention and cleanup

10. Identify stale tags or unapproved packages in the sample namespace.
11. Delete only approved sample packages or record why they must remain.
12. Document restore path, retention owner, and next review date.

## Validation / Definition of Done

- [ ] Package governance standard covers visibility, access, naming, retention, provenance, and deletion/restore.
- [ ] Sample GHCR package is published by the participant under `ghec-ch45-*` or an approved customer namespace.
- [ ] Package access and source repository are configured intentionally.
- [ ] Metadata and tags meet the approved standard.
- [ ] Cleanup or retention evidence is recorded.
- [ ] Adoption handover names the package owner and next package family.

## Operational extensions

- Add image signing or artifact attestations.
- Add a scheduled report for untagged or stale package versions.
- Combine with required reusable workflows from Ch41 for standard image publishing.

## Reference links

- Working with the Container registry — https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Package access control and visibility — https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility
- Deleting and restoring a package — https://docs.github.com/en/packages/learn-github-packages/deleting-and-restoring-a-package
- Publishing Docker images — https://docs.github.com/en/actions/publishing-packages/publishing-docker-images
