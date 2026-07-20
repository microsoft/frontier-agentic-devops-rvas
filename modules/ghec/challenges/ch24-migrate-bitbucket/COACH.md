# Ch24 — Migrate Bitbucket to GitHub (Server & Cloud) — Coach Guide

> Audience: facilitators and graders. Pair with the delivery team member `README.md`.

## Intent

This activity teaches customer practitioners to choose the correct Bitbucket migration path instead of treating all Bitbucket sources as equivalent. The primary hands-on path is Bitbucket Server/Data Center to GitHub Enterprise Cloud with `gh bbs2gh`, preserving Git history and pull request metadata. The fallback path is Bitbucket Cloud to GitHub using `git clone --mirror` and `git push --mirror`, preserving only source and Git history.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Orientation and migration-fidelity discussion | ~20 min |
| Server/Data Center prerequisite checks | ~35 min |
| Single-repo `gh bbs2gh` migration | ~75 min |
| Bulk script and manual archive walkthrough | ~35 min |
| Bitbucket Cloud mirror fallback | ~35 min |
| Validation, documentation, and debrief | ~40 min |
| **Total** | **~240 min** |

## Expected Outputs

When a delivery team member completes this activity successfully, you should see:

- `gh-bbs2gh` installed in `gh extension list`.
- Environment variables for `GH_PAT`, `BBS_USERNAME`, `BBS_PASSWORD`, and storage credentials set only in the shell, not committed.
- A migrated GitHub repository created as private from a Bitbucket Server/Data Center source.
- Git source, branches, tags, commit history, pull requests, comments, reviews, file/line comments, required reviewers, and attachments visible in GitHub for the Server/Data Center path.
- Evidence that AWS S3, Azure Blob, or GitHub-owned blob storage handled the archive handoff.
- A reviewed `migrate-bitbucket-wave.ps1` or equivalent generated script for bulk planning.
- A written note explaining the manual archive path from `$BITBUCKET_SHARED_HOME/data/migration/export` to `--archive-path`.
- A GitHub repository populated from Bitbucket Cloud using a mirror push, with branches and tags present.
- A clear loss register: branch permissions, commit comments, repo settings, repo permissions, and CI pipelines for Server/Data Center; pull requests, issues, comments, pipelines, settings, permissions, and branch restrictions for Cloud.

## Environment guidance for coaches

A real Bitbucket Server/Data Center instance is the best lab because customer practitioners see the export API, SFTP or SMB transfer, and archive staging behavior. If no enterprise lab instance is available, a lightweight coach-managed option is to run a temporary Bitbucket Server/Data Center evaluation container or VM with one seeded project, one repository, and a few pull requests. Ensure the version is 5.14 or later, SFTP is enabled for Linux, and `$BITBUCKET_SHARED_HOME` is accessible.

Do not let the workshop stall if a Server/Data Center instance is unavailable. The Bitbucket Cloud Git CLI path is the guaranteed-doable fallback and still teaches an important migration decision: Bitbucket Cloud has no GEI or `bbs2gh` metadata support.

## Common Pitfalls

### SSH cipher error: `aes256-ctr not supported`
**Symptom:** `bbs2gh` fails during SFTP negotiation or reports an unsupported cipher.
**Fix:** Regenerate the migration SSH key with no passphrase and configure the server/client to use a supported cipher such as `aes256-ctr` or `aes256-cbc`.

### SFTP subsystem disabled
**Symptom:** The Bitbucket export succeeds, but archive download fails with `Subsystem 'sftp' could not be executed`.
**Fix:** Enable the OpenSSH SFTP subsystem on the Bitbucket server or use the manual archive path.

### Wrong `--bbs-shared-home` or archive location
**Symptom:** The generated archive cannot be found or the manual archive path points at an empty directory.
**Fix:** Confirm the effective `$BITBUCKET_SHARED_HOME` for the Bitbucket node and look under `data/migration/export`.

### Azure SAS connection string rejected
**Symptom:** Azure Blob upload fails even though the storage URL looks valid.
**Fix:** Use an access-key connection string in `AZURE_STORAGE_CONNECTION_STRING`; SAS connection strings are not supported.

### Destination ruleset blocks migration with `GH013`
**Symptom:** GEI reports repository rule violations during import.
**Fix:** Add `Repository migrations` to the destination organization ruleset bypass list or relax the blocking rule during the migration wave.

### Private email push protection blocks Cloud fallback with `GH007`
**Symptom:** `git push --mirror` fails because a commit would publish a private email address.
**Fix:** Decide whether to rewrite commit author emails before cutover or temporarily change the destination setting with explicit owner approval.

### Cloud users expect pull requests to migrate
**Symptom:** Customer practitioners ask for a `bbs2gh` command for bitbucket.org or expect PRs to appear after a mirror push.
**Fix:** Restate the product boundary: Bitbucket Cloud is not supported by GEI or `bbs2gh`; first-party migration preserves source and history only.

### Clustered Bitbucket archive download fails
**Symptom:** Export works through the Bitbucket base URL, but archive download fails or downloads from the wrong node.
**Fix:** Use `--archive-download-host` to point at the node that can serve the archive.

## Progressive Hints

1. **Gentle:** First identify your source type. If the URL is `bitbucket.org`, you are not on the `bbs2gh` metadata path.
2. **Medium:** For Server/Data Center, trace the archive handoff. Can `bbs2gh` cause Bitbucket to export, reach the archive over SFTP or SMB, and then upload it to internet-reachable blob storage?
3. **Specific:** If the export exists but import does not start, inspect `$BITBUCKET_SHARED_HOME/data/migration/export`, verify the storage flag (`--aws-bucket-name`, Azure connection string, or `--use-github-storage`), and retry with `--archive-download-host` for clustered deployments.

## Debrief Questions

- Which Bitbucket repositories in your real estate need PR metadata, and which can accept a source-history-only migration?
- What is your cutover freeze window, and who decides whether a failed repository is retried, deferred, or migrated by Git mirror only?
- Which controls must be recreated after migration: branch permissions, repository permissions, rulesets, CI/CD, webhooks, or teams?
- How will you prove a migration wave is complete before users start working in GitHub?
- What message will you give Bitbucket Cloud teams about PR and issue history before migration day?

## Grading rubric (100 pts)

| Criterion | Points | Full marks look like |
|---|---:|---|
| Path selection | 15 | Correctly separates Server/Data Center metadata migration from Cloud source-history-only migration |
| Server/Data Center prerequisites | 15 | Verifies version, admin access, SFTP/SMB, SSH key constraints, and blob storage |
| Single-repo `bbs2gh` execution | 20 | Runs a complete migration command and produces a private GitHub destination repo |
| Metadata validation | 15 | Confirms PRs, reviews, comments, required reviewers, and attachments migrated |
| Bulk and manual archive planning | 10 | Generates/reviews a PowerShell script and explains `--archive-path` |
| Cloud mirror fallback | 10 | Mirror-pushes a bitbucket.org repo and validates branches/tags |
| Loss register and follow-up plan | 10 | Documents not-migrated data and post-migration rebuild tasks |
| Coach conversation | 5 | Connects the exercise to a real migration wave and risk plan |

## Verification aids

Use these checks as prompts; adapt names to the customer practitioner's repositories.

```bash
gh extension list | grep bbs2gh

gh repo view contoso-migration-lab/payments-api --json name,visibility,defaultBranchRef

git ls-remote --heads https://github.com/contoso-migration-lab/web-portal.git
git ls-remote --tags https://github.com/contoso-migration-lab/web-portal.git
```

For Server/Data Center, UI inspection is required for PR metadata. Ask the customer practitioner to open migrated pull requests and show comments, reviews, file/line comments, required reviewers, and attachments.

## Coach conversation prompt

Before marking complete, ask:

> Pick one real Bitbucket migration wave. Which repositories require pull request metadata, which can use a mirror fallback, what will you freeze during cutover, and what evidence lets you reopen work in GitHub?

Look for concrete answers: repository names or classes, source type, storage choice, validation checks, known losses, and a retry or rollback decision.
