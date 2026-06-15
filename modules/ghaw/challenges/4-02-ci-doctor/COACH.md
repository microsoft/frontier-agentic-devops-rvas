---

## What This Challenge Teaches

The `workflow_run` trigger — one of the most powerful and least-understood triggers in GitHub Actions. Participants learn how to react to another workflow's outcome (not just code events), how to access run logs programmatically, and how to structure a diagnostic issue that's actually useful to a maintainer.

---

## Expected Solution Shape

```markdown
---
on:
  workflow_run:
    workflows: ["CI", "tests"]
    types: [completed]

permissions:
  actions: read
  issues: write

safe-outputs:
  create-issue: {}

tools:
  github:
    toolsets: [actions]

engines:
  - copilot
---

# CI Doctor

This workflow fires when a monitored CI workflow completes.

Only proceed if `github.event.workflow_run.conclusion == "failure"`.

If the run failed:
1. Fetch the run logs using the actions toolset
2. Identify the failure type: compile error, test failure, flaky test, env issue, or other
3. Find the specific error message and failing step
4. Open an issue titled "CI Failure: [workflow name] — [brief description]" with:
   - What failed (step name, error message)
   - Most likely root cause (1-2 sentences)
   - Suggested fix or next investigation step
   - Link to the failing run: `github.event.workflow_run.html_url`
```

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Workflow never fires | Check `workflows:` names match exact workflow names in `name:` field of target `.yml` files |
| "Could not access logs" | Needs `actions: read` permission + `toolsets: [actions]` |
| Fires on successful runs too | Add conclusion check in body: "Only investigate if conclusion is 'failure'" |
| Issue body is too long / noisy | Add word limit to body: "Keep issue body under 200 words" |
| No workflow failures to test against | Have participant add `run: exit 1` to a test workflow temporarily |

---

## How to Verify It's Working

1. Break a CI workflow intentionally (add `run: exit 1` to a step)
2. Push to a branch — let CI fail
3. Confirm Doctor fires after CI completes
4. Check the opened issue — does it name the failing step? Is the root-cause diagnosis reasonable?
5. Fix the CI — confirm Doctor doesn't fire on the successful re-run

---

## Coaching Notes

The `workflow_run` trigger confuses participants because it's asynchronous and crosses workflow boundaries. Key concept to reinforce: the Doctor runs in a *separate* workflow from CI — it's observing CI from the outside, not running inside it.

Common mistake: nesting this inside the CI workflow itself (using `on: push`). Redirect: _"The Doctor needs to fire after CI completes, not during. Which trigger lets you react to another workflow's result?"_

Participants who finish early can extend: add a second `workflows:` entry, or add an `if:` condition to only run on `main` branch failures.
