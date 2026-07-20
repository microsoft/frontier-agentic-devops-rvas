# Ch24 — Migrate Bitbucket to GitHub (Server & Cloud)

> Deliver an approved Bitbucket Server/Data Center migration with `gh bbs2gh`, or validate the explicitly limited source-history path for Bitbucket Cloud.

| | |
|---|---|
| Track | Migration |
| Difficulty | Advanced |
| Duration | ~4 hrs |
| Minimum input | A GitHub org with org-owner rights and a classic GitHub PAT |
| App | none |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: execute an approved Bitbucket migration path with explicit fidelity and cutover ownership.
- Customer-tenant target: a selected customer Bitbucket repository, GitHub destination, migration staging/queue, and metadata-gap plan.
- Approval and safety boundary: run customer migrations only in an approved change window with source-write controls and owner approval; a source-history fallback is a controlled proof that must end in a cutover decision, not the delivery destination.
- Records to keep: retain inventory, script/queue output, migration logs, validation results, fidelity decision, and follow-up backlog.
- Adoption owner / handover: the customer migration owner accepts cutover; repository and platform owners accept retained gaps and operating changes.
- Next action and owner: authorise the selected migration path and cutover window or hand over the approved proposal and risk decision.

## Customer delivery objective

Migrate one Bitbucket Server/Data Center repository to GitHub Enterprise Cloud with Git source, history, and pull request metadata, then validate the explicitly limited Bitbucket Cloud fallback that preserves only Git source and history.

## Prerequisites

Activities: _(none — this activity is self-contained)_

Access and tooling you need:
- GitHub organization where you are an org owner.
- Classic GitHub PAT available as `GH_PAT`.
- GitHub CLI `gh >= 2.4.0`.
- PowerShell, because `gh bbs2gh generate-script` emits `.ps1` scripts.
- For Path A: Bitbucket Server/Data Center 5.14+, a Bitbucket account with admin or super-admin rights, SSH/SFTP access for Linux servers or SMB access for Windows servers, and one staging store: AWS S3, Azure Blob, or GitHub-owned blob storage.
- For Path B: a bitbucket.org repository and the `git` CLI.

## Scenario

Your migration team has two Bitbucket populations. The production estate runs Bitbucket Server/Data Center and needs pull request history in GitHub. A smaller team uses Bitbucket Cloud, which has no first-party metadata migration path, so you must still preserve Git source and history and clearly communicate what will be lost.

> [!IMPORTANT]
> Use an approved customer target (do this first)
> Default to an approved customer Bitbucket Server/Data Center or Bitbucket Cloud repository. Complete the work on that source and target, retaining the migrated repository, history, supported metadata, settings evidence, and gap record.
>
> - Have a candidate? Use it everywhere this guide references the Bitbucket project, repository, workspace, or target repository.
> - No suitable source and target? Do not start a migration against an unapproved example; record the access constraint, accountable owner, and next action.
>
> Record the selected target, customer migration owner, approval boundary, and next action and owner.

## Important fidelity decision

Use the paths exactly as separated below:

- Path A — Bitbucket Server/Data Center via `gh bbs2gh`: primary path for Git source, history, and pull request metadata.
- Path B — Bitbucket Cloud via Git CLI: fallback path for source and history only. Bitbucket Cloud is not supported by GitHub Enterprise Importer or `gh bbs2gh`; pull requests, comments, issues, and pipelines cannot be auto-migrated by first-party tools.

## Path A — Bitbucket Server/Data Center via `gh bbs2gh`

### 1. Install the extension and authenticate

```bash
gh extension install github/gh-bbs2gh
gh extension list | grep bbs2gh
export GH_PAT="ghp_your_classic_token"
export BBS_USERNAME="bitbucket-admin"
export BBS_PASSWORD="bitbucket-admin-password"
```

For Windows Bitbucket Server/Data Center using SMB, also set:

```powershell
$env:SMB_PASSWORD = "smb-share-password"
```

Your GitHub PAT must be a classic PAT. Fine-grained PATs are not supported for GEI migrations.

### 2. Confirm Server/Data Center prerequisites

Before running a migration, verify these operational requirements:

- Bitbucket Server/Data Center is version 5.14 or later.
- The Bitbucket account has admin or super-admin permissions.
- Linux Bitbucket instances expose the migration archive through SFTP.
- Windows Bitbucket instances expose the migration archive through an SMB share.
- The SSH private key used for SFTP has no passphrase and uses a supported cipher such as `aes256-ctr` or `aes256-cbc`.
- A clustered Bitbucket instance has a stable archive download host; pass it with `--archive-download-host`.
- Blob staging is ready because Bitbucket is usually behind a firewall and GitHub Enterprise Importer must retrieve the archive from an internet-reachable store.

