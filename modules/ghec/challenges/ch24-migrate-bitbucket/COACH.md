# Ch24 — Migrate Bitbucket to GitHub (Server & Cloud) — Delivery Assurance Guide
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.

> Audience: delivery assurance leads and authorized customer migration owners. Pair with the corresponding customer implementation `README.md`.

## Intent

Choose the authorized Bitbucket migration path rather than treating all Bitbucket sources as equivalent. The primary customer implementation path is Bitbucket Server/Data Center to GitHub Enterprise Cloud with `gh bbs2gh`, preserving Git history and pull request metadata. The Bitbucket Cloud `git clone --mirror` and `git push --mirror` path is a controlled fallback that preserves only source and Git history; its loss register must drive the customer cutover decision.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Authorized scope and migration-fidelity decision | ~20 min |
| Server/Data Center prerequisite checks | ~35 min |
| Single-repo `gh bbs2gh` migration | ~75 min |
| Bulk script and manual archive walkthrough | ~35 min |
| Bitbucket Cloud mirror fallback | ~35 min |
| Validation, handover, and cutover decision | ~40 min |
| Total | ~240 min |

## Expected Outputs

For delivery assurance, collect the following customer-owned evidence:

- `gh-bbs2gh` installed in `gh extension list`.
- Environment variables for `GH_PAT`, `BBS_USERNAME`, `BBS_PASSWORD`, and storage credentials set only in the shell, not committed.
- A migrated GitHub repository created as private from a Bitbucket Server/Data Center source.
- Git source, branches, tags, commit history, pull requests, comments, reviews, file/line comments, required reviewers, and attachments visible in GitHub for the Server/Data Center path.
- Evidence that AWS S3, Azure Blob, or GitHub-owned blob storage handled the archive handoff.
- A reviewed `migrate-bitbucket-wave.ps1` or equivalent generated script for bulk planning.
- A written note explaining the manual archive path from `$BITBUCKET_SHARED_HOME/data/migration/export` to `--archive-path`.
- A GitHub repository populated from Bitbucket Cloud using a mirror push, with branches and tags present.
- A clear loss register: branch permissions, commit comments, repo settings, repo permissions, and CI pipelines for Server/Data Center; pull requests, issues, comments, pipelines, settings, permissions, and branch restrictions for Cloud.

## Customer implementation environment guidance

An authorized Bitbucket Server/Data Center instance is preferred because customer implementation owners validate the export API, SFTP or SMB transfer, and archive staging behavior. If no authorized customer instance is available, use a controlled Bitbucket Server/Data Center evaluation container or VM with one seeded project, one repository, and a few pull requests. Ensure the version is 5.14 or later, SFTP is enabled for Linux, and `$BITBUCKET_SHARED_HOME` is accessible.

Do not let delivery stall if a Server/Data Center instance is unavailable. The Bitbucket Cloud Git CLI path is a safe fallback and must still produce an explicit migration-fidelity and cutover decision: Bitbucket Cloud has no GEI or `bbs2gh` metadata support.

## Common Pitfalls

### SSH cipher error: `aes256-ctr not supported`
Symptom: `bbs2gh` fails during SFTP negotiation or reports an unsupported cipher.
Fix: Regenerate the migration SSH key with no passphrase and configure the server/client to use a supported cipher such as `aes256-ctr` or `aes256-cbc`.

### SFTP subsystem disabled
Symptom: The Bitbucket export succeeds, but archive download fails with `Subsystem 'sftp' could not be executed`.
Fix: Enable the OpenSSH SFTP subsystem on the Bitbucket server or use the manual archive path.

### Wrong `--bbs-shared-home` or archive location
Symptom: The generated archive cannot be found or the manual archive path points at an empty directory.
Fix: Confirm the effective `$BITBUCKET_SHARED_HOME` for the Bitbucket node and look under `data/migration/export`.

### Azure SAS connection string rejected
Symptom: Azure Blob upload fails even though the storage URL looks valid.
Fix: Use an access-key connection string in `AZURE_STORAGE_CONNECTION_STRING`; SAS connection strings are not supported.

