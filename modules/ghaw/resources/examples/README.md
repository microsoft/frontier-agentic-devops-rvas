# Workflow starters

[`hello-world.md`](hello-world.md) is an optional manual readiness check for the
customer repository. Follow [Activity 00](../../challenges/00-setup/README.md)
to deploy it through review. It creates at most one setup issue and skips an
existing one.

The example checks runtime access. Use a customer workflow pilot to test
whether the automation helps the team.

| Starter | What to customize |
| --- | --- |
| [Issue triage](issue-triage-agent.md) | Approved label names and their definitions. |
| [Documentation correction](daily-doc-updater.md) | Approved issue, document and source paths, and validation command. |
| [Regression test](daily-test-improver.md) | Approved issue, test file, and test command. |
| [Review assistant](review-buddy.md) | The base-branch [review rule](review-rule.md). |
| [Issue summaries](slash-commands.md) | The summary's audience and wording. |
| [CI diagnosis](ci-doctor.md) | Exact workflow name, numeric ID, branch, and log redaction. |

The documentation and test pilots also need [pilot-guard.cjs](pilot-guard.cjs).
The review, issue-summary, and CI starters import [report-reader.md](report-reader.md) and
[report-writer.md](report-writer.md), and need [report-pilot.cjs](report-pilot.cjs).
Copy these files together, as each lesson shows. The helper scripts run outside
the model and select approved inputs and write targets. The model receives no
write token.

The report writer uses `GITHUB_TOKEN` and recognizes comments and issues authored
by `github-actions[bot]`. Adapting it to another App identity requires updating
that ownership check. It never adopts a human comment that copies the marker.

Run the dependency-free helper tests from this curriculum checkout:

```bash
node --test modules/ghaw/resources/examples/*.test.cjs
```

Compile the selected workflow in the customer checkout, with its imports
beside it. Inspect the generated permissions and failure conditions before
deployment. These helpers' local tests do not replace a live engine and writer
check. Review action versions and pin them to approved commits.
If the compiler rejects `allowed-files`, a job condition, or a custom safe
output, use an approved version that supports it. Do not remove a control just
to make compilation pass.
