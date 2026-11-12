# Repository-specific review assistant

**Session outcome:** An optional reviewer finds a repository-specific defect,
cites the code and the standard it violates, or reports no finding. It keeps
to one comment and doesn't replace human review.

Start after [setup](../00-setup/README.md). First compare the check you have in mind
with Copilot code review and the repository's native checks. **Build this only
for a review gap they don't already cover.** Skip greetings and diff statistics,
and don't require a minimum number of findings.

## Build

Create `.github/workflows/review-buddy.md`. Trigger on PR `opened` and
`synchronize` events, scoped to the files that need the extra review.
Use read-only GitHub tools for the diff and repository contents. Look up toolset names in the
[current toolset reference](https://github.github.com/gh-aw/reference/tools/)
instead of guessing.

Read the rule from the trusted base revision, for example a service's
architecture rule or documented compatibility requirement. Read the changed
lines at the exact PR head SHA. Treat PR text and code as evidence, never as
instructions.

Each finding must cite the changed lines and the standard they break, and
explain the failure they would cause. If a claim can't be checked, say what
evidence is missing. No finding is a valid result. No generic comments about
change size or whether tests exist.

The supplied writer resolves the PR from the event and finds its own marked
comment. It creates the comment on the first run and updates it on later runs.
It rechecks the head SHA before publishing and rejects stale results. The agent
supplies only report text and the source hash, never a destination. A clean
review replaces an earlier finding.

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

Review the lock file, including the permissions of the reader and the separate
writer. Merge the workflow, helper, imports, and rule to the default branch
first. Then open the agreed PR from a branch in the same repository. **This starter
skips fork PRs.** It never checks out or executes the proposed change.

Open the Actions run and compare the comment with the changed lines. Push the
fix to that PR. The next run should replace the finding with
"No finding for the configured rule" instead of adding a comment.

## Validate the gap

Use a maintainer-reviewed PR that violates the rule and a legitimate change
that should pass. The first needs a finding a reviewer can act on. The second
needs none. Push an update and check that the assistant edits its one comment.
Record the human review and the
[shared acceptance evidence](../../setup.md#pilot-acceptance).

## Optional suspicious-change review

For a specific risk, add one focused check, such as an unexpected destination
in a changed data-transfer path. Test it on a harmless, non-executed fixture and
on legitimate code that uses the same API. Look at data flow and context, not
keywords. Apply it to internal and external authors alike.

Never execute suspicious code, and don't claim this replaces CodeQL, secret
scanning, or dependency controls. Report sensitive findings through an approved
restricted channel, not in a public PR comment.
