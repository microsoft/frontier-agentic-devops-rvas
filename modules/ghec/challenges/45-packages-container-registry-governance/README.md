# Ch45: Packages and container registry governance

**Session outcome:** A scoped identity publishes a container to GHCR. Pull tests confirm that only an authorized consumer can retrieve it by digest.

## Prerequisites

- GitHub organization package admin and repository admin rights.
- `gh >= 2.x`, `git`, `jq`.
- An approved source repository with a working `Containerfile`, and a separate consumer repository.
- Do not pass package tokens or container registry credentials to setup scripts.

## Scenario

A customer publishes containers to GHCR, but visibility, ownership, and retention vary. Define a package standard and publish a sample image under an approved namespace. Connect package access to the intended repository or team, then record retention or cleanup evidence.

> [!IMPORTANT]
> Use an approved customer package if one exists. If not, use the sample `ghec-ch45-*` namespace and avoid changing production package visibility or deleting production packages.

## Install the workflows

Copy the [publisher](../../resources/packages/publish.yml) to the source repository's `.github/workflows/publish.yml` and the [consumer](../../resources/packages/consume.yml) to the other repository's `.github/workflows/consume.yml`. Review existing files before replacing them. Merge both through independent review to their protected default branches.

The publisher builds `Containerfile` from the checkout root. Use the application's tested container definition and approved base image; adjust that path if needed. Protect this file and the publisher with CODEOWNERS. Dispatching these workflows on another branch skips their jobs and does not prove publication or access.

## Tasks

### Part A: Define the package standard

1. Record the approved naming pattern, owner, source repository, visibility, access model, retention period, and deletion/restore approver.
2. Require a source-repository link and image digest. **This session tests distribution and access, not provenance.** OCI labels and a digest are not attestations. If provenance is required, get separate approval to generate an attestation and verify it cryptographically.
3. Decide whether packages inherit repository permissions or use package-specific grants.

### Part B: Publish a sample container

4. Dispatch `publish.yml` from the source repository's default branch through **Actions → Publish private test image → Run workflow**.
5. Inspect its actual build and push. It uses `GITHUB_TOKEN`, gives `packages: write` only to the publish job, and authenticates through `--password-stdin`. The image name is the lower-case source repository name, with a unique run/attempt tag and a source-repository label.
6. Copy the complete `ghcr.io/owner/image@sha256:...` reference from the successful run summary. Open the package settings and confirm its source link and visibility. A new GHCR package is private by default; an existing package may retain its earlier visibility.

### Part C: Govern access and visibility

7. Confirm the package is private for this test. Agree its intended final visibility with the package owner.
8. Connect package access to the intended repository or team.
9. Keep the test package **private**. In its settings, add the consumer repository under **Manage Actions access** with read access. Dispatch `consume.yml` from that repository's default branch, supplying the exact published digest. It first proves an unauthenticated client receives an access denial, then authenticates with its own read-only `GITHUB_TOKEN`, pulls the same image, and checks the returned digest. Both steps must pass; a network error is not access-denial evidence.

After this test, apply another approved visibility only if the customer needs it. Anonymous pulls of a public package are expected to succeed; the private-access test should then fail. Do not widen package access merely to make the consumer green.

### Part D: Retention and cleanup

10. Identify stale tags or unapproved packages in the sample namespace.
11. Delete only approved sample packages or record why they must remain.
12. Document restore path, retention owner, and next review date.

## Reference links

- [Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Package access control and visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
- [Deleting and restoring a package](https://docs.github.com/en/packages/learn-github-packages/deleting-and-restoring-a-package)
- [Publishing Docker images](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
