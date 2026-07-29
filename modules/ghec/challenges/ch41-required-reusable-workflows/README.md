# Ch41 — Required Reusable Workflows

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

- Customer objective: make baseline CI/security checks consistent across repositories without copy-pasting workflow logic.
- Customer-tenant target: one reusable workflow library and one authorized consumer cohort with a required gate.
- Approval and safety boundary: organization rulesets or required-workflow controls are explicit participant changes after owner approval.
- Records to keep: reusable workflow version, pinned action review, consumer evidence, required gate evidence, exceptions, and rollout plan.
- Adoption owner / handover: developer experience or platform engineering owns the library and versioning model.
- Next action and owner: expand the required gate to the next repository cohort.

## Prerequisites

- Org owner or repository admin rights for the selected cohort.
- `gh >= 2.x`, `git`, `jq`.
- Agreement on the checks that must run for every protected repository.

## Scenario

Teams have different CI workflows, so baseline checks are inconsistent and hard to audit. You will publish a reusable workflow, prove one repository can call it, then configure an approved control that requires the workflow before merge.

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

## Tasks

### Part A — Publish the reusable workflow

1. Review the seeded reusable workflow for least-privilege `permissions` and pinned third-party actions.
2. Decide the versioning model: branch, tag, release, or SHA.
3. Record owners, review cadence, and compatibility promises.

### Part B — Validate a consumer

4. Update the consumer caller to reference the approved version.
5. Open a pull request that changes sample code or docs.
6. Confirm the reusable workflow runs and returns a required status context.

### Part C — Require the gate

7. Choose the enforcement mechanism available in the customer tenant: required workflows or repository rulesets.
8. Configure the requirement manually for the authorized repository cohort.
9. Verify a pull request cannot merge while the required reusable workflow is failing or missing.

### Part D — Govern exceptions and rollout

10. Define an exception path for repositories that cannot adopt the workflow.
11. Record how library changes are communicated and how breaking changes are prevented.
12. Capture before/after evidence and next cohort decision.

## Validation / Definition of Done

- [ ] Reusable workflow is versioned, least-privilege, and owner-approved.
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
- Security hardening for GitHub Actions — https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions
