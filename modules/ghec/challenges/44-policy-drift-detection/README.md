# Ch44: Monitor an approved repository ruleset

**Session outcome:** A daily, read-only Actions workflow checks a customer ruleset against its reviewed baseline. Unexpected changes or unreadable evidence fail the run, and a named owner handles the result.

**Drift** means the live configuration differs from the approved one.
For example, someone disables a ruleset or removes a required CI check.
The monitor reports the change. It never repairs settings.

## Before you start

Use an approved private repository with an **active branch ruleset** and working
review or CI requirements. If those controls are missing, set up and test
them in [Ch08](../08-rulesets-repo-properties/README.md) first.

You need permission to merge the monitor files, `gh`, and Python 3. Metadata
read access is enough for these ruleset fields. Repair needs the ruleset's
administrator: a repository administrator can't repair an inherited
organization rule. Get the control owner's approval, and keep baseline changes
under the repository's existing review policy.

## 1. Select the control to monitor

From the customer checkout, set the repository and list its branch rulesets:

```bash
export TARGET_REPOSITORY="YOUR-ORG/YOUR-APPROVED-REPO"
gh api "repos/$TARGET_REPOSITORY/rulesets?targets=branch&includes_parents=true&per_page=100" \
  --paginate --jq '.[] | {id, name, source_type, enforcement}'
```

Choose the active ruleset that supplies the agreed controls. Set its numeric ID:

```bash
export RULESET_ID="123456"
```

For GHE.com, set `GH_HOST=<customer>.ghe.com` and authenticate to that host first.
The baseline records the hostname to prevent a check against the wrong service.

## 2. Capture and review the baseline

Check for existing files before copying to these paths. From the customer checkout:

```bash
CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
mkdir -p .github/scripts .github/workflows
cp "$CURRICULUM/modules/ghec/resources/drift/check.py" .github/scripts/check.py
cp "$CURRICULUM/modules/ghec/resources/drift/ruleset-drift.yml" .github/workflows/
python3 .github/scripts/check.py "$TARGET_REPOSITORY" \
  --capture "$RULESET_ID" > .github/ruleset-baseline.json
```

Capture must exit `0`. An error report isn't a baseline.
Have the owner check the generated JSON against the intended settings,
especially rule enforcement, branch conditions, review count, and required
check names and App IDs. Capturing the current state doesn't make it correct.

The checker compares `enforcement`, `target`, `conditions`, and all returned
`rules` and their parameters. It ignores timestamps, names, and array order.
**It doesn't check bypass actors**, which the API hides from read-only
identities. It also doesn't audit classic branch protection or certify
enterprise compliance. Use Ch08 for enforcement tests and
[Ch37](../37-ghqr-governance-quick-review/README.md) for a broader review.

Run the first check:

```bash
python3 .github/scripts/check.py "$TARGET_REPOSITORY" \
  --baseline .github/ruleset-baseline.json
```

| Exit | Meaning | Owner action |
|---|---|---|
| `0` | Monitored fields match the baseline | No repair needed |
| `1` | An observed setting differs | Review the change and approve a repair or baseline update |
| `2` | Baseline or API evidence is unavailable or invalid | Restore access or fix the configuration. Don't treat this as a pass |

A `404` can mean hidden or absent evidence. It doesn't prove the ruleset was
deleted. Even a stricter unexpected setting needs review before you update the
baseline. Never recapture the baseline just to turn a failure green.

## 3. Install the recurring check

Open a PR with the checker, baseline, and workflow. Have the control owner
review it, then merge it under the existing controls. Add these files to
the team's CODEOWNERS or review policy, so changing the monitor also needs review.

The supplied workflow runs daily at **06:17 UTC** and supports manual runs.
It uses the repository's `GITHUB_TOKEN` with `contents: read`. It needs no PAT,
App key, or write permission. It derives the host from the Actions server.
Results appear in the run summary. Scheduling is best-effort and runs from the
default branch.

After merge, dispatch and inspect a run:

```bash
gh workflow run ruleset-drift.yml --repo "$TARGET_REPOSITORY"
gh run list --repo "$TARGET_REPOSITORY" --workflow ruleset-drift.yml --limit 5
```

Open the run in Actions and confirm the expected repository and ruleset ID.
Name who checks failed runs and who can repair the control. Enable Actions
failure notifications for that owner. Scheduled notifications go to the
workflow creator, the latest cron editor, or the user who re-enabled it. Confirm
that person is the named owner. If not, have the owner re-enable the workflow.
Use the customer's existing alerting route if email isn't enough.

## 4. Verify failure without weakening the live rule

Run the local helper tests:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s "$CURRICULUM/modules/ghec/resources/drift" -p 'test_*.py'
```

They cover disabled enforcement, removed checks, reduced reviews, changed branch
conditions, and unreadable evidence. Don't weaken a customer control to test
the monitor.

To test a failed Actions run and its notification, create an approved temporary
branch after the workflow is merged. In that branch's baseline JSON only, add
`refs/heads/drift-notification-test` to `policy.conditions.ref_name.exclude`.
Keep the rule ID and live ruleset unchanged. Commit the change, push the
branch, and have the notification owner dispatch it:

```bash
gh workflow run ruleset-drift.yml --repo "$TARGET_REPOSITORY" --ref <test-branch>
```

Expect exit `1` with a conditions difference. Have the owner confirm they can
see the failed run and receive its notification. **Don't merge the test
baseline.** Delete the temporary branch through normal cleanup.
Dispatch the default-branch workflow again and confirm it passes.

If live drift appears later, have the ruleset owner approve and apply the repair,
then rerun the monitor. Record an intentional control change through a reviewed
baseline PR. Don't weaken the approved expectation.

Keep the baseline PR and the passing and failed run links in the existing adoption
issue. The session is done when the monitor is installed and its owner can
handle a failure. To stop it, disable **Ruleset drift** in Actions. The ruleset
itself stays unchanged.

## References

- [Get a repository ruleset](https://docs.github.com/en/rest/repos/rules#get-a-repository-ruleset)
- [Scheduled workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule)
- [Actions notifications](https://docs.github.com/en/actions/concepts/workflows-and-actions/notifications-for-workflow-runs)
