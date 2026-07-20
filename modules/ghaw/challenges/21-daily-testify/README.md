**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 60 minutes
**Tier:** Bonus

---

## Production outcome

Build a governed test-quality pipeline for one repository your customer delivery team owns:

1. **Daily Testify** reviews the test suite and opens a small number of specific `test-improvement` issues.
2. A team member reviews those issues.
3. **Daily Test Improver** reads approved issues and opens one focused, test-only pull request.
4. A maintainer reviews and merges or closes the pull request.

The workflows are deliberately separate. Analysis can create issues, but it cannot write code. Code generation is limited to a reviewable pull request, using the reviewed issue as its contract.

> [!IMPORTANT]
> **Use a real repository**
>
> Choose a repository in an organization you control with established test conventions, a test owner, and a maintainer who will review the proposed pull requests. Configure the workflows for its language, framework, test directories, and quality bar. Use the sample repository only when no suitable customer repository is available.

## What you'll build

| Workflow | Schedule | Safe output | Purpose |
|---|---|---|---|
| Daily Testify | 09:00 | `create-issue` | Finds concrete test-quality gaps and creates up to three actionable issues. |
| Daily Test Improver | 10:00 | `create-pull-request` | Reads reviewed `test-improvement` issues and opens at most one test-only pull request. |

The one-hour offset lets Testify create issues before the Improver evaluates them. The issue label and issue-body format are the contract between the workflows.

## Build the pipeline

1. Install [`gh aw`](https://github.com/github/gh-aw) if needed:
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. Add the Testify workflow:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/daily-testify-uber-super-expert.md
   ```

3. Adapt Testify to the repository:
   - Define the test framework, test directories, quality standards, and relevant anti-patterns.
   - Require every issue to name the file, function or test, exact gap, and a one-sentence fix suggestion.
   - Apply the `test-improvement` label and limit the workflow to three issues per run.
   - Keep `safe-outputs: create-issue`; it must not create pull requests.

4. Add the Test Improver workflow:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/daily-test-improver.md
   ```

5. Adapt Test Improver to the repository:
   - Read open, reviewed issues labelled `test-improvement` before doing any general gap scan.
   - Specify the test framework and supported assertion patterns.
   - Restrict changes to test files; do not modify production source files.
   - Open one pull request per run, with no more than three new test cases.
   - Keep `safe-outputs: create-pull-request` and configure the pull-request reviewer.

6. Compile both workflows:
   ```bash
   gh aw compile daily-testify-uber-super-expert
   gh aw compile daily-test-improver
   ```

7. Run Testify manually. Review one created issue before allowing the Improver to consume it.

8. Dry-run Test Improver:
   ```bash
   gh aw run daily-test-improver --dry-run
   ```
   Confirm that the proposed test is valid for the repository's framework and actually proves behavior rather than merely raising coverage.

## Expected workflow contracts

### Daily Testify

```markdown
---
on:
  schedule:
    - cron: "0 9 * * *"
  workflow_dispatch: {}

permissions:
  issues: write
  contents: read

safe-outputs:
  create-issue: {}

engine: copilot
---
```

The prompt must name the repository's test standards and require issues to use the `test-improvement` label. It must limit output to specific, actionable gaps.

### Daily Test Improver

```markdown
---
on:
  schedule:
    - cron: "0 10 * * *"
  workflow_dispatch: {}

permissions:
  contents: write
  pull-requests: write
  issues: read

safe-outputs:
  create-pull-request: {}

tools:
  github:
    toolsets: [issues]

engine: copilot
---
```

Its prompt must first select a reviewed `test-improvement` issue, write only the associated tests, and link the pull request to that issue. If no suitable issue exists, it may identify one bounded coverage gap; it must still open no more than one pull request.

## Success criteria

- [ ] Both workflow files have valid frontmatter and compile successfully.
- [ ] Testify uses `create-issue` only, creates no more than three issues per run, and labels them `test-improvement`.
- [ ] Each Testify issue identifies a real file, function or test gap, and an actionable fix.
- [ ] Test Improver runs after Testify, reads the reviewed issue, and uses `create-pull-request`.
- [ ] Test Improver changes tests only, opens at most one focused pull request, and links it to the issue.
- [ ] The proposed test is syntactically valid and demonstrates behavior, an error path, or an edge case.
- [ ] A named maintainer reviews both the issue and the pull request before adoption.

## Common blockers

| Symptom | Fix |
|---|---|
| Testify produces vague issues | Require the exact file, function, gap, and proposed test behavior in every issue. |
| Too many issues or pull requests | Limit Testify to three issues and Test Improver to one pull request per run. |
| Test Improver changes application code | State that it may modify only the configured test directories. |
| Generated tests pass trivially | Require a concrete expected value, side effect, error condition, or edge case. |
| The Improver cannot act on an issue | Improve the Testify issue contract before rerunning the pipeline. |

