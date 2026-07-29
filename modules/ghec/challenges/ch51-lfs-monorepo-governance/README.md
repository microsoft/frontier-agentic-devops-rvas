# Ch51 — LFS and Monorepo Governance

> Deliver governance for a growing monorepo: ownership boundaries, Git LFS patterns, large-file intake, repository health evidence, and explicit storage decisions.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + repository administrator rights. |
| App | Provisioned monorepo governance repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: prevent monorepo sprawl, unclear ownership, and large-file storage surprises.
- Customer-tenant target: an approved monorepo or monorepo candidate.
- Approval and safety boundary: history rewrites, LFS migrations, retention changes, and quota purchases are high-impact decisions; setup does not perform them. Execute only after explicit owner approval.
- Records to keep: retain repository health evidence, `.gitattributes`, CODEOWNERS map, large-file exceptions, storage owner, and migration decisions.
- Adoption owner / handover: the platform, source-control, or monorepo governance owner accepts ongoing operations.
- Next action and owner: choose the next package area, LFS migration decision, or enforcement control.

## Prerequisites

- A GitHub Enterprise Cloud organization and repository administrator rights.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch51 --org <org>` (least privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`; `git lfs` is recommended for production validation but not required by setup.
- No setup step commits large binaries, rewrites history, changes quotas, or mutates organization policy.

## Customer delivery objectives

This delivery engagement establishes:

- Inspect repository size, large-file risk, and existing LFS configuration.
- Define approved LFS patterns and a large-file exception path.
- Map monorepo package paths to owners through CODEOWNERS or equivalent governance evidence.
- Record storage/quota owner, migration approver, review cadence, and high-impact decisions.
- Validate the workflow with a sample large-file intake issue.

## Scenario

A customer wants one repository for many services, docs, generated assets, and models. The repo is growing, ownership is unclear, and teams sometimes commit binaries directly. Your job is to create the governance layer: package owners, approved LFS patterns, intake for exceptions, and an evidence-backed decision about when to enforce or migrate.

> [!IMPORTANT]
> Use an approved customer target (do this first)
>
> Default to an authorised customer monorepo or monorepo candidate. Complete the work on that artifact and retain the evidence.
>
> - Have a candidate? Use the real repository wherever this guide names `ghec-ch51-lfs-monorepo-governance`. Skip setup.
> - No suitable one? Use the fallback below: a seeded monorepo-shaped repository with packages, `.gitattributes`, CODEOWNERS, governance docs, labels, and sample intake issue.
>
> Record the selected target, storage owner, package owners, migration approver, exception owner, and next action.

## Sample test repository or environment (when tenant delivery is constrained)

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch51 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch51 -Org <org>
```

What setup creates (all artifacts namespaced `ghec-ch51-*`, idempotent, prefix-guarded teardown):

- `ghec-ch51-lfs-monorepo-governance` with package folders, docs, `.gitattributes`, and `.github/CODEOWNERS`.
- Labels for `monorepo: ownership`, `lfs: review`, `lfs: approved`, and `lfs: blocked`.
- A sample large-file intake issue.
- Printed repository size, LFS, CODEOWNERS, and ruleset inspection commands; setup does not rewrite history, commit large binaries, or change quotas.

## Tasks

### Part A — Inspect repository health

1. Snapshot repository metadata:
   ```bash
   gh repo view <org>/ghec-ch51-lfs-monorepo-governance --json name,visibility,diskUsage,defaultBranchRef
   ```
2. Inspect current LFS tracking and large-file patterns from a local clone or existing evidence:
   ```bash
   git lfs track
   git rev-list --objects --all | sort -k 2 > repo-object-inventory.txt
   ```
3. Record branch/tag count, large file candidates, generated content, package boundaries, and known quota concerns.

### Part B — Define LFS and large-file policy

4. Complete `docs/lfs-monorepo-governance.md` or the customer register with:
   - approved LFS patterns
   - prohibited direct-binary patterns
   - exception owner and expiry rules
   - storage/quota owner
   - history rewrite or migration approver
   - review cadence and evidence location
5. Review `.gitattributes` and decide which patterns are advisory versus enforced in the production repository.

### Part C — Map monorepo ownership

6. Review `.github/CODEOWNERS` and map package paths to accountable teams.
7. Validate that each service, docs area, and shared package has an owner and escalation path.
8. Decide whether branch protection or rulesets should require CODEOWNERS review. Record the decision; change enforcement only after approval.

### Part D — Operate large-file intake

9. Open a large-file intake issue for a proposed binary or generated asset.
10. Capture file pattern, expected size, update frequency, retention need, consuming teams, and alternative storage options.
11. Apply `lfs: approved` or `lfs: blocked`, and update `.gitattributes` only for approved patterns.

### Part E — Handover and rollout

12. Record storage/quota owner, package owners, migration approver, exception owner, and next review date.
13. Choose the next step: advisory policy, CODEOWNERS enforcement, LFS migration plan, repository split, or storage/quota decision.

## Validation / Definition of Done

- [ ] Monorepo governance policy identifies ownership boundaries, CODEOWNERS strategy, LFS patterns, large-file exception path, storage/quota owner, and review cadence.
- [ ] Repository evidence captures current size, large-file candidates, branch/tag risk, and LFS tracking configuration.
- [ ] `.gitattributes` plan or implementation tracks approved binary patterns with Git LFS and setup did not commit large binaries.
- [ ] CODEOWNERS or equivalent evidence maps monorepo areas to accountable reviewers.
- [ ] Storage, retention, history rewrite, and migration decisions are explicit participant steps, not hidden setup mutations.
- [ ] Adoption handover names storage owner, package owners, exception approver, next rollout decision, and review date.

## Operational extensions

- Add a CI check that rejects unapproved large files.
- Enforce CODEOWNERS review through branch protection or repository rulesets after approval.
- Build a migration plan with `git lfs migrate` only after explicit history rewrite approval.

## Reference links

- About Git Large File Storage — https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage
- Configuring Git Large File Storage — https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage
- About CODEOWNERS — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- About large files on GitHub — https://docs.github.com/en/repositories/working-with-files/managing-files/about-large-files-on-github
- Repository limits — https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits
