# Activity 00: Customer workflow setup

**Session outcome:** The chosen AI engine runs in the customer's GitHub Actions
environment. The workflow has an owner and a reviewed deployment process.

## Prepare the repository

Follow the [setup guide](../../setup.md). Choose a real task for the
[documentation pilot](../19-daily-doc-updater/README.md),
[test pilot](../21-daily-testify/README.md),
[CI diagnosis](../18-ci-doctor/README.md), or
[issue triage](../17-issue-triage-agent/README.md). Use a customer-owned repository
with an independent reviewer and existing checks.

Run these commands from its checkout:

```bash
gh --version
gh auth status
gh aw --version
gh repo view --json nameWithOwner,viewerPermission,defaultBranchRef
```

If authentication is missing, run `gh auth login` for the correct GitHub host.
Confirm that the returned repository is the intended target. Check the
requirements in the
[deployment readiness checklist](../../setup.md#deployment-readiness).

## Verify the runtime

Use the chosen pilot's manual trigger for the readiness run. If the pilot is
not ready, copy the [manual smoke example](../../resources/examples/hello-world.md)
to `.github/workflows/hello-world.md` in the customer repository and inspect it.
It allows at most one setup issue; the agent gets read-only access.

```bash
gh aw compile hello-world
```

Review the source and generated lock file through the customer's normal PR
process, then deploy them to the default branch. Manually dispatch the workflow
from Actions. Check the live run log for successful engine authentication and
the permitted output. Close the smoke-test issue afterward.

**A dry run is only a preparation check.** It does not prove the engine can run
and write its output in this repository. If deployment is blocked, record who
will address it and the next action before attempting a pilot.
