# Ch43 — Repository Inventory Cleanup

> Deliver a practical inventory cleanup pass: discover, classify, fix safe metadata, and queue high-impact cleanup with approvals.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Intermediate |
| Duration | ~3 hrs total, multi-session |
| Minimum input | An org + an org-owner token. |
| App | Provisioned inventory sample repositories |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: make repository inventory trustworthy enough for ownership, reporting, and cleanup decisions.
- Customer-tenant target: a reviewed repository cohort with owner and cleanup decisions.
- Approval and safety boundary: setup creates sample repositories only. Archive, delete, transfer, visibility, and org settings require explicit participant approval.
- Records to keep: inventory export, decision register, metadata changes, exceptions, and next cohort.
- Adoption owner / handover: platform governance or developer experience owner accepts the cleanup workflow.

## Prerequisites

- GitHub Enterprise Cloud organization with org-owner rights.
- Token scopes from `setup.sh doctor ch43 --org <org>` (`repo` + `read:org`).
- `gh >= 2.x`, `git`, and `jq`.

## Scenario

The organization has repositories with unclear owners, duplicate names, stale purpose, and inconsistent topics. Your job is to produce an inventory, classify cleanup decisions, improve safe metadata, and queue risky changes for approval.

## Sample setup

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch43 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch43 -Org <org>
```

Setup creates `ghec-ch43-owned-service`, `ghec-ch43-orphan-tool`, and `ghec-ch43-duplicate-api` with seeded review issues/topics. It does not archive, delete, transfer, or change org settings.

## Tasks

### Part A — Define inventory fields

1. Agree required fields: repository, owner/team, purpose, visibility, topics, lifecycle state, data classification, criticality, last review, cleanup decision, and next owner.
2. Export a cohort:
   ```bash
   gh repo list <org> --limit 200 --json name,visibility,isArchived,description,repositoryTopics,pushedAt,updatedAt
   ```
3. Identify gaps: blank owner, weak description, duplicate purpose, stale samples, missing topics, or uncertain visibility.

### Part B — Review sample repositories

4. Inspect seeded repos:
   ```bash
   gh repo view <org>/ghec-ch43-orphan-tool --json name,description,repositoryTopics,visibility,isArchived
   gh issue list --repo <org>/ghec-ch43-duplicate-api --state all --json number,title,labels
   ```
5. Assign cleanup decisions: keep, enrich metadata, merge, transfer, archive candidate, or delete candidate.
6. Record rationale and approval route for each decision.

### Part C — Apply safe cleanup

7. Apply safe metadata updates to at least one repository:
   ```bash
   gh repo edit <org>/ghec-ch43-orphan-tool --description "Inventory sample: owner review required" --add-topic inventory-owner-needed
   gh issue create --repo <org>/ghec-ch43-orphan-tool --title "Inventory cleanup decision" --body "Owner gap, decision, approver, and next review."
   ```
8. Queue high-impact cleanup only after approval. If not approved, leave the marker and decision issue.

### Part D — Handover

9. Store the inventory and decision register in the customer governance location.
10. Name the next cohort, owner, and review cadence.

## Validation / Definition of Done

- [ ] Inventory fields and cleanup decision values are defined.
- [ ] A sample or customer cohort is exported and reviewed.
- [ ] Missing metadata, unowned repos, and duplicate-purpose repos are identified.
- [ ] At least one safe metadata improvement is applied.
- [ ] High-impact actions are explicitly approved or deferred with owner/date.
- [ ] Adoption handover names the inventory owner and next cleanup cohort.

## Reference links

- Repositories REST API — https://docs.github.com/en/rest/repos/repos
- Searching for repositories — https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories
- Repository topics — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics
- Archiving repositories — https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories
