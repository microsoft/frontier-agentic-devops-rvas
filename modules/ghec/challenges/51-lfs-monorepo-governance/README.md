# Ch51: LFS and Monorepo Governance

> Deliver governance for a growing monorepo: ownership boundaries, Git LFS patterns, large-file intake, repository health evidence, and explicit storage decisions.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Advanced |
| Duration | 120 min |
| Minimum input | An org + repository administrator rights. |
| App | Provisioned monorepo governance repository (created by setup) |
| EMU compatible | yes |

## Prerequisites

- A GitHub Enterprise Cloud organization and repository administrator rights.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch51 --org <org>` (least privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`; `git lfs` is recommended for production validation but not required by setup.
- No setup step commits large binaries, rewrites history, changes quotas, or mutates organization policy.

## Customer delivery objectives

You will:

- Inspect repository size, large-file risk, and existing LFS configuration.
- Define approved LFS patterns and a large-file exception path.
- Map monorepo package paths to owners through CODEOWNERS or equivalent governance evidence.
- Record storage/quota owner, migration approver, review cadence, and high-impact decisions.
- Validate the workflow with a sample large-file intake issue.

## Scenario

A customer wants one repository for many services, docs, generated assets, and models. The repository is growing, ownership is unclear, and teams sometimes commit binaries directly. Define package owners, approved LFS patterns, and an exception intake path. Record when the team will enforce the policy or migrate existing files.

> [!IMPORTANT]
> Choose the target before setup. Use an authorised customer monorepo or candidate if you have one, wherever this guide names `ghec-ch51-lfs-monorepo-governance`, and skip setup. Otherwise use the fallback seeded repository below.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch51 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch51 -Org <org>
```

Setup is idempotent and creates only these namespaced artifacts. Teardown accepts only the `ghec-ch51-*` prefix.

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

4. Complete `docs/lfs-monorepo-governance.md` with:
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

## Reference links

- About Git Large File Storage — https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage
- Configuring Git Large File Storage — https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage
- About CODEOWNERS — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- About large files on GitHub — https://docs.github.com/en/repositories/working-with-files/managing-files/about-large-files-on-github
- Repository limits — https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits
