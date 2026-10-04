# Issue triage for the customer's taxonomy

**Session outcome:** The workflow applies only approved labels to real issues.
A maintainer validates its choices, including an ambiguous issue where it
abstains.

Start after [setup](../00-setup/README.md).
**Use issue forms first** when the reporter can select a known category.
Use the model only when those fields and simple rules cannot classify the issue.

## Build and validate

1. Read the repository's existing issue forms and list its labels:
   `gh label list --limit 100`. Increase the limit if needed. Have a maintainer
   define the small subset this workflow may add and what each label means.
2. Copy the [complete triage starter](../../resources/examples/issue-triage-agent.md)
   into the customer checkout as `.github/workflows/issue-triage-agent.md`.
   Its Markdown body is the reporting agent's prompt. It runs on issue
   `opened` and `reopened` events.
3. Keep the agent's token read-only. Configure `safe-outputs: add-labels` with
   an explicit `allowed` list of the customer's exact labels. Exclude approval
   and escalation labels that maintainers control. Triage must not approve
   work for a code-writing workflow.
4. Ask the model to add a label only when the issue supplies enough evidence.
   Preserve existing labels and abstain on ambiguity. There is no required
   number of labels and no mandatory explanatory comment.
5. Compile with `gh aw compile issue-triage-agent`. Inspect the lock file's
   writer permissions and label allowlist, then deploy through review.
6. Test a clear issue, an ambiguous one, and an issue with existing labels.
   Rerun an event. A maintainer compares results with the taxonomy; unchanged
   labels should produce no extra output.

Record corrections before enabling this for all new issues. Complete the
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
have a maintainer create the agreed missing ones. Replace both the
`safe-outputs.add-labels.allowed` list and their definitions in the prompt.
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

Open new files in the editor too; untracked files do not appear in `git diff`.
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

## Deterministic maintenance references

These are optional native Actions recipes, separate from AI triage.

Use [`actions/stale`](https://github.com/actions/stale) for a
maintainer-approved inactivity policy. Configure `days-before-issue-stale`,
`days-before-issue-close`, and `exempt-issue-labels`; disable PR handling if
the policy covers issues only. Warn once, then calculate the grace period by
elapsed time, not number of workflow runs. Verify activity removes the stale
state and exemption labels prevent closure. Test recent activity, an exempt
issue, and the grace-period boundary with fixture timestamps before enabling
closure. A custom minimum issue age needs a separate deterministic check.

For contributor guidance, start with
[community-health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)
and [issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository).
If maintainers still want a welcome comment, use a fixed template and a
deterministic first-contribution check. `author_association: NONE` alone does
not establish that this is someone's first contribution. Query prior activity
and exclude bots. Check for an existing welcome on the PR before posting.
Link real guidance without promising review times. No model is needed.

Pin any action to a reviewed commit SHA and scope its token to the required
issue or PR writes.
