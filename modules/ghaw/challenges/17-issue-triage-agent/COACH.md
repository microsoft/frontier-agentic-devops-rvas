---

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — if you deployed this proven triage agent on your busiest repo tomorrow, what would you measure to decide whether it is actually saving the team time rather than adding noise? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to name their busiest repo and the volume of incoming issues there.
- Probe what 'saving time' versus 'adding noise' would actually look like in that backlog.
- Have them define the metric and one repo where they'll trial the triage agent next week.

## What This Challenge Teaches

The fundamentals of production agentic workflows: event-driven triggering on `issues`, constrained tool access via `toolsets`, and safe-outputs that prevent unintended side effects. This is the pattern every other production workflow builds on — participants leave understanding why allowlists matter and how to prevent label hallucination.


Official grounding: when students are unsure whether a frontmatter field or permission is valid, anchor them in the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions) and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) docs before they tune the agent prompt.

---

## Expected Solution Shape

```markdown
---
on:
  issues:
    types: [opened, reopened]

permissions:
  issues: write

safe-outputs:
  add-labels: {}
  add-comment: {}

tools:
  github:
    toolsets: [issues, labels]

engine: copilot
---

# Issue Triage Agent

Read the issue title and body. Using only labels from this list: [bug, enhancement, docs, question, good first issue], apply 1-3 labels that best describe the issue.

After labelling, post a brief comment explaining the categorisation in one sentence.

Do not create new labels. If no label fits clearly, apply `question` and note the ambiguity in the comment.
```

The key elements: explicit allowlist in the body, `add-labels` + `add-comment` in safe-outputs, `toolsets: [issues, labels]` for label lookup.

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Agent creates labels that don't exist | Add explicit allowlist to body: "Only use labels from: [...]" |
| Labels applied but no comment appears | Check `add-comment` is in `safe-outputs`, not just `add-labels` |
| "Insufficient permissions" in run log | Needs `issues: write` in permissions block |
| Workflow doesn't fire on existing issues | `reopened` covers re-triaging; `opened` only fires on new issues |
| Agent applies 5+ labels to every issue | Add constraint: "Apply 1-3 labels maximum" |

---

## How to Verify It's Working

1. Open a new issue with a clear topic (e.g., "Button not working on mobile" → should get `bug`)
2. Check the Actions tab — confirm the workflow ran
3. Verify the issue now has labels AND a comment
4. Open an issue that's ambiguous — confirm the agent handles it gracefully (applies `question`, explains why)
5. Confirm no invented labels appear

---

## Coaching Notes

The most common failure mode is label hallucination — the agent invents labels that sound reasonable but don't exist in the repo. Socratic prompt: _"What happens if the model suggests a label your repo doesn't have? How would you prevent that?"_ Lead them to the allowlist solution themselves.

The `toolsets: [issues, labels]` is the technical answer; the allowlist in the body is the safety net. Both are needed.
