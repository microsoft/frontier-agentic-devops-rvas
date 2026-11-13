# Issue triage for the customer's taxonomy

**Session outcome:** The workflow applies only approved labels to real issues.
A maintainer checks its choices, including when it declines to label an
ambiguous issue.

Start after [setup](../00-setup/README.md).
**Use issue forms first** when the reporter can select a known category.
Use the model only when those fields and simple rules can't classify the issue.

## Build and validate

1. Read the repository's existing issue forms and list its labels:
   `gh label list --limit 100`. Increase the limit if needed. Have a maintainer
   pick the small set of labels this workflow may add and define each one.
2. Copy the [complete triage starter](../../resources/examples/issue-triage-agent.md)
   into the customer checkout as `.github/workflows/issue-triage-agent.md`.
   Its Markdown body is the agent's prompt. It runs on issue `opened` and
   `reopened` events.
3. Keep the agent's token read-only. Configure `safe-outputs: add-labels` with
   an explicit `allowed` list of the customer's exact labels. Exclude approval
   and escalation labels that maintainers control. Triage must not approve
   work for a code-writing workflow.
4. Tell the model to add a label only when the issue gives enough evidence.
   Keep existing labels and abstain when unsure. No minimum number of labels,
   no mandatory comment.
5. Compile with `gh aw compile issue-triage-agent`. Inspect the lock file's
   writer permissions and label allowlist, then merge through review.
6. Test a clear issue, an ambiguous one, and an issue with existing labels.
   Rerun an event. A maintainer compares the results with the taxonomy. Labels
   that didn't change should produce no extra output.

Record the maintainer's corrections before you enable this for all new issues. Complete the
[shared acceptance check](../../setup.md#pilot-acceptance).

## Customize and run the starter

From the customer checkout, set `CURRICULUM` to the absolute path of this
curriculum checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/workflows
cp "$CURRICULUM/modules/ghaw/resources/examples/issue-triage-agent.md" .github/workflows/
gh label list --limit 100
```

The sample uses `bug`, `documentation`, and `question`. Use existing labels or
have a maintainer create the missing ones. Replace both the
`safe-outputs.add-labels.allowed` list and the definitions in the prompt.
For help adapting them, paste this into Copilot Chat in agent mode:

```text
Adapt .github/workflows/issue-triage-agent.md to this repository's issue forms
and labels. Propose the smallest useful taxonomy and ask me to approve it.
Then update both the label allowlist and the prompt's definitions.
Keep the token read-only, preserve existing labels, and call noop when the
issue is ambiguous. Do not add comments, assignments, or approval labels.
Compile the workflow. Do not deploy it or create test issues.
```

Compile and inspect the source and lock file:

```bash
gh aw compile issue-triage-agent
git diff -- .github/workflows/
```

Open new files in the editor too. `git diff` doesn't show untracked files.
Merge the reviewed files to the default branch. Use an approved test repository
for these examples, or coordinate equivalent real issues with the maintainer:

| Issue body | Expected result with the sample taxonomy |
| --- | --- |
| "The documented Save button returns HTTP 500. Here are the reproduction steps..." | `bug`, if the evidence establishes a defect. |
| "How do I change the export format?" | `question`. |
| "Something is wrong. Please help." | No label; the run records why it abstained. |

Open the issue's Actions run and compare its label request with the issue text.
In the run menu, choose **Re-run all jobs**. Confirm the same label is not added
again and no comment appears. Close practice issues after the check.

Optional: for stale-issue policy or contributor welcome messages, use native
[`actions/stale`](https://github.com/actions/stale) and
[community-health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file). They need no model.
