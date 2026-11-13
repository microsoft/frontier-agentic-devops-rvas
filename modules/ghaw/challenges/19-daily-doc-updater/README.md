# Reviewed documentation correction

**Session outcome:** One doc-correction PR fixes a documentation error in one
customer file and cites the code that supports the fix. Checks pass, and an
independent reviewer approves it. This session changes docs only. For a
test-only PR, see [daily-testify](../21-daily-testify/README.md).

Complete [setup](../00-setup/README.md), then pick an issue about a real
documentation error with a maintainer. For example, a documented option may
disagree with its implemented default. Don't plant a stale document just to
get the agent to open a PR.

## Approve the work

Agree on the issue URL, the one documentation file the agent may write, the
source files that show the correct behavior, the validation command, and an
independent reviewer.

Start with `workflow_dispatch`, restricted to authorized maintainers. Set the
approved issue and write path in reviewed configuration.

## Build the pilot

Use the [documentation starter](../../resources/examples/daily-doc-updater.md)
and [approval guard](../../resources/examples/pilot-guard.cjs). The starter is
manual and its Markdown body contains the agent's prompt.

The guard is the pattern [daily-testify](../21-daily-testify/README.md) reuses.
It checks the configured issue, its approval label, and the current write
permission of whoever applied the label, before the model runs. It rejects a
different issue chosen at runtime. It writes `.pilot-context.json` with the
issue and base SHA. The agent reads the named source at that revision. Don't
let it infer behavior from prose alone. A triage bot must not apply the
approval label.

Give the agent read-only GitHub permissions and only the local editing and
test tools needed. Configure `create-pull-request` with `max: 1`, the approved
base branch, and `allowed-files` set to the approved file. Keep
`protected-files: blocked` and disable fallback issues. The writer enforces
this, not just the prompt.

The prompt must fix only the documented mismatch and cite the code evidence in
the PR body. Check for an existing PR on the same issue and file first.
**If the documentation is already correct, do nothing.**

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

Have a maintainer create `agent-doc-approved` if it doesn't exist and apply it
to the issue. Writing "approved" in the issue body doesn't pass the guard.

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

Compile, review the generated jobs, and merge the source, guard, and lock file
through normal review:

```bash
gh aw compile daily-doc-updater
```

A failed approval check must block inference and publication. After the merge:

```bash
gh workflow run daily-doc-updater.lock.yml -f issue=42
gh run list --workflow daily-doc-updater.lock.yml --limit 5
```

Replace `42` here too. Open the run and the draft PR it creates. Its body
should link the issue and the exact source lines, then show the check command
and its real result.

## Prove the result

Run the repository's relevant tests or documentation checks, including one
that exercises the documented behavior if possible. Put the exact command and
result in the PR, and confirm the required CI checks run.

Have the independent reviewer compare the fix with the cited code, then
complete the [shared acceptance check](../../setup.md#pilot-acceptance).
Rerun the workflow while the PR is open, then again after the merge. Neither
run should create a duplicate PR or a new change.

## Optional

- Add `push.paths` triggers for source paths that can make the doc stale. Exclude the generated PR's own changes to avoid a loop.
- Approve removal of one redundant passage through the same one-file PR route.
