---

## Facilitated application

**Required facilitator check-in:** before completion, ask the customer practitioner to connect the exercise to work they actually own.

**Discuss:** What would it take for you to rely on a daily agent scanning your code changes for supply-chain red flags, and how would you handle false positives without tuning out the real threats? Connect it to a project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask which of their repos or dependencies carry real supply-chain exposure.
- Explore how they'd handle false positives without tuning out genuine threats.
- Get them to commit to one repo where they'll run a daily change-scan next week.

## What This Activity Teaches

Supply-chain threat modelling expressed as an agentic workflow. Participants learn to define threat patterns precisely (not just "look for bad code"), scope reviews to recent changes (not the entire codebase), and structure alerts with enough context for a security reviewer to investigate. This is a detective aid, not a preventive control or replacement for code review and other security controls.


Official grounding: when customer delivery team members are unsure whether a frontmatter field or permission is valid, anchor them in the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions) and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) docs before they tune the agent prompt.

---

## Expected Solution Shape

```markdown
---
on:
  schedule:
    - cron: "0 7 * * *"
  workflow_dispatch: {}

permissions:
  contents: read
  issues: write

safe-outputs:
  create-issue: {}

tools:
  github:
    toolsets: [actions, issues]

engine: copilot
---

# Daily Malicious Code Scan

Review all commits merged into `main` in the last 7 days.

Flag any of the following patterns added or modified in that window:

1. **Obfuscated evaluation**: `eval`, `Function`, or `new Function` with non-literal string arguments; base64/hex decoded strings passed to execution functions
2. **Unexpected network calls**: `fetch`, `http.request`, `axios`, or `curl` calls to external domains not present in the repo before this week
3. **Credential access patterns**: reading `process.env` or `os.environ` for keys containing TOKEN, SECRET, KEY, PASSWORD, or PRIVATE
4. **Dynamic imports**: `require(variable)` or `import(expression)` where the module path is constructed at runtime
5. **Workflow self-modification**: changes to `.github/workflows/` files that were not part of a reviewed PR

For each flagged pattern:
- Note the file path, line number, and commit SHA
- Explain why it was flagged (which pattern, what the code does)
- Assess likelihood: is this likely benign (e.g., test utilities) or suspicious?

Open a single issue titled "🔍 Malicious Code Scan — [date]" only if high-likelihood suspicious patterns are found. If all findings are likely benign, add a brief comment to the most recent scan issue instead.

If nothing suspicious is found, do nothing.
```

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Too many false positives | Add a likelihood assessment step: "Mark each finding as likely benign / uncertain / suspicious before deciding to open an issue" |
| Agent scans the entire repo history | Scope explicitly: "Only review commits from the last 7 days" |
| Can't test without real suspicious code | Have participant add a test trigger: `// SCAN-TEST: eval(atob('dGVzdA=='))` in a comment — remove after test |
| "No suspicious patterns found" even with test trigger | Check if the agent is actually reading the recent commits — may need to explicitly point at commit diff tool |
| Alert issue doesn't have enough context | Enforce structure: "Each finding must include: file, line number, commit SHA, and one sentence explaining the risk" |

---

## How to Verify It's Working

1. Add a clearly fake test pattern to a file (e.g., a comment with `eval(atob(...))`) and commit to a branch, then merge
2. Trigger `workflow_dispatch`
3. Confirm an issue opens referencing the specific file and line number
4. Verify the issue explains why it was flagged (not just "found eval")
5. Remove the test pattern, commit, trigger again — confirm no issue opens

---

## Coaching Notes

The most important framing: this is an additional detection signal, not a replacement for code review. Socratic prompt: _"A CodeQL rule can detect known patterns. What could this workflow be prompted to examine beyond those rules?"_ Answer: novel patterns, contextual intent, cross-file reasoning, and things that may look unusual in context even without a CVE. Findings still require human review.

The "likely benign vs suspicious" classification step prevents excessive findings. Without it, every eval in a test file generates noise. Ask participants: _"If this fires every day with 50 findings, what happens to the team's trust in the tool?"_ Then have them add the likelihood gate.

Participants with security backgrounds often want to add more patterns. Encourage it — but cap at 5-7 patterns per run to keep the prompt focused and the output actionable.
