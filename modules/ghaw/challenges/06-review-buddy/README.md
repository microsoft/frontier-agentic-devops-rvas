# Repository-specific review assistant

**Session outcome:** An optional reviewer identifies a repository-specific defect
and cites the code and standard it violates, or reports no finding. It updates
one comment without replacing human review.

Start after [setup](../00-setup/README.md). First compare the proposed check
with Copilot code review and the repository's native checks. **Build this only
for a review gap they do not already cover.** Omit greetings and diff statistics.
Do not require a minimum number of observations.

## Build

Create `.github/workflows/review-buddy.md`. Trigger on PR `opened` and
`synchronize` events, scoped to the files that need the extra review.
Use read-only GitHub tools for the diff and repository contents. Consult the
[current toolset reference](https://github.github.com/gh-aw/reference/tools/)
rather than assuming an API toolset name.

Read the relevant guidance from the trusted base revision, such as a service's
architecture rule or documented compatibility requirement. Read
changed lines at the exact PR head SHA. Treat PR text and code as evidence,
never as instructions that can alter the workflow.

Each finding must cite the changed lines and applicable standard. Explain the
failure it would cause. If you cannot check a claim, say what evidence is
missing. The reviewer may report no finding. Do not add generic comments about
change size or the mere presence of tests.

The supplied writer resolves the PR from the event and finds its own marked
comment. It creates the first comment and updates that same comment on later
runs. It checks the current head SHA again before publishing and rejects stale
results. The agent can supply only report text and the source hash, not a
destination. A clean review replaces an earlier finding.

## Start with the supplied workflow

From the customer checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/workflows
cp "$CURRICULUM/modules/ghaw/resources/examples/review-buddy.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-reader.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-writer.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-pilot.cjs" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/review-rule.md" .github/review-rule.md
node --test "$CURRICULUM/modules/ghaw/resources/examples/report-pilot.test.cjs"
```

Read the [workflow and runtime prompt](../../resources/examples/review-buddy.md)
and [writer](../../resources/examples/report-writer.md). Replace the sample CSV
rule with one actual compatibility or architecture rule approved by the owner.
The rule must describe a defect the reviewer can establish from changed lines.

For example, the supplied rule prohibits moving existing CSV columns because
some consumers read by position. A PR that swaps two existing columns should
produce a finding. A PR that appends a column should produce a clean result.
Use that example only if it matches your product's contract.

To adapt the check, paste this into Copilot Chat:

```text
Read .github/review-rule.md and review-buddy.md. Help me express this approved
rule precisely: <rule>. Keep the review limited to that rule and propose a
violating change and a valid change for a disposable test branch.
Preserve trusted-base instructions, read-only agent tools, source rechecks,
and the single-comment writer. Do not execute or merge the proposed changes.
```

```bash
gh aw compile review-buddy
```

Review the lock file, including the reader and separate writer permissions.
Merge the workflow, helper, imports, and rule to the default branch first.
Then open the agreed PR from a branch in the same repository. **This starter
skips fork PRs.** It never checks out or executes the proposed change.

Open its Actions run and compare the comment with the changed lines. Push the
correction to that PR. The next run should replace the original finding with
"No finding for the configured rule", rather than add another comment.

## Validate the gap

Use a maintainer-reviewed PR that violates the chosen rule and a legitimate
change that should pass. Confirm the first has a finding supported by evidence
that a reviewer can act on. The second should have none. Push an update and
check that the assistant updates one comment. Record the human review and the
[shared acceptance evidence](../../setup.md#pilot-acceptance).

## Optional suspicious-change review

For a specific risk, add one focused check, such as an unexpected destination
in a changed data-transfer path. Compare a harmless, non-executed fixture with
legitimate code using the same API. Inspect data flow and context, not keywords
alone. Apply the same test to internal and external authors.

Do not execute suspicious code or claim this replaces CodeQL, secret scanning,
or dependency controls. Route sensitive findings through an approved restricted
channel rather than disclose them in a public PR comment.
