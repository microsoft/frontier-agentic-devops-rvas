# Ch50: License Compliance Workflow

> Deliver a repository-level license compliance workflow: dependency inventory, review checkpoint, exception intake, and owner-approved rollout decisions.

| | |
|---|---|
| Track | Security |
| Difficulty | Advanced |
| Duration | ~4 hrs total, multi-session |
| Minimum input | An org + repository administrator rights. |
| App | Provisioned license compliance repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Objective: make open source license risk visible before dependency changes merge.
- Delivery target: an approved repository or cohort with dependency manifests and compliance evidence.
- Safety boundary: enterprise or organization license policies and required checks affect many teams. Setup does not change them; enforce policy only with owner and legal approval.
- Evidence: dependency inventory, dependency-review results, exception decisions, expiry dates, remediation owners, and policy rollout decision.
- Owner: the open source program, legal, security, or platform team.
- Next decision: select the next repository cohort or approve enforcement controls.

## Prerequisites

- A GitHub Enterprise Cloud organization and repository administrator rights.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch50 --org <org>` (least privilege; for this activity: `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Dependency graph must be available for live repository inventory evidence. If it is unavailable, use manifests or a customer-approved SBOM as fallback evidence.

## Customer delivery objectives

You will:

- Define allowed, review-required, and prohibited license categories.
- Capture dependency inventory evidence from dependency graph, manifests, or SBOMs.
- Add a pull-request checkpoint for dependency/license changes.
- Create a license exception intake path with owner, expiry, legal/security decision, and remediation plan.
- Record which high-impact policy settings require explicit approval before enforcement.

## Scenario

A customer adds dependencies quickly, but license reviews happen late or inconsistently. Build a workflow that inventories current dependencies, classifies license risk, reviews changes before merge, and records exceptions. Legal and platform owners must be able to run it after handover.

> [!IMPORTANT]
> Choose the target before setup
>
> Start with an authorised customer repository or cohort that has real dependency manifests. Complete the work there and keep the evidence.
>
> - Have a candidate? Use the real repository wherever this guide names `ghec-ch50-license-compliance-workflow`. Skip setup.
> - No suitable one? Use the fallback below: a seeded repository with sample manifests, compliance docs, issue form, labels, and Dependabot scaffold.
>
> Record the selected target, compliance owner, legal/security approver, exception owner, policy boundary, and next action.

## Sample test repository or environment (when tenant delivery is constrained)

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch50 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch50 -Org <org>
```

Setup is idempotent and creates only these namespaced artifacts. Teardown accepts only the `ghec-ch50-*` prefix.

- `ghec-ch50-license-compliance-workflow` with sample `package.json`, `requirements.txt`, and compliance documentation.
- `.github/dependabot.yml` and `.github/ISSUE_TEMPLATE/license-exception.yml` scaffolds.
- Labels for `license: review`, `license: approved`, `license: exception`, and `license: blocked`.
- A sample license exception issue.
- Printed dependency graph, dependency review, and policy inspection commands; setup does not mutate enterprise or organization policies.

## Tasks

### Part A — Capture dependency inventory

1. Snapshot repository manifests and dependency graph evidence:
   ```bash
   gh api repos/<org>/ghec-ch50-license-compliance-workflow/dependency-graph/sbom --jq '.sbom.packages[]? | {name, versionInfo, licenseConcluded}'
   ```
2. If SBOM data is unavailable, capture manifest evidence:
   ```bash
   gh api repos/<org>/ghec-ch50-license-compliance-workflow/contents/package.json --jq '.download_url'
   gh api repos/<org>/ghec-ch50-license-compliance-workflow/contents/requirements.txt --jq '.download_url'
   ```
3. Record inventory source, timestamp, repository, and known blind spots such as private registries or generated dependencies.

### Part B — Define the license policy

4. Complete `docs/license-compliance-policy.md` or the customer register with:
   - allowed license families
   - review-required license families
   - prohibited license families
   - decision owner and legal/security approver
   - exception expiry and remediation rules
   - review cadence and evidence location
5. Identify enterprise or organization policy settings that need owner approval before enforcement. Do not change them without explicit approval.

### Part C — Add dependency review checkpoint

6. Review `.github/dependabot.yml` and decide the update cadence and package ecosystems.
7. Add dependency review guidance to the pull request process. If using GitHub Actions dependency review, configure it in the customer repository after approval.
8. For a sample pull request, compare dependency changes and capture license findings:
   ```bash
   gh api repos/<org>/ghec-ch50-license-compliance-workflow/dependency-graph/compare/main...<branch>
   ```

### Part D — Operate exception intake

9. Open a license exception issue using the provided template.
10. Capture package, version, license, usage, business owner, approver, expiry date, and remediation path.
11. Apply `license: exception` for approved exceptions or `license: blocked` for rejected requests.
12. Link the exception back to the dependency change that needs it.

### Part E — Handover and rollout

13. Record policy owner, exception approver, repository cohort, and next review date.
14. Decide the next enforcement step: advisory dependency review, required check, repository ruleset, or enterprise/org policy rollout.

## Validation / Definition of Done

- [ ] License policy identifies allowed, review-required, and prohibited license families with owner, exception path, expiry rules, and review cadence.
- [ ] Dependency inventory evidence is captured from dependency graph, manifests, or approved SBOM source.
- [ ] A dependency review or equivalent pull-request checkpoint is documented for license changes.
- [ ] A license exception issue records package, license, usage, decision, expiry, and remediation path.
- [ ] Enterprise or organization policy changes are explicit participant steps and were not performed by setup.
- [ ] Adoption handover names the compliance owner, legal/security approver, next repository cohort, and review date.

## Operational extensions

- Configure the Dependency Review GitHub Action after policy approval.
- Add code owners for dependency manifests.
- Feed approved exceptions into a centralized governance register.

## Reference links

- About the dependency graph — https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph
- About dependency review — https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review
- Configuring dependency review — https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/configuring-dependency-review
- Configuring Dependabot version updates — https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates
- Dependency review REST API — https://docs.github.com/en/rest/dependency-graph/dependency-review
