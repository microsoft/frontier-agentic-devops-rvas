# Approved regression-test pilot

**Session outcome:** One maintainer-approved issue becomes a test-only PR. The
test passes on current code and fails for the known regression. An independent
reviewer checks the result.

This is a core alternative to the documentation pilot. Start right after
[setup](../00-setup/README.md) in a customer repository that already has a test
runner. You don't need a discovery agent or a schedule.

## Choose an approved issue

A maintainer records the affected behavior, expected result, test path, and the
test command. Identify a known bad revision, or an approved, isolated mutation,
that the test must catch. Keep production fixes out of this test-only PR.

Create a dedicated approval label, such as `agent-test-approved`. Before the
model starts, a trusted job must fetch the open issue and its approval event
and check that the label is present and was applied by a maintainer in an
approved role. Or require both the label and an issue author whose association
is explicitly allowed, such as `OWNER`, `MEMBER`, or `COLLABORATOR`. Check
current write permission if the team's policy requires it. Association alone
doesn't prove write access.

Verify these facts through API metadata in a
[trusted pre-agent step](https://github.github.com/gh-aw/reference/steps-jobs/).
The model runs only if the checks pass. Don't trust an issue body that says
"approved", and don't let a triage bot add the approval label. Recheck approval
and issue state right before publishing.

**Stop if there's no approved issue.** Don't look for a fallback task. Missing
approval evidence stops inference, and API errors must fail visibly.

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
permissions and approval checks, then merge through review.

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
current write access, and looks for an existing PR. A post-agent recheck loads
the guard from the trusted workflow revision, not from the agent's edits.

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

The starter uses `node --test`; replace it if needed. The maintainer applies
the approval label after documenting the behavior and the bad-state check.

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

Run the test command with the new test on current code. In an isolated
environment without credentials, apply the same test to the known bad revision
or approved mutation and run the same command. It must fail at the intended
assertion, not on missing dependencies or imports. Restore the good state and
confirm it passes again.

Attach the command outputs and tested revisions to the PR. Keep the code
changes that trigger the regression out of the PR. Have an independent reviewer
confirm the assertion catches the issue, then complete the
[shared acceptance check](../../setup.md#pilot-acceptance).

Test an unapproved issue and an empty selection. Both must skip the model and
create nothing. Rerun the approved issue and confirm there's no duplicate PR.

## Optional discovery later

If maintainers want help finding test gaps, add a separate read-only discovery
workflow that proposes an issue with code evidence. A maintainer must approve it
before implementation starts. Running the workflows an hour apart isn't
approval, and neither workflow may grant it.
