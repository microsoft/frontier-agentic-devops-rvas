# Ch42: Repository Lifecycle Governance

> Deliver owner-backed repository lifecycle decisions without letting setup archive, transfer, or delete anything.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. |
| App | Provisioned lifecycle sample repositories |
| EMU compatible | yes |

## Delivery target

- Delivery target: a lifecycle policy and a reviewed repository cohort.
- Safety boundary: archive, transfer, visibility, and delete operations require named approval. Setup only seeds sample repos and review material.
- Evidence: lifecycle criteria, repository decisions, approvals, retention notes, exceptions, and next review date.
- Owner: platform governance or engineering operations.

## Prerequisites

- GitHub Enterprise Cloud organization with org-owner rights.
- Token scopes from `setup.sh doctor ch42 --org <org>` (`repo` + `read:org`).
- `gh >= 2.x`, `git`, and `jq`.

## Scenario

The organization has active services, deprecated prototypes, and repositories with no owner. Create a lifecycle process that uses safe markers first. Allow destructive actions only after explicit approval.

## Sample setup

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch42 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch42 -Org <org>
```

Setup creates `ghec-ch42-active-service`, `ghec-ch42-deprecated-service`, and `ghec-ch42-archive-candidate` with lifecycle review issues. It does not archive, transfer, delete, or change org settings.

## Tasks

### Part A — Define lifecycle policy

1. Define lifecycle states: active, watch, deprecated, transfer candidate, archive candidate, delete candidate.
2. For each state, document criteria, owner, review cadence, required approvals, retention needs, and rollback expectations.
3. Snapshot the sample cohort:
   ```bash
   gh repo view <org>/ghec-ch42-active-service --json name,isArchived,visibility,description,repositoryTopics
   gh issue list --repo <org>/ghec-ch42-archive-candidate --state all --json number,title,labels
   ```

### Part B — Classify repositories

4. Classify each sample or customer repository using evidence: ownership, last use, open issues, dependent teams, data retention, and replacement status.
5. Apply safe, reversible markers such as topics, labels, README notices, or review issues:
   ```bash
   gh repo edit <org>/ghec-ch42-deprecated-service --add-topic lifecycle-deprecated
   gh issue create --repo <org>/ghec-ch42-deprecated-service --title "Lifecycle decision: deprecated" --body "Owner, rationale, next review, and exception path."
   ```
6. Record who approved each lifecycle state.

### Part C — Execute only approved high-impact actions

7. If archive is approved, execute it as a participant step and save evidence:
   ```bash
   gh repo archive <org>/ghec-ch42-archive-candidate --yes
   ```
8. If transfer or deletion is proposed, record the approval route and retention/legal checks before any action.
9. If approval is not available, leave the safe markers and a dated decision issue.

### Part D — Handover

10. Publish the lifecycle inventory location, review cadence, and escalation path.
11. Name the next repository cohort and owner.

## Reference links

- Archiving repositories — https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories
- Transferring a repository — https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository
- Deleting a repository — https://docs.github.com/en/repositories/creating-and-managing-repositories/deleting-a-repository
- Repositories REST API — https://docs.github.com/en/rest/repos/repos
- Repository topics — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics
