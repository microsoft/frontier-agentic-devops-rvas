# Ch44: Policy Drift Detection

> Deliver a repeatable drift check that compares repository reality to an approved policy baseline and records remediation decisions.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. |
| App | Provisioned baseline and drifted sample repositories |
| EMU compatible | yes |

## Customer delivery target

- Objective: spot repository governance drift before an audit or incident does.
- Delivery target: an approved baseline and a drift report for a repository cohort.
- Safety boundary: setup creates sample repositories only. Organization rulesets, default permissions, and other high-impact controls require explicit approval.
- Evidence: baseline contract, drift output, remediation or exception decisions, owner, and next automation review.
- Owner: platform governance or compliance.

## Prerequisites

- GitHub Enterprise Cloud organization with org-owner rights.
- Token scopes from `setup.sh doctor ch44 --org <org>` (`repo` + `read:org`).
- `gh >= 2.x`, `git`, and `jq`.

## Scenario

A baseline defines repository ownership, required files, labels, topics, and safe feature settings. Repositories drift from it over time. Define the baseline, detect the differences, and record remediation without silently applying broad organization policy.

## Sample setup

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch44 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch44 -Org <org>
```

Setup creates `ghec-ch44-policy-baseline` and `ghec-ch44-drifted-service`. The drifted repository intentionally misses some baseline files, labels, and topics. Setup does not create org rulesets or mutate org settings.

## Tasks

### Part A — Define the baseline

1. Define baseline checks: owner evidence, README, CODEOWNERS, issue template, PR template, labels, topics, visibility, issues enabled, and branch/ruleset expectations.
2. Inspect the baseline sample:
   ```bash
   gh repo view <org>/ghec-ch44-policy-baseline --json name,visibility,hasIssuesEnabled,repositoryTopics,description
   gh label list --repo <org>/ghec-ch44-policy-baseline --limit 100 --json name,color,description
   ```
3. Record severity and exception rules for each check.

### Part B — Detect drift

4. Compare the drifted repo to the baseline:
   ```bash
   gh repo view <org>/ghec-ch44-drifted-service --json name,visibility,hasIssuesEnabled,repositoryTopics,description
   gh label list --repo <org>/ghec-ch44-drifted-service --limit 100 --json name
   gh api repos/<org>/ghec-ch44-drifted-service/contents/.github/CODEOWNERS --silent || echo "missing CODEOWNERS"
   ```
5. Produce a drift report with pass/fail, severity, owner, remediation, exception, and next review date.
6. Decide what can be safely remediated now versus what needs approval.

### Part C — Remediate safely

7. Apply one safe remediation, such as adding a missing topic or label:
   ```bash
   gh repo edit <org>/ghec-ch44-drifted-service --add-topic policy-baseline
   gh label create "status: needs-triage" --repo <org>/ghec-ch44-drifted-service --color fbca04 --description "Needs initial triage"
   ```
8. For high-impact changes, record an approved exception or rollout ticket instead of changing settings during setup.
9. Optional: move the drift check into a scheduled workflow after the customer approves the automation identity.

### Part D — Handover

10. Store the baseline contract, latest drift report, and approved exceptions.
11. Name the drift check owner, review cadence, and next repository cohort.

## Validation / Definition of Done

- [ ] Baseline contract covers files, labels, topics, settings, owner evidence, and exceptions.
- [ ] At least two repositories are compared.
- [ ] Drift report lists severity, owner, remediation, exception, and next review.
- [ ] One safe remediation is applied or an approved exception is recorded.
- [ ] High-impact controls are explicitly approved or deferred with owner/date.
- [ ] Adoption handover names the drift detection owner and next automation decision.

## Reference links

- Repositories REST API — https://docs.github.com/en/rest/repos/repos
- Labels REST API — https://docs.github.com/en/rest/issues/labels
- Repository contents API — https://docs.github.com/en/rest/repos/contents
- Repository topics — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics
- Scheduled workflows — https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule
