# Authorized issue summaries

**Session outcome:** An authorized `/summarize` request updates one issue summary
with links to its sources. Unapproved commands never reach the model.

This is optional after [setup](../00-setup/README.md). Pick a real issue with a
discussion long enough that a maintainer would want a summary.

## Check access before the model runs

Create `.github/workflows/slash-commands.md` for
`issue_comment: types: [created]`. Use a deterministic activation check:

- Require the trimmed comment body to equal `/summarize` exactly. Reject quoted
  commands, prose containing the command, and additional arguments.
- Require `author_association` to be in the team's approved list, such as
  `OWNER`, `MEMBER`, or `COLLABORATOR`. Check current repository permission if
  that policy requires write access; association alone does not prove it.
- Reject bot comments and PR conversations if this workflow supports only issues.
- Use the comment ID as the request key. Skip already handled requests and
  process one request at a time per issue.

The supplied helper runs these checks in a trusted pre-agent step. It requires
current write, maintain, or admin permission and records rejected requests as a
noop before inference. **A prompt instruction is not an authorization check.**

## Summarize evidence

Fetch the issue and paginate its comments with read-only access. Record the
latest comment ID included. Ask the model for a short summary with direct
comment links beside decisions and open actions. State what discussion the
summary covers and when it was collected. If a source can't be read, stop
instead of publishing a summary that hides the gap.

**Only name a decision or owner when someone explicitly recorded it.**
Separate proposals from accepted decisions. If an action has no owner, say so.
Don't recommend closing the issue because no one responded, and don't infer
agreement the thread doesn't contain.

The supplied writer always targets the event's issue. It creates one marked
comment, then updates it. The request ID and source hash go into the comment in
the same write as the summary. The writer rechecks permissions and source state,
so a failed write can't record a completed request.

## Copy, customize, and invoke

From the customer checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/workflows
cp "$CURRICULUM/modules/ghaw/resources/examples/slash-commands.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-reader.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-writer.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-pilot.cjs" .github/workflows/
node --test "$CURRICULUM/modules/ghaw/resources/examples/report-pilot.test.cjs"
```

Read the [complete workflow](../../resources/examples/slash-commands.md).
Its Markdown body contains a usable summary prompt. Adjust its headings to
your team's issue summaries if needed, but keep the exact-command gate and
write-permission check outside the model.

Compile, review the generated jobs, and merge the files to the default branch:

```bash
gh aw compile slash-commands
```

Choose a real issue with useful discussion. With maintainer approval, replace
`42` and post the exact command:

```bash
gh issue comment 42 --body "/summarize"
gh run list --workflow slash-commands.lock.yml --limit 5
```

The comment should separate accepted decisions from proposals and link the
comments that establish them. Add a relevant comment and post `/summarize`
again. The workflow should edit the first summary, not create a second.

## Verify

Post these three comments. Only the first should call the engine:

| Comment | Expected |
| --- | --- |
| `/summarize` from an authorized author | Summary created, or updated if one exists |
| `Please /summarize this` from the same author | Skipped before the model |
| `/summarize` from an unauthorized author | Skipped before the model |

Check every decision and owner against its cited comment. Rerun the same event and confirm no duplicate comment appears.
