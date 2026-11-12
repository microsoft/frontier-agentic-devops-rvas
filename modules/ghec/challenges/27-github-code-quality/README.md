# Ch27: GitHub Code Quality: Code Health and coverage

**Session outcome:** Your approved repository runs GitHub Code Quality, publishes CI coverage, and has a recorded Code Health baseline. A human reviewer used the pull request findings to decide whether to merge and whether to recommend a wider rollout.

## Prerequisites

- A GitHub Team or GitHub Enterprise Cloud organization where GitHub Code Quality is available. If the organization belongs to an enterprise, check that the enterprise owner allowed the product.
- An authorized repository with GitHub Actions enabled and at least one Code Quality-supported language.
- A test suite that can emit a Cobertura XML report. If the repository has no CI yet, `ghec-ch04` is good preparation, but you don't need it.
- Repository administrator or organization owner access, plus `gh >= 2.x`, `git`, and `jq`.
- A named customer repository, its accountable owner, and permission to change its Code Quality, workflow, and merge-control settings.

> [!IMPORTANT]
> Use an approved customer target
>
> Test GitHub Code Quality on a repository the customer plans to use. CodeQL security scanning, a generic lint job, or an agent review workflow is not a substitute for the GitHub Code Quality product.

## Scenario

A customer team runs tests and reviews code, but can't see coverage, reliability, or maintainability changes on a pull request. Enable GitHub Code Quality, set a Code Health baseline, upload coverage from CI, and use one focused pull request to decide how to handle findings before a wider pilot.

## Tasks

### Part A: Confirm product readiness and ownership

1. Confirm the selected repository uses a language supported by Code Quality and that GitHub Actions is enabled. Record the repository, default branch, repository owner, engineering owner, and what's approved.
2. Confirm Code Quality is available in the customer tenant. If the organization belongs to an enterprise, ask the enterprise owner to allow it before you enable it on the repository.
3. Identify the existing test command and the coverage tool for the repository. It must produce Cobertura XML. If it emits another format, pick a converter.
4. Record whether the team has Copilot licenses and AI features enabled. This affects the optional Copilot review findings, not the rules-based baseline.

### Part B: Enable Code Quality and record the baseline

5. In the selected repository, go to Settings -> Security -> Code quality and select Enable code quality.
6. Review the detected languages and runner configuration. Disable only languages the customer explicitly excluded, then save.
7. Wait for the initial analysis, then open Security and quality -> Code quality -> Standard findings. Record:
   - maintainability score;
   - reliability score;
   - number of Error, Warning, and Note findings;
   - any generated-code, test-code, or repository-context factor that affects interpretation.
8. Don't confuse this with security code scanning: Code Quality assesses reliability and maintainability. The [CodeQL deployment activity](../../../ghas/challenges/03-admin-codeql-deployment-data-flow-autofix/README.md) covers security vulnerabilities and data-flow analysis.

### Part C: Publish code coverage from CI

9. Update the customer CI workflow so tests generate a Cobertura XML report on pushes to the default branch and pull requests targeting it.
10. Add the permission and the upload step after the tests. Replace the placeholders with the real report path, the language, and an optional label:

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

11. Push the workflow change to a branch and open a pull request. Confirm the workflow runs on both the PR and the default branch. Code Quality needs both to compare branches.
12. Confirm a comment from `github-code-quality[bot]` reports aggregate coverage and the per-file coverage delta. If no comment appears, check that the report is valid Cobertura XML, the upload step ran, and `code-quality: write` is set.

### Part D: Triage quality feedback in a pull request

13. Use a focused pull request that changes supported-language code. In Files changed, note whether each comment comes from `github-code-quality[bot]` (rules-based) or Copilot (AI-powered).
14. For at least one rules-based finding, read the severity and choose one action:
    - fix it manually;
    - review and commit an Autofix, only if the patch is right for the customer codebase; or
    - dismiss it with a specific reason when the finding is intentional or doesn't apply.
15. Review the optional Copilot findings separately. They have no Error/Warning/Note severity and can't satisfy a Code Quality merge gate on their own. Don't merge a generated patch without normal pull request review.
16. Return to Standard findings and record how the backlog and scores changed. Read the scores in the repository's context: generated code, or very little supported-language code, can skew them.

### Part E: Make the merge and rollout decision

17. With the customer owner, decide whether Code Quality is informational during the pilot or whether a severity threshold should block pull requests. If a gate is approved, set the native Code Quality threshold in the ruleset.
18. Show the decision on the test pull request: a finding at or above the threshold blocks the merge until it's fixed or dismissed, and a finding below it doesn't. If the customer chooses no gate, document why and set a review cadence instead.
19. At the organization level, use Code Quality's native repository access targeting to pick a small, authorized pilot cohort. A generic repository ruleset doesn't enable the product.
20. Record the pilot cohort, repository owners, expected baseline date, success measures, and rollback criteria.

Keep the product analysis and the reviewed PR as [completion evidence](../../../README.md#completion-evidence). If Code Quality isn't available, record the next step in an accepted assessment. Don't present it as enabled.

## Reference links

- [About GitHub Code Quality](https://docs.github.com/en/code-security/concepts/about-code-quality)
- [Enabling GitHub Code Quality](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/enable-code-quality)
- [Setting up code coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-up-code-coverage)
- [Interpreting Code Quality results](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/interpret-results)
- [Preventing code quality issues from reaching the default branch](https://docs.github.com/en/code-security/tutorials/improve-code-quality/catch-issues-before-merge)
- [Metrics and scores reference](https://docs.github.com/en/code-security/reference/code-quality/metrics-and-ratings)
