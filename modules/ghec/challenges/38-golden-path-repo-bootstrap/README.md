# Ch38: Golden-Path Repository Bootstrap

> Deliver a governed starter path for new repositories: template, baseline files, validation, and handover evidence.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. |
| App | Provisioned template candidate and validation repository |
| EMU compatible | yes |

## Customer delivery target

- Objective: make new repositories start from an approved, supportable baseline.
- Delivery target: a customer-owned template or bootstrap repository and one validated repository created from it.
- Safety boundary: organization-wide defaults, member repository creation policy, and required rules need explicit approval. Setup creates only namespaced sample repositories.
- Evidence: baseline checklist, template URL, validation snapshots, exceptions, owner, and next rollout cohort.
- Owner: developer experience or platform governance.

## Prerequisites

- GitHub Enterprise Cloud organization with org-owner rights.
- Token scopes from `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch38 --org <org>` (`repo` + `read:org`; `admin:org` only if you choose approved org setting changes manually).
- `gh >= 2.x`, `git`, and `jq`.

## Scenario

Teams create repositories by copying old projects. The copies often lack owners, support files, or baseline controls. Define a golden path that makes the first commit predictable and auditable without silently changing organization-wide settings.

> [!IMPORTANT]
> Use a real customer template repository when available. If none is approved, run the setup and use `ghec-ch38-golden-path-template` plus `ghec-ch38-bootstrap-candidate` as fallback samples.

## Sample setup

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch38 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch38 -Org <org>
```

Setup creates only namespaced sample repositories:

- `ghec-ch38-golden-path-template` with README, CODEOWNERS, issue form, PR template, and workflow guidance.
- `ghec-ch38-bootstrap-candidate`, an empty validation target.
- No organization defaults, rulesets, member privileges, or tokens are changed.

## Tasks

### Part A — Approve the bootstrap standard

1. Record the authorized scope, template owner, support team, exception path, and review cadence.
2. Define the baseline: README, ownership, issue intake, PR checklist, labels, branch/ruleset expectations, Actions permissions, secret policy, and required metadata.
3. Decide which controls are enforced now and which require a later org-owner approval.

### Part B — Inspect the template candidate

4. Review the seeded files in `ghec-ch38-golden-path-template`:
   ```bash
   gh repo view <org>/ghec-ch38-golden-path-template --json name,isTemplate,visibility,description
   gh api repos/<org>/ghec-ch38-golden-path-template/contents/.github/CODEOWNERS --jq .name
   ```
5. Mark it as a template only after approval:
   ```bash
   gh api -X PATCH repos/<org>/ghec-ch38-golden-path-template -f is_template=true
   ```
6. Save the before/after evidence.

### Part C — Bootstrap and validate a repository

7. Create a repository from the template, or apply the same files to the validation target:
   ```bash
   gh repo create <org>/ghec-ch38-bootstrap-check --private --template <org>/ghec-ch38-golden-path-template
   ```
8. Validate required files and settings:
   ```bash
   gh api repos/<org>/ghec-ch38-bootstrap-check/contents/.github/pull_request_template.md --jq .name
   gh repo view <org>/ghec-ch38-bootstrap-check --json name,visibility,description,defaultBranchRef
   ```
9. Record baseline gaps, approved exceptions, and the owner for each remediation.

### Part D — Handover

10. Document how teams request template changes.
11. Name the first production repository cohort and review date.
12. If high-impact org defaults are desired, capture the explicit approval and execute them outside setup.

## Validation / Definition of Done

- [ ] Golden-path standard names owner, scope, required files/settings, exception path, and review cadence.
- [ ] Template contains baseline README, CODEOWNERS, issue form, PR template, and workflow guidance.
- [ ] One repository is created from or reconciled to the template.
- [ ] Validation evidence shows baseline files and settings.
- [ ] Organization-wide changes are either explicitly approved and recorded or deferred with owner/date.
- [ ] Adoption handover names the template maintainer and next rollout cohort.

> Coaches verify these via `COACH.md`.

## Reference links

- Creating a template repository — https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository
- Creating a repository from a template — https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template
- CODEOWNERS — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- Issue templates — https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- Repositories REST API — https://docs.github.com/en/rest/repos/repos
