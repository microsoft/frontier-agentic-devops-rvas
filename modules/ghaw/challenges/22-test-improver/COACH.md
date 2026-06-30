---

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — would you trust an agent to write and open PRs for your missing tests, and how would you check that those generated tests actually prove something rather than just lifting coverage numbers? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to name a codebase with real coverage gaps they care about.
- Explore how they'd verify generated tests prove behaviour rather than just lift coverage numbers.
- Get them to pick one module they'll let a test-improver open PRs for next week.

## What This Challenge Teaches

The consumer side of the causal chain pattern — a workflow that translates analysis (issues from Testify) into implementation (PRs with new tests). Participants learn incremental, focused automation: one PR per file, one concern per PR, human review before merge. They also practice framework-specific prompt engineering.


Official grounding: when students are unsure whether a frontmatter field or permission is valid, anchor them in the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions) and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) docs before they tune the agent prompt.

---

## Expected Solution Shape

```markdown
---
on:
  schedule:
    - cron: "0 10 * * *"
  workflow_dispatch: {}

permissions:
  contents: write
  pull-requests: write
  issues: read

safe-outputs:
  create-pull-request: {}

tools:
  github:
    toolsets: [issues]

engine: copilot
---

# Daily Test Improver

You are improving test coverage for a Node.js project using Jest.

First, check for open issues labelled `test-improvement`. If any exist, implement the test described in the top-priority issue. Close the issue in the PR body with "Closes #<issue-number>".

If no labelled issues exist, scan `src/` for exported functions with no corresponding test in `tests/`. Find the most critical untested function (core business logic over utilities).

Write the missing test(s) for that function:
- Use Jest syntax: `describe`, `it`, `expect`
- Test the happy path, at least one error path, and one edge case
- Keep the new test file focused — no more than 50 lines

Open a single PR with the new or updated test file. Do not modify source code.
```

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Generated tests don't run (syntax errors) | Specify the framework version: "Use Jest 29 syntax" and check generated output before committing |
| PR modifies source code, not just tests | Add constraint: "Do not modify any file in `src/`. Only add or modify files in `tests/`" |
| Can't find the causal chain connection | Walk them through: Testify creates issue with label → Improver reads issues with that label → Improver opens PR and closes the issue |
| Test file tests the wrong thing | Enforce structure: "Each test must assert a specific return value, not just that the function runs without error" |
| Opens 10 PRs at once | Add limit: "Open at most one PR per run" |

---

## How to Verify It's Working

1. Have a `test-improvement` issue open from Challenge 4-05 (or create one manually)
2. Trigger `workflow_dispatch`
3. Confirm a PR opens that addresses the specific issue
4. Check the PR — does it close the issue in the PR body?
5. Review the test — is it syntactically valid? Does it test what the issue described?

---

## Coaching Notes

The most revealing moment in this challenge is when participants look at a Testify issue and then look at the Improver PR — and see the chain working end to end. Prompt them to articulate what would break if the issues weren't specific enough (_the Improver would produce vague tests_).

The framework-specificity lesson is practical: a prompt that says "write tests" produces worse output than "write Jest 29 tests using `describe`/`it` with async `await` patterns and `.resolves`/`.rejects` matchers." Have them find the right level of specificity for their own framework.

Fast squads: connect both 4-05 and 4-06 and run the full chain — Testify at 9am, Improver at 10am. Watch one pipeline create and resolve its own test debt.