### Destination ruleset blocks migration with `GH013`
Symptom: GEI reports repository rule violations during import.
Fix: Add `Repository migrations` to the destination organization ruleset bypass list or relax the blocking rule during the migration wave.

### Private email push protection blocks Cloud fallback with `GH007`
Symptom: `git push --mirror` fails because a commit would publish a private email address.
Fix: Decide whether to rewrite commit author emails before cutover or temporarily change the destination setting with explicit owner approval.

### Cloud users expect pull requests to migrate
Symptom: Customer implementation owners ask for a `bbs2gh` command for bitbucket.org or expect PRs to appear after a mirror push.
Fix: Restate the product boundary: Bitbucket Cloud is not supported by GEI or `bbs2gh`; first-party migration preserves source and history only.

### Clustered Bitbucket archive download fails
Symptom: Export works through the Bitbucket base URL, but archive download fails or downloads from the wrong node.
Fix: Use `--archive-download-host` to point at the node that can serve the archive.

## Implementation troubleshooting prompts

1. Gentle: First identify your source type. If the URL is `bitbucket.org`, you are not on the `bbs2gh` metadata path.
2. Medium: For Server/Data Center, trace the archive handoff. Can `bbs2gh` cause Bitbucket to export, reach the archive over SFTP or SMB, and then upload it to internet-reachable blob storage?
3. Specific: If the export exists but import does not start, inspect `$BITBUCKET_SHARED_HOME/data/migration/export`, verify the storage flag (`--aws-bucket-name`, Azure connection string, or `--use-github-storage`), and retry with `--archive-download-host` for clustered deployments.

## Customer adoption decision

- Which Bitbucket repositories in your real estate need PR metadata, and which can accept a source-history-only migration?
- What is your cutover freeze window, and who decides whether a failed repository is retried, deferred, or migrated by Git mirror only?
- Which controls must be recreated after migration: branch permissions, repository permissions, rulesets, CI/CD, webhooks, or teams?
- How will you prove a migration wave is complete before users start working in GitHub?
- What message will you give Bitbucket Cloud teams about PR and issue history before migration day?

## Implementation acceptance evidence

| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Path selection | 15 | Correctly separates Server/Data Center metadata migration from Cloud source-history-only migration |
| Server/Data Center prerequisites | 15 | Verifies version, admin access, SFTP/SMB, SSH key constraints, and blob storage |
| Single-repo `bbs2gh` execution | 20 | Runs a complete migration command and produces a private GitHub destination repo |
| Metadata validation | 15 | Confirms PRs, reviews, comments, required reviewers, and attachments migrated |
| Bulk and manual archive planning | 10 | Generates/reviews a PowerShell script and explains `--archive-path` |
| Cloud mirror fallback | 10 | Mirror-pushes a bitbucket.org repo and validates branches/tags |
| Loss register and follow-up plan | 10 | Documents not-migrated data and post-migration rebuild tasks |
| Adoption decision | 5 | Records the real migration wave, risk plan, accountable owner, and next cutover action |

## Verification aids

Use these checks as prompts; adapt names to the customer implementation owner's repositories.

```bash
gh extension list | grep bbs2gh

gh repo view contoso-migration-lab/payments-api --json name,visibility,defaultBranchRef

git ls-remote --heads https://github.com/contoso-migration-lab/web-portal.git
git ls-remote --tags https://github.com/contoso-migration-lab/web-portal.git
```

For Server/Data Center, UI inspection is required for PR metadata. Ask the customer implementation owner to show migrated pull requests, comments, reviews, file/line comments, required reviewers, and attachments.

## Customer adoption decision prompt

Before accepting implementation evidence, ask:

> Pick one real Bitbucket migration wave. Which repositories require pull request metadata, which can use a mirror fallback, what will you freeze during cutover, and what evidence lets you reopen work in GitHub?

Record concrete evidence: repository names or classes, source type, storage choice, validation checks, known losses, accountable owner, and a retry, rollback, or cutover decision.
