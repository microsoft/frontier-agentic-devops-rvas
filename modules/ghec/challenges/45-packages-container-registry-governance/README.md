# Ch45: Packages and container registry governance

**Session outcome:** A scoped identity publishes a container to GHCR. Pull tests confirm that only an authorized consumer can retrieve it by digest.

## Prerequisites

- GitHub organization package admin and repository admin rights.
- `gh >= 2.x`, `git`, `jq`.
- An approved source repository with a working `Containerfile`, and a separate consumer repository.
- Don't pass package tokens or container registry credentials to setup scripts.

## Scenario

A customer publishes containers to GHCR, but visibility, ownership, and retention vary. Publish a sample image under an approved namespace, then test who can pull it by digest.

> [!IMPORTANT]
> Use an approved customer package if one exists. If not, use the sample `ghec-ch45-*` namespace. Don't change production package visibility or delete production packages.

## Install the workflows

Copy the [publisher](../../resources/packages/publish.yml) to the source repository's `.github/workflows/publish.yml` and the [consumer](../../resources/packages/consume.yml) to the other repository's `.github/workflows/consume.yml`. Check for existing files before overwriting them. Merge both to their protected default branches through independent review.

The publisher builds `Containerfile` from the checkout root. Use the application's tested container definition and approved base image, and adjust that path if needed. Protect this file and the publisher with CODEOWNERS. Dispatching these workflows on another branch skips their jobs, so it proves neither publication nor access.

## Tasks

### Part A: Publish a sample container

1. Dispatch `publish.yml` from the source repository's default branch through **Actions → Publish private test image → Run workflow**.
2. The workflow uses `GITHUB_TOKEN`, gives `packages: write` only to the publish job, and authenticates through `--password-stdin`. The image name is the lower-case source repository name, with a unique run/attempt tag and a source-repository label.
3. Copy the complete `ghcr.io/owner/image@sha256:...` reference from the successful run summary. Open the package settings and confirm its source link and visibility. A new GHCR package is private by default; an existing package may keep its earlier visibility.

This session tests distribution and access, not provenance. OCI labels and a digest aren't attestations.

### Part B: Test authorized and unauthorized pulls

1. Keep the test package **private**. In its settings, add the consumer repository under **Manage Actions access** with read access.
2. Dispatch `consume.yml` from that repository's default branch, supplying the exact published digest. The workflow first proves an unauthenticated client gets an access denial. It then authenticates with its own read-only `GITHUB_TOKEN`, pulls the same image, and checks the returned digest. Both steps must pass. A network error isn't proof of access denial.

After this test, apply a different approved visibility only if the customer needs it. Anonymous pulls of a public package should succeed, so the private-access test should then fail. Don't widen package access just to make the consumer check pass.

### Part C: Package standard

Keep this short list with the adoption issue:

- naming pattern: owner, source repository, and visibility;
- access model: inherit repository permissions or use package-specific grants;
- retention: who approves deletion and restore.

Delete only approved sample packages.

## Reference links

- [Working with the Container registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Package access control and visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)
- [Deleting and restoring a package](https://docs.github.com/en/packages/learn-github-packages/deleting-and-restoring-a-package)
- [Publishing Docker images](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
