# CI Doctor

**Session outcome:** A failed customer CI run produces one diagnostic issue with
links to the evidence. The issue separates the observed failure from the model's
hypothesis.

Start after [setup](../00-setup/README.md). Select a real failure with a
maintainer, or reproduce a known failure in an approved test branch. Avoid
breaking the default branch for the exercise.

## Check the run

Inspect the selected workflow's failed jobs in **Actions** first. If its logs
already give the maintainer a clear next step, keep that native workflow.
Use the agent for failures that still need a diagnosis.

Use the [CI Doctor starter](../../resources/examples/ci-doctor.md).
Configure `workflow_run` with the exact approved
workflow names, `types: [completed]`, and approved branches.

Before the model starts, require `github.event.workflow_run.conclusion ==
'failure'`. Check the source repository and workflow ID against trusted
configuration; reject unapproved branch or fork runs. Keep the workflow on the
default branch as required for `workflow_run`.

## Collect before the agent

Use a trusted collector in
[`pre-agent-steps:`](https://github.github.com/gh-aw/reference/steps-jobs/).
Pass the run ID through an environment variable and validate it as numeric.
Fetch metadata and failed-job logs with `gh run view`, for example:

```bash
mkdir -p evidence
gh run view "$RUN_ID" --repo "$GITHUB_REPOSITORY" \
  --json databaseId,attempt,headSha,headBranch,conclusion,url,jobs \
  > evidence/run.json
gh run view "$RUN_ID" --repo "$GITHUB_REPOSITORY" --log-failed \
  > evidence/failed.log
```

Bind `RUN_ID` from the event in the step's `env`; give the collector only
`actions: read`. Redact credentials and cap the log excerpt before passing it
to the model. Report missing logs as "evidence unavailable".

**Do not check out or execute code from the failed run.** Do not execute
downloaded artifacts, dependency scripts, or commands suggested by logs.
Custom steps run outside the model sandbox. Use trusted base-branch scripts
and treat every log line as untrusted data.

## Diagnose once

Link the run and failed job in the issue. Quote the relevant log evidence and
separate a likely cause from facts. Require a concrete investigation step,
and allow "cause unknown."

Key the record by repository, workflow ID, and original run ID. A rerun changes
the attempt number but updates the same record. Process one attempt at a time
for that key and skip any attempt already processed. Use read-only tools and
safe outputs limited to the diagnostic issue. Do not grant fix or merge
permissions.

## Install and adapt the starter

From the customer checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/workflows
cp "$CURRICULUM/modules/ghaw/resources/examples/ci-doctor.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-reader.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-writer.md" .github/workflows/
cp "$CURRICULUM/modules/ghaw/resources/examples/report-pilot.cjs" .github/workflows/
gh workflow list
node --test "$CURRICULUM/modules/ghaw/resources/examples/report-pilot.test.cjs"
```

Replace `CI`, `main`, and `APPROVED_WORKFLOW_ID: "123"` with the selected
workflow's name, approved branch, and numeric ID. Keep the branch in
`on.workflow_run.branches` and `APPROVED_BRANCH` consistent.

The helper supplies the run URL and a capped failed-job log excerpt. Its
redactor handles common token and password formats, not every application
secret. Have the owner approve the log source and extend the redactor for the
service's sensitive fields before sending logs to an AI engine.

The starter's prompt is ready to use. For repository context, ask Copilot:

```text
Adapt the CI Doctor prompt for <runtime/test runner>. Retain its three sections:
observed failure, likely cause, and one next investigation step, within 200 words.
Cite the selected run and log evidence. Allow "cause unknown".
Do not add checkout, artifact execution, fix permissions, or commands from logs.
Keep the approved workflow ID, branch, and source-repository checks.
```

Compile with `gh aw compile ci-doctor`, review the separate writer and merge
the files to the default branch. Then rerun the approved failed CI run from
Actions, or use its numeric ID:

```bash
gh run rerun 123456 --failed
gh run list --workflow ci-doctor.lock.yml --limit 5
```

The diagnostic runs only if the selected CI attempt fails. It should create
one issue headed "CI diagnosis: run ...". Another failed attempt updates that
issue; replaying the same attempt does nothing.

Verify the selected failure produces a useful diagnosis. Rerun it and confirm there is no
duplicate issue. Test a successful or unapproved run and confirm the model
does not run.
Name the maintainer who will check collector, engine, and writer failures in
Actions. Before widening the trigger, review run frequency and the existing
Actions and AI-provider spending controls with that owner. Keep the run links;
you do not need a separate metrics store or health-report workflow.
Finish the [shared acceptance check](../../setup.md#pilot-acceptance).