For AWS S3, the IAM principal used by `bbs2gh` needs object and multipart permissions on the bucket, including:

- `s3:PutObject`
- `s3:GetObject`
- `s3:ListBucket`
- `s3:DeleteObject`
- `s3:AbortMultipartUpload`
- `s3:ListMultipartUploadParts`
- `s3:ListBucketMultipartUploads`

Set AWS credentials in the environment:

```bash
export AWS_REGION="eu-west-1"
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="aws-secret-access-key"
```

For Azure Blob Storage, use an access-key connection string, not a SAS connection string:

```bash
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=migrationstore;AccountKey=base64-account-key;EndpointSuffix=core.windows.net"
```

If you do not want to manage cloud storage, use GitHub-owned blob storage with `--use-github-storage`. It requires `gh bbs2gh` v1.9.0 or later and GitHub deletes the uploaded archive after migration or after seven days.

### 3. Understand the `bbs2gh` architecture

`gh bbs2gh` coordinates a multi-hop migration because GitHub cannot directly reach most Bitbucket Server/Data Center instances:

1. `bbs2gh` calls the Bitbucket Server/Data Center export API over HTTPS.
2. Bitbucket writes a migration `.tar` archive under `$BITBUCKET_SHARED_HOME/data/migration/export`.
3. `bbs2gh` downloads that archive from the Bitbucket server through SFTP on Linux or SMB on Windows.
4. `bbs2gh` uploads the archive to AWS S3, Azure Blob Storage, or GitHub-owned blob storage.
5. GitHub Enterprise Importer reads the staged archive and imports it into GitHub Enterprise Cloud.
6. The destination repository is created as private. If you do not pass a target name, the default is `projectKey-repositoryName`, such as `ENG-payments-api`.

### 4. Run a single-repository migration with AWS S3

Set variables once so the command is repeatable and auditable:

```bash
BBS_URL="https://bitbucket.example.com"
BBS_PROJECT="ENG"
BBS_REPO="payments-api"
GITHUB_ORG="contoso-migration-lab"
GITHUB_REPO="payments-api"
SSH_USER="atlbitbucket"
SSH_PRIVATE_KEY="$HOME/.ssh/bbs_migration_id_rsa"
AWS_BUCKET="contoso-gei-bbs-archives"
ARCHIVE_HOST="bitbucket-node-01.example.com"
```

Run the migration:

```bash
gh bbs2gh migrate-repo \
  --bbs-server-url "$BBS_URL" \
  --bbs-project "$BBS_PROJECT" \
  --bbs-repo "$BBS_REPO" \
  --github-org "$GITHUB_ORG" \
  --github-repo "$GITHUB_REPO" \
  --ssh-user "$SSH_USER" \
  --ssh-private-key "$SSH_PRIVATE_KEY" \
  --aws-bucket-name "$AWS_BUCKET" \
  --archive-download-host "$ARCHIVE_HOST"
```

Use `--archive-download-host` for clustered Bitbucket deployments where the Bitbucket base URL is a load balancer but the archive must be downloaded from a specific node.

### 5. Run the same migration with GitHub-owned storage

This avoids managing AWS or Azure staging storage:

```bash
gh bbs2gh migrate-repo \
  --bbs-server-url "$BBS_URL" \
  --bbs-project "$BBS_PROJECT" \
  --bbs-repo "$BBS_REPO" \
  --github-org "$GITHUB_ORG" \
  --github-repo "$GITHUB_REPO" \
  --ssh-user "$SSH_USER" \
  --ssh-private-key "$SSH_PRIVATE_KEY" \
  --archive-download-host "$ARCHIVE_HOST" \
  --use-github-storage
```

### 6. Generate a bulk migration script

Use bulk scripts for migration waves after you validate one representative repository:

```bash
gh bbs2gh generate-script \
  --bbs-server-url "$BBS_URL" \
  --github-org "$GITHUB_ORG" \
  --output migrate-bitbucket-wave.ps1 \
  --download-migration-logs
```

Open the generated PowerShell script, review every repository mapping, then run it from a workstation that has the same environment variables and network access as the single-repository test.

### 7. Validate the two-phase manual archive path

Use this when the server cannot expose SFTP or SMB reliably.

First, trigger archive generation from `bbs2gh` without providing archive download arguments:

```bash
gh bbs2gh migrate-repo \
  --bbs-server-url "$BBS_URL" \
  --bbs-project "$BBS_PROJECT" \
  --bbs-repo "$BBS_REPO" \
  --github-org "$GITHUB_ORG" \
  --github-repo "$GITHUB_REPO"
```

On the Bitbucket server, locate the generated archive in:

```text
$BITBUCKET_SHARED_HOME/data/migration/export
```

