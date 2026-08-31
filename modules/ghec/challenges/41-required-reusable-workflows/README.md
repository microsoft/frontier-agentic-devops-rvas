# Ch41: Required Reusable Workflows

> Create an organization-owned reusable workflow and require it for a repository cohort through approved required-workflow or ruleset controls.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + permission to manage repository workflows and rulesets. |
| App | Provisioned workflow library and consumer repositories |
| EMU compatible | yes |

## Customer delivery target

- Objective: make baseline CI and security checks consistent without copying workflow logic across repositories.
- Delivery target: one reusable workflow library and one authorized consumer cohort with a required gate.
- Safety boundary: organization rulesets or required-workflow controls change only after owner approval.
- Evidence: reusable workflow version, pinned-action review, consumer and required-gate evidence, exceptions, and rollout plan.
- Owner: developer experience or platform engineering.
- Next decision: expand the required gate to the next repository cohort.

## Prerequisites

- Org owner or repository admin rights for the selected cohort.
- `gh >= 2.x`, `git`, `jq`.
- Agreement on the checks that must run for every protected repository.

## Scenario

Teams use different CI workflows, so baseline checks vary and audits take longer. Publish a reusable workflow and prove that one repository can call it. Then configure an approved control that requires the workflow before merge.

> [!IMPORTANT]
> Do not use setup automation to enforce organization-wide rules. Required workflows and rulesets can block production teams, so configure them manually for the approved cohort only.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch41 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch41 -Org <org>
```

Setup creates:

- `ghec-ch41-workflow-library` with `.github/workflows/baseline.yml` using `workflow_call`.
- `ghec-ch41-consumer-service` with a caller workflow and sample source file.
- No org-wide rulesets or required-workflow settings.

> [!IMPORTANT]
> A private workflow-library repository is not callable by other private repositories until its Actions access is shared. Before validating the consumer, open `ghec-ch41-workflow-library` → Settings → Actions → General → **Access** and allow repositories in the organization to use its reusable workflows. Record that access decision as evidence.

## Tasks

### Part A — Publish the reusable workflow

1. Review the seeded reusable workflow for least-privilege `permissions` and pinned third-party actions.
2. Decide the versioning model: branch, tag, release, or SHA.
3. Configure Actions **Access** on `ghec-ch41-workflow-library` so the approved consumer repository can call the private reusable workflow.
4. Record owners, review cadence, access scope, and compatibility promises.

### Part B — Validate a consumer

5. Update the consumer caller to reference the approved version.
6. Open a pull request that changes sample code or docs.
7. Confirm the reusable workflow runs and returns a required status context.

### Part C — Require the gate

8. Choose the enforcement mechanism available in the customer tenant: required workflows or repository rulesets.
9. Configure the requirement manually for the authorized repository cohort.
10. Verify a pull request cannot merge while the required reusable workflow is failing or missing.

### Part D — Govern exceptions and rollout

11. Define an exception path for repositories that cannot adopt the workflow.
12. Record how library changes are communicated and how breaking changes are prevented.
13. Capture before/after evidence and next cohort decision.

## Validation / Definition of Done

- [ ] Reusable workflow is versioned, least-privilege, and owner-approved.
- [ ] The private workflow-library repository allows the approved consumer scope to call its reusable workflows.
- [ ] Consumer repository calls the reusable workflow successfully.
- [ ] Required workflow or ruleset control is configured by the participant for the approved cohort.
- [ ] Pull request evidence shows the gate blocks merge until passing.
- [ ] Exception and rollout records exist with owners and review dates.
- [ ] Adoption handover names the library owner and next repository cohort.

## Operational extensions

- Add CodeQL, dependency review, or artifact attestation checks to the reusable workflow.
- Publish a changelog and deprecation policy for workflow versions.
- Use repository custom properties to target rulesets by repository class.

## Reference links

- Reusing workflows — https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
- Required workflows — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
- Organization rulesets — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Security hardening for GitHub Actions — https://docs.github.com/en/actions/reference/security/secure-use
