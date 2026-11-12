# Ch24: Migrate one Bitbucket repository

**Session outcome:** You migrated an approved Bitbucket repository to GitHub and verified its Git history. A Server/Data Center migration also keeps supported pull request metadata. A Cloud migration keeps source and history only, and you recorded what was left out.

## Prerequisites

This session has no prerequisites from other sessions.

Access and tooling you need:
- GitHub organization where you are an org owner.
- Classic GitHub PAT available as `GH_PAT`.
- GitHub CLI `gh >= 2.4.0`.
- PowerShell, because `gh bbs2gh generate-script` emits `.ps1` scripts.
- For Path A: Bitbucket Server/Data Center 5.14+, a Bitbucket account with admin or super-admin rights, SSH/SFTP access for Linux servers or SMB access for Windows servers, and one staging store: AWS S3, Azure Blob, or GitHub-owned blob storage.
- For Path B: a bitbucket.org repository and the `git` CLI.

## Scenario

Your team supports both Bitbucket Server/Data Center and Bitbucket Cloud. The Server/Data Center repositories need their pull request history in GitHub. Bitbucket Cloud has no first-party path for metadata, so you keep its Git source and history and document what's lost.

> [!IMPORTANT]
> Use an approved Bitbucket Server/Data Center or Bitbucket Cloud repository as the source, and an approved GitHub target. Migrate only in an agreed change window with source writes frozen. If you don't have an approved repository, note what blocks you and the next step. Don't migrate an unapproved example.

## Choose the migration path

Run one route for one approved repository. For Server/Data Center, pick one staging store before you run anything. Prefer GitHub-owned storage when supported, and use the AWS or manual-archive route only as an alternative. Bulk migration is optional, after the owner accepts the pilot.

- Use Path A for Bitbucket Server/Data Center via `gh bbs2gh`. It preserves Git source, history, and pull request metadata.
- Use Path B for Bitbucket Cloud via Git CLI. It preserves source and history only. GitHub Enterprise Importer and `gh bbs2gh` don't support Bitbucket Cloud, so first-party tools can't migrate its pull requests, comments, issues, or pipelines.

## Path A: Bitbucket Server/Data Center via `gh bbs2gh`

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

Use a classic PAT. GEI doesn't support fine-grained PATs.

### 2. Confirm Server/Data Center prerequisites

Before you migrate, check that:

- Bitbucket Server/Data Center is version 5.14 or later.
- The Bitbucket account has admin or super-admin permissions.
- Linux instances expose the migration archive through SFTP.
- Windows instances expose it through an SMB share.
- The SFTP SSH private key has no passphrase and uses a supported cipher such as `aes256-ctr` or `aes256-cbc`.
- A clustered instance has a stable archive download host. Pass it with `--archive-download-host`.
- Blob staging is ready. Bitbucket usually sits behind a firewall, and GitHub Enterprise Importer must fetch the archive from an internet-reachable store.

For AWS S3, the IAM principal that `bbs2gh` uses needs these object and multipart permissions on the bucket:

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

To skip managing cloud storage, use GitHub-owned blob storage with `--use-github-storage`. It needs `gh bbs2gh` v1.9.0 or later. GitHub deletes the uploaded archive after the migration or after seven days.

### 3. Review the `bbs2gh` migration flow

`gh bbs2gh` works in stages because GitHub can't reach most Bitbucket Server/Data Center instances directly:

1. `bbs2gh` calls the Bitbucket Server/Data Center export API over HTTPS.
2. Bitbucket writes a migration `.tar` archive under `$BITBUCKET_SHARED_HOME/data/migration/export`.
3. `bbs2gh` downloads that archive from the Bitbucket server through SFTP on Linux or SMB on Windows.
4. `bbs2gh` uploads the archive to AWS S3, Azure Blob Storage, or GitHub-owned blob storage.
5. GitHub Enterprise Importer reads the staged archive and imports it into GitHub Enterprise Cloud.
6. The destination repository is created as private. If you do not pass a target name, the default is `projectKey-repositoryName`, such as `ENG-payments-api`.

### 4. Run a single-repository migration with AWS S3

Set these variables before running either migration command:

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

Use `--archive-download-host` for clustered deployments where the base URL is a load balancer but the archive must come from a specific node.

### 5. Alternative: GitHub-owned storage instead of AWS

Use this instead of step 4, not after it. You don't manage AWS or Azure staging storage:

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

Use a bulk script for migration waves, after you've validated one representative repository:

```bash
gh bbs2gh generate-script \
  --bbs-server-url "$BBS_URL" \
  --github-org "$GITHUB_ORG" \
  --output migrate-bitbucket-wave.ps1 \
  --download-migration-logs
```

Review every repository mapping in the generated PowerShell script. Then run it from a workstation with the same environment variables and network access as the single-repository test.

### 7. Alternative: Manual archive transfer

Skip this unless the server can't reliably expose SFTP or SMB. Don't rerun a completed migration through another route.

First, trigger archive generation without any archive download arguments:

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

Copy the `.tar` archive to your migration workstation by an approved internal transfer method, then import from the local archive:

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

In GitHub, confirm the repository is private and check:

- Git branches and tags.
- Commit history.
- Pull requests.
- Pull request comments.
- Pull request reviews.
- File and line-level review comments.
- Required reviewers.
- Pull request attachments.

Document what didn't migrate from Bitbucket Server/Data Center:

- Personal repositories owned by users.
- Branch permissions.
- Commit comments.
- Repository settings.
- Repository permissions.
- CI pipelines.

## Path B: Bitbucket Cloud fallback with Git CLI

### 1. Record the limitation before migrating

GitHub Enterprise Importer and `gh bbs2gh` don't support Bitbucket Cloud repositories on `bitbucket.org`. No first-party path migrates their pull requests, comments, issues, or pipeline history. The fallback is a Git mirror migration, which keeps source code and Git history only. For GHE.com targets, Git CLI is also the only way to move source history.

### 2. Mirror-clone and mirror-push

Create an empty private destination first with `gh repo create <org>/<repo> --private`. Confirm it holds no customer work, because a mirror push can overwrite or delete destination refs. Save the source branch and tag SHAs before pushing.

```bash
BITBUCKET_WORKSPACE="contoso-workspace"
BITBUCKET_REPO="web-portal"
GITHUB_ORG="contoso-migration-lab"
GITHUB_REPO="web-portal"

git clone --mirror "https://bitbucket.org/$BITBUCKET_WORKSPACE/$BITBUCKET_REPO.git"
cd "$BITBUCKET_REPO.git"
git push --mirror "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
```

### 3. Validate the Cloud migration

```bash
git ls-remote --heads "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
git ls-remote --tags "https://github.com/$GITHUB_ORG/$GITHUB_REPO.git"
```

Then document what didn't migrate:

- Pull requests and review comments.
- Issues.
- Bitbucket Pipelines configuration and run history.
- Repository settings, permissions, and branch restrictions.
- User identities for collaboration events.

## Accept the selected pilot

Compare `git ls-remote --heads --tags` output from source and destination by ref name and SHA. Matching counts aren't enough. Record any excluded provider refs. For Server/Data Center, check a known PR and its comments against the source. Recreate the team permissions and the CI and review requirements the tool doesn't migrate.

Open a first PR as a non-owner contributor. Verify that failing CI and a missing human approval block the merge. Then fix the failure and get approval before merging. Keep the source read-only until the owner accepts cutover, and record any metadata that didn't migrate.

## Cleanup

Save the approved evidence before you remove the local clone or archive from this pilot. Don't delete the source or destination repository.

If you didn't use GitHub-owned storage, delete the temporary S3 or Azure staging objects, or let a lifecycle policy expire them. Keep destination repositories unless the customer owner approves removing them.

## References

- [About GitHub Enterprise Importer](https://docs.github.com/en/migrations/using-github-enterprise-importer/understanding-github-enterprise-importer/about-github-enterprise-importer)
- [About migrations from Bitbucket Server to GitHub Enterprise Cloud](https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/about-migrations-from-bitbucket-server-to-github-enterprise-cloud)
- [Overview of a migration from Bitbucket Server to GitHub Enterprise Cloud](https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/overview-of-a-migration-from-bitbucket-server-to-github-enterprise-cloud)
- [Managing access for a Bitbucket Server migration](https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/managing-access-for-a-migration-from-bitbucket-server-to-github-enterprise-cloud)
- [Migrating repositories from Bitbucket Server to GitHub Enterprise Cloud](https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-from-bitbucket-server-to-github-enterprise-cloud/migrating-repositories-from-bitbucket-server-to-github-enterprise-cloud)
- [`gh-bbs2gh` extension](https://github.com/github/gh-bbs2gh)