Copy the `.tar` archive to your migration workstation by your approved internal transfer method, then import from the local archive:

```bash
ARCHIVE_PATH="$HOME/migration-archives/ENG-payments-api.tar"

gh bbs2gh migrate-repo \
  --bbs-server-url "$BBS_URL" \
  --bbs-project "$BBS_PROJECT" \
  --bbs-repo "$BBS_REPO" \
  --github-org "$GITHUB_ORG" \
  --github-repo "$GITHUB_REPO" \
  --archive-path "$ARCHIVE_PATH" \
  --use-github-storage
```

### 8. Validate what migrated

In GitHub, confirm the repository is private and inspect:

- Git branches and tags.
- Commit history.
- Pull requests.
- Pull request comments.
- Pull request reviews.
- File and line-level review comments.
- Required reviewers.
- Pull request attachments.

Document what did not migrate from Bitbucket Server/Data Center:

- Personal repositories owned by users.
- Branch permissions.
- Commit comments.
- Repository settings.
- Repository permissions.
- CI pipelines.

## Path B — Bitbucket Cloud fallback with Git CLI

### 1. State the limitation before migrating

Bitbucket Cloud repositories on `bitbucket.org` are not supported by GitHub Enterprise Importer or `gh bbs2gh`. There is no first-party path that migrates Bitbucket Cloud pull requests, comments, issues, or pipeline history. The always-doable baseline is a Git mirror migration that preserves source code and Git history only. For GHE.com targets, Git CLI is also the only available source-history path.

### 2. Mirror-clone and mirror-push

```bash
BITBUCKET_WORKSPACE="contoso-workspace"
BITBUCKET_REPO="web-portal"
GITHUB_ORG="contoso-migration-lab"
GITHUB_REPO="web-portal"

git clone --mirror "https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO.git"
cd "$BITBUCKET_REPO.git"
git push --mirror "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
```

Alternative equivalent flow:

```bash
git clone --bare "https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO.git"
cd "$BITBUCKET_REPO.git"
git push --mirror "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
```

### 3. Validate the Cloud migration

```bash
git ls-remote --heads "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
git ls-remote --tags "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
```

Then document what was not migrated:

- Pull requests and review comments.
- Issues.
- Bitbucket Pipelines configuration and run history.
- Repository settings, permissions, and branch restrictions.
- User identities for collaboration events.

## Validation / Definition of Done

You are done when all of the following are true:

- [ ] A Bitbucket Server/Data Center repository with pull request history was migrated using `gh bbs2gh` and its pull requests, reviews, line comments, required reviewers, and attachments are visible in GitHub.
- [ ] AWS S3, Azure Blob, or GitHub-owned blob storage was configured and used for the Server/Data Center archive handoff.
- [ ] You can explain the `bbs2gh` sequence: Bitbucket export API, archive under `$BITBUCKET_SHARED_HOME/data/migration/export`, SFTP/SMB download, blob upload, and GEI import.
- [ ] You generated or reviewed a PowerShell bulk migration script with `gh bbs2gh generate-script`.
- [ ] You validated or documented the manual archive path with `--archive-path`.
- [ ] A Bitbucket Cloud repository was mirror-pushed to GitHub and branch/tag history is present.
- [ ] You documented exactly which Bitbucket Server/Data Center and Bitbucket Cloud data did not migrate.
- [ ] Adoption handover — record the customer migration owner, migration-wave plan, cutover risk, evidence checks, and rollback or retry decision points.

## Cleanup

Remove local mirror clones and locally copied archives after validation:

```bash
cd "$HOME"
rm -rf "$BITBUCKET_REPO.git"
rm -f "$HOME/migration-archives/ENG-payments-api.tar"
```

Delete or lifecycle-expire temporary S3/Azure staging objects if you did not use GitHub-owned storage. Retain destination repositories unless the accountable customer owner approves their removal.

## References

- About GitHub Enterprise Importer — https://docs.github.com/en/migrations/using-github-enterprise-importer/understanding-github-enterprise-importer/about-github-enterprise-importer
- About migrations from Bitbucket Server to GitHub Enterprise Cloud — https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/about-migrations-from-bitbucket-server-to-github-enterprise-cloud
- Overview of a migration from Bitbucket Server to GitHub Enterprise Cloud — https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/overview-of-a-migration-from-bitbucket-server-to-github-enterprise-cloud
- Managing access for a Bitbucket Server migration — https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/managing-access-for-a-migration-from-bitbucket-server-to-github-enterprise-cloud
- Migrating repositories from Bitbucket Server to GitHub Enterprise Cloud — https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/migrating-repositories-from-bitbucket-server-to-github-enterprise-cloud
- `gh-bbs2gh` extension — https://github.com/github/gh-bbs2gh
