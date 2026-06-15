---

## What This Challenge Teaches

Two linked concepts: embedding domain expertise in workflow prompts (the "uber expert" pattern), and the causal chain architecture where one workflow creates issues and another acts on them. Participants learn that the quality of an AI agent is largely the quality of its context — and that decoupling analysis from action produces better, more reviewable outcomes.

---

## Expected Solution Shape

```markdown
---
on:
  schedule:
    - cron: "0 9 * * *"
  workflow_dispatch: {}

permissions:
  issues: write
  contents: read

safe-outputs:
  create-issue: {}

engines:
  - copilot
---

# Daily Testify — Uber Expert

You are an expert in JavaScript testing with Jest. You understand:
- The difference between unit, integration, and end-to-end tests
- That `expect.assertions(n)` prevents silent passes in async tests
- That snapshot tests without meaningful assertions are noise
- That 100% line coverage does not imply good test coverage
- Common anti-patterns: testing implementation details, over-mocking, not testing error paths

Review the test suite in `src/__tests__/` and `tests/`.

For each concrete improvement opportunity, create a GitHub issue with:
- Title: "[Testify] <specific file>: <specific gap>"
- Body: exact file path, function/method name, what is missing, one-sentence fix suggestion
- Label: `test-improvement`

Only create issues for gaps that are specific and actionable. Do not create issues for general advice.
Limit to 3 issues per run to avoid flooding.
```

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Issues are vague ("add more tests to utils.js") | Enforce specificity: "Each issue must name the exact function and what's missing" |
| Agent creates 20 issues at once | Add hard limit: "Create at most 3 issues per run" |
| Expert persona feels generic | Push for specificity: what does the expert know that a junior dev doesn't? Name it explicitly |
| `create-pr` used instead of `create-issue` | Redirect: this is intentional — the Improver handles PRs; Testify only identifies |

---

## How to Verify It's Working

1. Trigger `workflow_dispatch`
2. Check that issues are created with the `test-improvement` label
3. Open one issue — is it specific enough to act on without guessing?
4. Check that the issue names a real file and a real function in the repo
5. Confirm no PRs were opened (issues only)

---

## Coaching Notes

The "uber expert" concept is the most transferable lesson in Track 4. Participants often write generic prompts; the nudge is: _"What would a 10-year testing veteran notice that the model wouldn't without this context? Write those observations into the prompt."_

The causal chain architecture matters: explain that the issue is a _contract_ between the analyst (Testify) and the implementer (Test Improver). If the issue isn't specific enough, the Improver can't act on it. That's why `create-issue` only — the human review gate enforces quality.

If they're building both 4-05 and 4-06: ask them to run Testify first, review the issues, then configure the Improver to consume them.
