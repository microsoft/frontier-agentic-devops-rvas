# Approved regression-test pilot

**Session outcome:** One maintainer-approved issue becomes a test-only PR. The
test passes on current code and fails for the known regression. An independent
reviewer checks the result.

This is a core alternative to the documentation pilot. Start directly
after [setup](../00-setup/README.md) in a customer repository with an existing
test runner. You do not need a discovery agent or a scheduled pipeline.

## Choose an approved issue

A maintainer records the affected behavior, expected result, test path, and
actual test command. Identify a known bad revision or an approved, isolated
mutation that the test must catch. Keep production fixes outside this test-only
PR.

Create a dedicated approval label, such as `agent-test-approved`. Before the
model starts, a trusted job must fetch the selected open issue and its approval
event. Check that the label is present and a maintainer with an approved role
applied it. Alternatively, require both the label and an issue author whose
association is explicitly allowed, such as `OWNER`, `MEMBER`, or `COLLABORATOR`.
Check current write permission when the team's policy requires it.
Association alone is not proof of write access.

Validate these facts through API metadata in a
[trusted pre-agent step](https://github.github.com/gh-aw/reference/steps-jobs/).
The model must run only if those checks pass. Do not trust an issue body saying
"approved" or let a triage bot add the approval label. Recheck approval and the
issue state immediately before publishing.

**Stop if there is no approved issue.** Do not scan for a fallback task.
Missing approval evidence must stop inference. API errors must fail visibly.

## Implement one test

Use the [test pilot starter](../../resources/examples/daily-test-improver.md)
and [approval guard](../../resources/examples/pilot-guard.cjs):

- Use `workflow_dispatch` with one issue number; keep the schedule disabled.
- Limit editing to the approved test files. Give the agent read-only GitHub
  access and only the tools needed to run this repository's tests.
- Permit one `create-pull-request` output. Link the approved issue and use its
  ID to check for duplicates. Skip work if an implementation PR already exists.
- Set `create-pull-request.allowed-files` to the approved test paths.
  The writer rejects any other changed file. Keep `protected-files: blocked`
  and `fallback-as-issue: false`.

Compile with `gh aw compile daily-test-improver`. Inspect the generated
permissions and approval checks, then deploy through review.

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
Markdown prompt. Keep the allowlist limited to the agreed test files.
The supplied guard verifies who applied `agent-test-approved`, checks their
current write access, and checks for an existing PR. A post-agent recheck loads
the guard from the trusted workflow revision, rather than the agent's edits.

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

The starter uses `node --test`; replace it if needed. Have the maintainer apply
the approval label after documenting the behavior and bad-state check.

```bash
gh aw compile daily-test-improver
```

Review and merge the source, guard, and lock file. Then dispatch from the
default branch, using the configured issue number:

```bash
gh workflow run daily-test-improver.lock.yml -f issue=42
gh run list --workflow daily-test-improver.lock.yml --limit 5
```

The result should be one draft PR that changes only the approved test file,
links the issue, and records the actual test result. Open its diff before
running the bad-state check below.

## Prove the regression

Run the named test command with the new test on current code. In an isolated
environment without credentials, apply that same test to the known bad revision
or approved mutation and run the same command. It must fail at the intended
assertion, not because dependencies or imports are missing. Restore the good
state and confirm it passes again.

Attach command outputs and the tested revisions to the PR. Production changes
used to check that the test fails must not enter the PR. Have an independent
reviewer confirm the assertion catches the issue, then complete the
[shared acceptance check](../../setup.md#pilot-acceptance).

Test an unapproved issue and an empty selection. Both must skip the model and
create nothing. Rerun the approved issue and confirm there is no duplicate PR.

## Optional discovery later

If maintainers need help finding test gaps, add a separate read-only discovery
workflow that proposes an issue with code evidence. A maintainer must approve it
before implementation starts. Scheduling the workflows one hour apart does not
establish approval. Neither workflow may grant it.
