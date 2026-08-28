# Ch35 — Organization Label Standards

> Deliver an organization-owned label standard: default labels for new repositories, reconciliation for existing repositories, and accountable governance evidence.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Intermediate |
| Duration | ~3 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repositories (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: make labels a shared organization standard instead of a per-repository habit.
- Customer-tenant target: approved organization default labels and one reconciled repository.
- Approval and safety boundary: change organization default labels only when the accountable org owner approves them; otherwise produce an approved rollout proposal and test the sample repos.
- Records to keep: retain the taxonomy, API snapshots, reconciliation notes, exception process, and review cadence.
- Adoption owner / handover: the platform governance or developer experience owner accepts ongoing label taxonomy ownership.
- Next action and owner: choose the next repository cohort to reconcile or approve the default-label rollout.

## Prerequisites

- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch35 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS, Codespaces, or enterprise-owner features are required for this activity.

## Customer delivery objectives

This delivery engagement establishes:

- Design an organization label taxonomy with stable dimensions, colors, descriptions, and ownership.
- Configure organization default labels so future repositories start with the approved baseline.
- Verify default-label inheritance by creating a new repository after the default labels are configured.
- Reconcile a brownfield repository from inconsistent labels to the organization taxonomy.
- Record the taxonomy, exceptions, and evidence in the customer governance register.

## Scenario

A customer has dozens of repositories with labels like `bug`, `Bug`, `urgent`, `sev1`, `backend`, and `needs review`, all meaning slightly different things. Reporting is unreliable and new repositories repeat the same drift. Your job is to turn labels into an organization standard: define the taxonomy, make new repositories inherit it, clean up one existing repository, and hand over an owner-backed operating model.

> [!IMPORTANT]
> Use an approved customer target (do this first)
>
> Default to an authorised customer organization and repository cohort that will keep using the taxonomy after delivery. Complete the work on that artifact and retain the evidence, guardrails, or automation.
>
> - Have a candidate? Use your real organization default labels and one real repository wherever this guide names `ghec-ch35-existing-service` or `ghec-ch35-new-service`. Skip the Setup step below entirely.
> - No suitable one? Use the fallback below: two seeded repositories, one deliberately inconsistent and one clean validation target.
>
> Record the selected target, taxonomy owner, exception owner, and next action. Use the sample only for testing; move the approved taxonomy to an authorized customer target.

## Sample test repository or environment (when tenant delivery is constrained)

Skip this if you brought your own org/repo target. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch35 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch35 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch35-*`, idempotent, prefix-guarded teardown):

- `ghec-ch35-existing-service` with deliberately inconsistent labels and a few issues to reconcile.
- `ghec-ch35-new-service`, a clean repo you can delete/recreate or compare after organization default labels are changed.
- A printed organization default-label snapshot so you can see the starting point.
- A printed Next steps block telling you where to start.

## Tasks

> Throughout, `ghec-ch35-existing-service` and `ghec-ch35-new-service` are fallback samples. If you brought your own artifacts, substitute their names in every command and use your real history, teams, settings, or data as the material to work from.

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
5. Record the owner, rationale, color palette, description standard, exception process, and review cadence in the governance settings register.
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

## Validation / Definition of Done

You are done when ALL of the following are true:

- [ ] An approved organization label taxonomy exists with names, descriptions, colors, owner, review cadence, and exception path.
- [ ] Organization default labels include the approved `type:`, `priority:`, `area:`, and `status:` dimensions.
- [ ] A newly created repository inherits the approved organization default labels.
- [ ] At least one existing repository is reconciled from inconsistent labels to the approved taxonomy.
- [ ] Governance register rows or an equivalent customer-owned record link to before/after snapshots and the next review decision.
- [ ] Real-outcome check — if you brought your own repository, the taxonomy now applies where the team will keep using it; if you used the sample, you can name the repository cohort to reconcile next.
- [ ] Adoption handover — name the taxonomy owner, exception approver, next repository cohort, and review date.

> Coaches verify these via the automated hints in `COACH.md`.

## Operational extensions

- Write a small reconcile script that compares organization default labels to every repository in a selected cohort.
- Add a pull request template or issue form guidance telling teams when to request a new organization label.
- Use repository custom properties from Ch08 to target reconciliation by repository class.

## Reference links

- Managing default labels for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-default-labels-for-repositories-in-your-organization
- Managing labels — https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels
- Labels REST API — https://docs.github.com/en/rest/issues/labels
- Repositories REST API — https://docs.github.com/en/rest/repos/repos
