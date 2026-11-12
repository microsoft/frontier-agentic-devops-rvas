# Activity 00: Customer workflow setup

**Session outcome:** The chosen AI engine runs in the customer's GitHub Actions
environment, and the workflow has an owner and a reviewed deployment path.

## Prepare the repository

Follow the [setup guide](../../setup.md). Pick a real task for the
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
Confirm the returned repository is the one you intend to change, then work
through the [deployment readiness checklist](../../setup.md#deployment-readiness).

## Verify the runtime

Use the chosen pilot's manual trigger for the readiness run. If the pilot is
not ready, copy the [manual smoke example](../../resources/examples/hello-world.md)
to `.github/workflows/hello-world.md` in the customer repository and inspect it.
It creates at most one setup issue, and the agent has read-only access.

```bash
gh aw compile hello-world
```

Review the source and lock file in a normal PR and merge them to the default
branch. Dispatch the workflow manually from Actions. In the live run log, check
that the engine authenticated and the output is the permitted one. Then close
the smoke-test issue.

**A dry run only checks your preparation.** It doesn't prove the engine can run
and write output in this repository. If deployment is blocked, record who will
unblock it and the next step before you start a pilot.
