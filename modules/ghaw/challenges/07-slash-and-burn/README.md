# Authorized issue summaries

**Session outcome:** An authorized `/summarize` request updates one issue summary
with links to its sources. Unapproved commands never reach the model.

This is optional after [setup](../00-setup/README.md). Choose a real issue whose
discussion is long enough that a summary would help a maintainer.

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

The supplied helper performs these checks in a trusted pre-agent step.
It requires current write, maintain, or admin permission. Rejected requests
write a noop before inference. A prompt instruction is not an authorization
check.

## Summarize evidence

Fetch the issue and paginate its comments with read-only access.
Record the latest included comment ID. Ask the model for a short summary
with direct comment links beside decisions and unresolved actions.
State which discussion the summary covers and when it was collected. If a
source cannot be read, stop rather than publish a seemingly complete summary.

**Only name a decision or owner when someone explicitly recorded it.**
Distinguish proposals from accepted decisions. If an action has no assigned
owner, say so. Do not recommend closing the issue from silence or infer an
agreement that the thread does not contain.

The supplied writer fixes the target to the event's issue. It creates one
marked comment, then updates it. The comment stores the request ID and source
hash in the same write as the summary. The writer rechecks permissions and
source state; failed writes cannot record a completed request.

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
Its Markdown body contains a usable summary prompt. To customize it, use:

```text
Adapt the Markdown prompt in slash-commands.md for our team's issue summaries.
Keep sections for the issue, accepted decisions, and unresolved actions.
Require comment links for decisions and named owners. Do not infer agreement.
Keep the exact-command gate and current-write-permission check outside the
model. Preserve one marked comment and the source recheck before publication.
```

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

The comment should separate accepted decisions from proposals and link to the
comments that establish them. Add a relevant discussion update and post another
`/summarize`. The workflow should edit the first summary, not create a second.

## Verify

Test an authorized exact command, a command embedded in prose, an unauthorized
author, and a rerun of the same event. Only the first should call the engine.
Check every decision and owner against its cited comment. A second authorized
request after new discussion should update the existing summary.
