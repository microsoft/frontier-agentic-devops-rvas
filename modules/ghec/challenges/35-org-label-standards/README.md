# Ch35: Organization Label Standards

> Deliver an organization-owned label standard: default labels for new repositories, reconciliation for existing repositories, and accountable governance evidence.

## Prerequisites

- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch35 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS, Codespaces, or enterprise-owner features are required for this activity.

## Customer delivery objectives

You will:

- Design an organization label taxonomy with stable dimensions, colors, descriptions, and ownership.
- Configure organization default labels so future repositories start with the approved baseline.
- Verify default-label inheritance by creating a new repository after the default labels are configured.
- Reconcile a brownfield repository from inconsistent labels to the organization taxonomy.

## Scenario

A customer has dozens of repositories with labels such as `bug`, `Bug`, `urgent`, `sev1`, `backend`, and `needs review`. Their meanings overlap, reports cannot be trusted, and each new repository repeats the problem. Define one organization taxonomy, apply it to new repositories, and clean up an existing repository. Then hand ownership to the team that will maintain it.

> [!IMPORTANT]
> Choose the target before setup. If you have an authorised organization and repository cohort that will keep using the taxonomy, use its real default labels and one real repository wherever this guide names `ghec-ch35-existing-service` or `ghec-ch35-new-service`, and skip Setup. Otherwise use the two seeded repositories below, then move the approved taxonomy to an authorized customer target. Organization default labels are an org-wide setting — change them only with org-owner approval.
>
> Record the selected target, taxonomy owner, exception owner, and next action.

## Sample test repository or environment

Skip if you brought your own org/repo target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch35 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch35 --org <org>
```

Setup is idempotent and creates only these namespaced artifacts. Teardown accepts only the `ghec-ch35-*` prefix.

- `ghec-ch35-existing-service` with deliberately inconsistent labels and a few issues to reconcile.
- `ghec-ch35-new-service`, a clean repo you can delete/recreate or compare after organization default labels are changed.
- A printed organization default-label snapshot so you can see the starting point.
- A printed Next steps block telling you where to start.

## Tasks

### Part A — Inspect the current label baseline

1. Snapshot organization default labels:
   ```bash
   gh api /orgs/<org>/labels --paginate --jq '.[] | {name, color, description}'
   ```
2. Snapshot labels on the existing repository:
   ```bash
   gh label list --repo <org>/ghec-ch35-existing-service --limit 200 --json name,color,description
   ```
3. Identify duplicate meanings, casing drift, missing descriptions, and labels that should be repo-specific rather than organization-wide.

### Part B — Design the approved taxonomy

4. Define a stable taxonomy using the same dimension style used in earlier GHEC work:
   - `type:` → `type: bug`, `type: feature`, `type: chore`, `type: docs`
   - `priority:` → `priority: p0`, `priority: p1`, `priority: p2`
   - `area:` → `area: frontend`, `area: backend`, `area: platform`
   - `status:` → `status: needs-triage`, `status: blocked`, `status: in-review`
5. Choose the owner, rationale, color palette, description standard, exception process, and review cadence before changing organization defaults.
6. Decide which labels are organization defaults and which labels remain repository-local.

### Part C — Configure organization default labels

7. Create or update organization default labels from the approved taxonomy. Use the UI under Organization settings, or use the API:
   ```bash
   gh api -X POST /orgs/<org>/labels \
     -f name='type: bug' \
     -f color='B60205' \
     -f description='Defect in existing behavior'
   ```
8. If a label already exists, update it instead of creating a duplicate:
   ```bash
   gh api -X PATCH '/orgs/<org>/labels/type:%20bug' \
     -f color='B60205' \
     -f description='Defect in existing behavior'
   ```
9. Re-run the snapshot and save the "after" evidence.

### Part D — Verify inheritance on a new repository

10. Create a new repository after the organization defaults are configured, or use a clean validation repo:
    ```bash
    gh repo create <org>/ghec-ch35-new-service-check --private --description 'Default-label validation target'
    gh label list --repo <org>/ghec-ch35-new-service-check --limit 200 --json name,color,description
    ```
11. Confirm the new repository contains the approved organization default labels without manual repo-level setup.
12. Delete the temporary validation repo if it was created only for this proof, or record why it should remain.

### Part E — Reconcile an existing repository

13. Map old labels to approved labels. Example:
    - `Bug` and `bug` → `type: bug`
    - `urgent` → `priority: p0`
    - `backend` → `area: backend`
14. Apply approved labels to issues, then remove or rename old labels once no active issues depend on them:
    ```bash
    gh issue list --repo <org>/ghec-ch35-existing-service --label urgent --json number --jq '.[].number' |
      xargs -I{} gh issue edit {} --repo <org>/ghec-ch35-existing-service --add-label 'priority: p0'
    ```
15. Keep a short reconciliation note: labels merged, labels intentionally retained, and exceptions with owners.

## Reference links

- Managing default labels for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-default-labels-for-repositories-in-your-organization
- Managing labels — https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels
- Labels REST API — https://docs.github.com/en/rest/issues/labels
- Repositories REST API — https://docs.github.com/en/rest/repos/repos
