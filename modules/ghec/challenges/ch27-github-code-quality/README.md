# Ch27 - GitHub Code Quality: Code Health & Coverage

> Deliver GitHub Code Quality for an authorized customer repository: establish a Code Health baseline, publish coverage from CI, act on pull-request findings, and make a controlled organization rollout decision.

| | |
|---|---|
| Track | Security |
| Difficulty | Intermediate |
| Duration | ~5 hrs total, multi-session |
| Minimum input | An authorized customer repository in a GitHub Team or Enterprise Cloud organization with Code Quality available |
| App | Customer repository |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: give delivery teams actionable, native GitHub evidence for maintainability, reliability, and test coverage before changes merge.
- Customer-tenant target: an authorized repository's Code Quality configuration, CI coverage upload, PR feedback, threshold decision, and rollout evidence.
- Approval and safety boundary: enable Code Quality and change workflow permissions or rulesets only with the repository or organization owner's approval. Use a controlled pilot repository if production rollout is not yet authorized.
- Records to keep: initial Code Health scores, workflow and coverage evidence, pull-request finding decision, threshold decision, and organization pilot proposal.
- Adoption owner / handover: the repository owner owns the repository configuration; the engineering and platform owners agree the triage and rollout cadence.
- Next action and owner: approve the pilot cohort, extend the rollout, or document the blocker and rollback decision.

## Prerequisites

- A GitHub Team or GitHub Enterprise Cloud organization where GitHub Code Quality is available. If the organization belongs to an enterprise, confirm the enterprise owner has allowed the product.
- An authorized repository with GitHub Actions enabled and at least one Code Quality-supported language.
- A test suite that can emit a Cobertura XML report. `ghec-ch04` is a useful preparation activity when the repository does not yet have CI, but it is not required for this session.
- Repository administrator or organization owner access, plus `gh >= 2.x`, `git`, and `jq`.
- A named customer repository, accountable repository owner, and authorization to change its Code Quality, workflow, and merge-control configuration.

> [!IMPORTANT]
> Use an approved customer target
>
> GitHub Code Quality should be evaluated against a repository the customer plans to operate. Do not treat CodeQL security scanning, a generic lint job, or an agent review workflow as a substitute: this activity configures the GitHub Code Quality product.

## Scenario

A customer team has test runs and code review, but cannot see whether a pull request lowers coverage or introduces reliability and maintainability problems until they become technical debt. You will enable GitHub Code Quality, establish a Code Health baseline, upload coverage from the team's own CI workflow, and use a focused pull request to agree how findings should be handled before the organization pilots the product more widely.

## Tasks

### Part A - Confirm product readiness and ownership

1. Confirm the selected repository uses a language supported by Code Quality and that GitHub Actions is enabled. Record the repository, default branch, repository owner, engineering owner, and approval boundary.
2. Confirm product availability in the customer tenant. If the organization belongs to an enterprise, ask the enterprise owner to allow Code Quality before attempting repository enablement.
3. Identify the existing test command and the coverage tool for the repository. It must produce Cobertura XML; choose a converter when the current tool only creates another format.
4. Record whether the team has Copilot licenses and AI features enabled. This affects optional Copilot review findings, not the rules-based Code Quality baseline.

### Part B - Enable Code Quality and record the baseline

5. In the selected repository, go to Settings -> Security -> Code quality and select Enable code quality.
6. Review the detected languages and runner configuration. Disable only languages the customer has explicitly excluded; save the configuration.
7. Wait for the initial analysis, then open Security and quality -> Code quality -> Standard findings. Record:
   - maintainability score;
   - reliability score;
   - number of Error, Warning, and Note findings;
   - any generated-code, test-code, or repository-context factor that affects interpretation.
8. Distinguish this result from security code scanning: Code Quality assesses reliability and maintainability, while `ghec-ch12` covers security vulnerabilities and data-flow triage.

### Part C - Publish code coverage from CI

9. Update the customer CI workflow so tests generate a Cobertura XML report on pushes to the default branch and pull requests targeting it.
10. Add the least-privilege permission and upload step after tests. Replace the placeholders with the real report path, language, and an optional label:

```yaml
permissions:
  contents: read
  code-quality: write

# Run this after the test command produces a Cobertura XML report.
- name: Upload coverage report
  if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository
  uses: actions/upload-code-coverage@v1
  with:
    file: COVERAGE-FILE-PATH.xml
    language: LANGUAGE
    label: code-coverage/CI
```

11. Push the workflow change to a branch and open a pull request. Confirm the workflow runs on both the PR and default branch; Code Quality needs both for the branch comparison.
12. Confirm a comment from `github-code-quality[bot]` reports aggregate coverage and the per-file coverage delta. If no comment appears, first verify the report is valid Cobertura XML, the upload step ran, and `code-quality: write` is present.

### Part D - Triage quality feedback in a pull request

13. Use a focused pull request that changes supported-language code. In Files changed, identify whether each comment comes from `github-code-quality[bot]` (rules-based) or Copilot (AI-powered).
14. For at least one rules-based finding, read the severity and choose one action:
    - fix it manually;
    - review and commit an Autofix only when the patch is correct for the customer codebase; or
    - dismiss it with a specific rationale when the finding is intentional or does not apply.
15. Review optional Copilot findings separately. They do not carry the Code Quality Error/Warning/Note severity and do not independently satisfy a Code Quality merge gate. Do not merge any generated patch without normal pull-request review.
16. Return to Standard findings and record the before/after effect on the backlog and scores. Scores must be interpreted in repository context; generated code and small supported-language footprints can skew them.

### Part E - Make the merge and rollout decision

17. With the customer owner, decide whether Code Quality is informational during the pilot or whether a severity threshold should block pull requests. If a gate is approved, configure the native Code Quality threshold in the applicable ruleset.
18. Demonstrate the decision on the test pull request: a finding at or above the selected threshold blocks merge until it is fixed or dismissed; a finding below it does not. If the customer chooses no gate, document why and set the review cadence instead.
19. At the organization level, use Code Quality's native repository access targeting to select a small authorized pilot cohort. Do not substitute a generic repository ruleset for product enablement.
20. Record the pilot cohort, repository owners, cost/license review, expected baseline date, success measures, opt-out or rollback criteria, and decision date.

### Part F - Control-catalogue evidence

Use `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md` for control
terminology; do not copy catalogue rows into this guide. Contribute to the
existing customer register:

- `QLT-CODE-QUALITY-GATES` — inspect Code Quality availability and the effective threshold or review-cadence setting → record `approved pilot` → attach baseline scores, coverage-upload proof, PR-gate result, and pilot decision as objective evidence.

## Validation / Definition of Done

You are done when ALL of the following are true:

- [ ] Code Quality is enabled on an authorized customer repository, with chosen languages and runner configuration recorded.
- [ ] Maintainability and reliability baseline scores plus the Standard findings backlog were reviewed in repository context.
- [ ] CI creates a Cobertura XML report and uploads it using only `contents: read` and `code-quality: write`.
- [ ] A pull request displays Code Quality coverage feedback with aggregate and per-file comparison data.
- [ ] A rules-based Code Quality finding was fixed or dismissed with a reviewable decision; any Autofix was reviewed before commit.
- [ ] The customer decided and evidenced whether a native Code Quality severity threshold blocks merges.
- [ ] An organization pilot proposal identifies the selected cohort, owners, measures, licensing/cost review, and rollout or rollback decision.
- [ ] The existing customer register contains `QLT-CODE-QUALITY-GATES` with the inspected effective setting, `approved pilot` status, and the required objective evidence.
- [ ] Adoption handover: the customer repository owner, platform owner, triage cadence, and next authorized action are recorded.

## Operational extensions

- Enable a second authorized repository through native organization targeting and compare its baseline after the first analysis completes.
- Configure and prove a coverage threshold only after the team agrees how generated code, test scope, and temporary coverage changes will be handled.
- Use the product API to export Code Quality status for the pilot cohort into the customer’s engineering-health reporting process.

## Reference links

- [About GitHub Code Quality](https://docs.github.com/en/code-security/concepts/about-code-quality)
- [Enabling GitHub Code Quality](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/enable-code-quality)
- [Setting up code coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-up-code-coverage)
- [Interpreting Code Quality results](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/interpret-results)
- [Preventing code quality issues from reaching the default branch](https://docs.github.com/en/code-security/tutorials/improve-code-quality/catch-issues-before-merge)
- [Metrics and scores reference](https://docs.github.com/en/code-security/reference/code-quality/metrics-and-ratings)
