# Ch27: GitHub Code Quality: Code Health and coverage

**Session outcome:** Your approved repository runs GitHub Code Quality and uploads CI coverage. A merged pull request shows a rules-based finding that a reviewer fixed or dismissed with a reason.

## Prerequisites

- A GitHub Team or GitHub Enterprise Cloud organization where GitHub Code Quality is enabled. If the organization belongs to an enterprise, the enterprise owner must allow the product.
- A customer repository with GitHub Actions enabled, a Code Quality-supported language, and a test suite that can emit a Cobertura XML report.
- Repository administrator or organization owner access, plus `gh >= 2.x`, `git`, and `jq`.

> [!IMPORTANT]
> Use a repository the customer plans to keep. CodeQL, a generic lint job, or an agent review is not GitHub Code Quality.

**Blocked:** if the product isn't available or the owner doesn't allow it, stop and note the blocker in the adoption issue. The session isn't complete.

## Tasks

### Part A: Enable Code Quality

1. Go to **Settings → Security → Code quality** and select **Enable code quality**.
2. Review the detected languages and runner configuration. Disable only languages the customer excluded, then save.
3. Wait for the initial analysis, then open **Security and quality → Code quality → Standard findings**. Check that scores and findings appear.

Code Quality assesses reliability and maintainability, not security. The [CodeQL activity](../../../ghas/challenges/03-admin-codeql-deployment-data-flow-autofix/README.md) covers vulnerabilities.

### Part B: Publish code coverage from CI

1. Update the CI workflow so tests produce a Cobertura XML report on pushes to the default branch and on pull requests targeting it. If the tool emits another format, add a converter.
2. Add the permission and upload step after the tests. Replace the placeholders with the real report path and language:

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

3. Open a pull request with the workflow change. Confirm the workflow runs on the PR and on the default branch after merge. Code Quality needs both to compare branches.
4. Confirm `github-code-quality[bot]` comments with aggregate coverage and the per-file delta. If there's no comment, check that the report is valid Cobertura XML, the upload step ran, and `code-quality: write` is set.

### Part C: Dispose of one finding in a merged PR

1. Open a focused pull request that changes supported-language code. In **Files changed**, find a comment from `github-code-quality[bot]` (rules-based).
2. Pick one action:
   - fix it manually;
   - review and commit an Autofix, only if the patch is right for this codebase; or
   - dismiss it with a specific reason.
3. Copilot findings, if present, have no severity and can't satisfy a Code Quality gate. Don't merge a generated patch without normal review.
4. Merge the PR after review. Check that the finding is closed or dismissed in **Standard findings**.

**Optional:** set a severity threshold in the ruleset so findings at or above it block merges. Use Code Quality's native threshold, not a generic ruleset.

## Reference links

- [About GitHub Code Quality](https://docs.github.com/en/code-security/concepts/about-code-quality)
- [Enabling GitHub Code Quality](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/enable-code-quality)
- [Setting up code coverage](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/set-up-code-coverage)
- [Interpreting Code Quality results](https://docs.github.com/en/code-security/how-tos/maintain-quality-code/interpret-results)
- [Preventing code quality issues from reaching the default branch](https://docs.github.com/en/code-security/tutorials/improve-code-quality/catch-issues-before-merge)
- [Metrics and scores reference](https://docs.github.com/en/code-security/reference/code-quality/metrics-and-ratings)
