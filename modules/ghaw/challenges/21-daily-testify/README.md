# Approved regression-test pilot

**Session outcome:** One maintainer-approved issue becomes a test-only PR. The
test passes on current code and fails for the known regression. An independent
reviewer approves it. This session changes tests only. For a doc-correction PR,
see [daily-doc-updater](../19-daily-doc-updater/README.md).

Start right after [setup](../00-setup/README.md) in a customer repository that
already has a test runner.

## Choose an approved issue

Agree on the affected behavior, expected result, test path, and test command.
Identify a known bad revision, or an approved, isolated mutation, that the
test must catch. Keep production fixes out of this PR.

Create a dedicated approval label, such as `agent-test-approved`. The approval
guard, a [trusted pre-agent step](https://github.github.com/gh-aw/reference/steps-jobs/),
works as described in [daily-doc-updater](../19-daily-doc-updater/README.md#build-the-pilot):
it checks the label and who applied it before the model runs, then rechecks
before publishing. Don't trust an issue body that says "approved".

**Stop if there's no approved issue.** Don't look for a fallback task.

## Implement one test

Use the [test pilot starter](../../resources/examples/daily-test-improver.md)
and [approval guard](../../resources/examples/pilot-guard.cjs):

- Use `workflow_dispatch` with one issue number; keep the schedule disabled.
- Limit editing to the approved test files. Give the agent read-only GitHub
  access and only the tools needed to run this repository's tests.
- Permit one `create-pull-request` output that links the approved issue. Skip
  work if a PR for it already exists.
- Set `create-pull-request.allowed-files` to the approved test paths. Keep
  `protected-files: blocked` and `fallback-as-issue: false`.

## Copy and run the starter

From the customer checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/workflows
cp "$CURRICULUM/modules/ghaw/resources/examples/daily-test-improver.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/pilot-guard.cjs" .github/workflows/
node --test "$CURRICULUM/modules/ghaw/resources/examples/pilot-guard.test.cjs"
```

Replace `42` in `APPROVED_ISSUE` and both PR prefixes with the chosen issue.
Replace `test/approved-regression.test.js` in both `allowed-files` and the
Markdown prompt. Have a maintainer apply `agent-test-approved` after
documenting the behavior and the bad-state check.

Use this prompt to adapt the runtime and assertion:

```text
Customize daily-test-improver.md for issue <number> and test file <path>.
The expected behavior is <behavior>. The test command is <command>.
The known bad revision or approved mutation is <revision or change>.
Update the fixed issue, both PR prefixes, allowed-files, tool permissions,
and runtime prompt together. Add only the runtime/dependency setup required
by this repository. Preserve both approval checks and the test-only write policy.
Compile the workflow. Do not deploy, dispatch, or change production code.
```

The starter uses `node --test`; replace it if needed. Compile, review, and merge
the source, guard, and lock file. Then dispatch from the default branch:

```bash
gh aw compile daily-test-improver
gh workflow run daily-test-improver.lock.yml -f issue=42
gh run list --workflow daily-test-improver.lock.yml --limit 5
```

The result should be one draft PR that changes only the approved test file,
links the issue, and records the actual test result.

## Prove the regression

Run the test command with the new test on current code. In an isolated
environment without credentials, apply the same test to the known bad revision
or approved mutation and run the same command. It must fail at the intended
assertion, not on missing dependencies or imports. Restore the good state and
confirm it passes again.

Attach the command outputs and tested revisions to the PR. Have an independent
reviewer confirm the assertion catches the issue, then complete the
[shared acceptance check](../../setup.md#pilot-acceptance). Rerun the approved
issue and confirm there's no duplicate PR.

## Optional

- Test an unapproved issue and an empty selection. Both must skip the model and create nothing.
- Add a separate read-only discovery workflow that proposes issues with code evidence. A maintainer must approve each one before implementation starts.
