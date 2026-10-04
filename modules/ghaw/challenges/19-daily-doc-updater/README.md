# Reviewed documentation correction

**Session outcome:** One PR corrects a customer documentation error in one file.
The correction cites the code that supports it. Checks pass, and an independent
reviewer records a decision.

This is a core pilot. Complete [setup](../00-setup/README.md), then choose an
issue about a real documentation error with a maintainer.
For example, a documented option may disagree with its implemented default.
Do not introduce a stale document just to make the agent produce a PR.

## Approve the work

Record the issue URL, one writable documentation file, and the source files
that establish the correct behavior. Agree on the actual validation command
and independent reviewer before running the workflow.

Start with `workflow_dispatch`, restricted to authorized maintainers. Set the
approved issue and write path in reviewed configuration. If the user selects
the issue at runtime, check it against a maintainer-controlled approval record
before invoking the model. Stop if the issue is not approved.

## Build the pilot

Use the [documentation starter](../../resources/examples/daily-doc-updater.md)
and [approval guard](../../resources/examples/pilot-guard.cjs). The starter is
manual and its Markdown body contains the agent's prompt.

The guard checks the configured issue, its approval label and the labeler's
current write permission. It writes `.pilot-context.json` with the issue and
base SHA. The agent reads the named source at that revision. Do not ask it to
invent behavior from prose alone.

Give the agent read-only GitHub permissions and only the local editing and
test tools needed for the task. Configure `create-pull-request` with `max: 1`
and the approved base branch. Use `allowed-files` on `create-pull-request` to enforce the one-file restriction
in the writer. Keep `protected-files: blocked` and disable fallback issues.
This is a writer policy, not merely a prompt instruction.

The prompt must correct only the documented mismatch and cite its code
evidence in the PR body. Before generating work, check for an existing PR using
the approved issue and target file as its key. Run one request at a time for
that key.
**If the documentation is already correct, do nothing.**

Compile with `gh aw compile daily-doc-updater`. Inspect the source and lock
file together, then deploy through the normal review process.

## Copy and customize

From the customer checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/workflows
cp "$CURRICULUM/modules/ghaw/resources/examples/daily-doc-updater.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/pilot-guard.cjs" .github/workflows/
node --test "$CURRICULUM/modules/ghaw/resources/examples/pilot-guard.test.cjs"
```

Replace issue `42` in `APPROVED_ISSUE`, `PR_PREFIX`, and `title-prefix` with the
approved issue number. Replace `docs/usage.md` in the allowlist and prompt,
and replace `src/options.js` with the source that proves the correction.
The guard rejects any different issue selected at runtime.

Have a maintainer create `agent-doc-approved` if it does not exist, then apply
it to the issue. The guard checks the label event; merely putting "approved"
in the issue body does not pass.

Use this customization prompt in Copilot Chat:

```text
Adapt daily-doc-updater.md for approved issue <number>, document <path>, and
source <path>. Update the fixed issue, both matching PR prefixes, file allowlist
and runtime prompt together. Use our actual validation command: <command>.
Configure only its required runtime and dependency setup.
Keep the approval guard before inference and the recheck after inference.
Keep PR publication restricted to the single document. Do not deploy or run it.
```

The sample uses Node's `node --test`. Replace it in both the tool allowlist and
prompt if your repository uses another check. If the approved file is a
protected root document such as `README.md`, use the documented
[`protected-files.exclude` exception](https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/#protected-files)
for that file only; keep the exact `allowed-files` entry.

```bash
gh aw compile daily-doc-updater
```

Review the generated jobs: failed approval checks must prevent inference or
publication, and the writer must enforce the file allowlist. Submit the source,
guard, and lock file through normal review. After merge:

```bash
gh workflow run daily-doc-updater.lock.yml -f issue=42
gh run list --workflow daily-doc-updater.lock.yml --limit 5
```

Replace `42` here too. Open the returned run in Actions and the draft PR it
creates. Its body should link the issue and the exact source lines, followed
by the check command and real result. Missing access is a failed pilot, not
evidence of a completed correction.

## Prove the result

Run manually on the approved issue. Execute the repository's relevant tests or
documentation checks, including a command that checks the documented behavior
when possible. Record the exact command and result in the PR. Verify that the
required CI checks actually run.

Have the independent reviewer compare the correction with the cited code.
Record acceptance or rejection and complete the
[shared acceptance check](../../setup.md#pilot-acceptance).
Rerun while the PR is open, then after it is merged. Neither run should create
a duplicate PR or a new change.

## Optional path triggers

Only after the manual pilot helps the team, add `push.paths` for source paths
that can invalidate the chosen document. Watch the approved base branch and
exclude the generated documentation PR's own changes to avoid a loop.
Test an in-scope source change and an unrelated path. Only the first should
start analysis. A scheduled run has no path event filter, so it needs a
deterministic changed-source check. Neither trigger expands the write allowlist.

## Optional manual cleanup

A maintainer may approve one redundant passage for removal using the same
one-file PR route. Preserve technical facts and required warnings. Keep useful
examples. Validate links and required sections after the cut. Keep cleanup
manual. A word-count target is not a reason to rewrite correct documentation.
