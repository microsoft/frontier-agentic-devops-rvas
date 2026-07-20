---

## Facilitated application

Required facilitator check-in: before completion, ask the customer practitioner to connect the exercise to work they actually own.

Discuss: Where has documentation bloat in your projects pushed contributors away, and how would you keep an agent from removing something important? Connect it to a project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask where documentation bloat has actually pushed contributors away in their world.
- Probe how they would stop an agent from removing something important.
- Get them to pick one bloated doc they'll let an unbloat agent propose trims for next week.

## What This Activity Teaches

The difference between correctness (what Doc Updater fixes) and quality (what Unbloat improves). Participants learn to write specificity into simplification prompts — "be concise" produces unreliable results, while "remove sentences starting with 'Note that'" gives the workflow a concrete criterion. They also practice PR discipline: one file, one concern, and a reviewable scope.


Official grounding: when customer delivery team members are unsure whether a frontmatter field or permission is valid, anchor them in the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions) and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) docs before they tune the agent prompt.

---

## Expected Solution Shape

```markdown
---
on:
  workflow_dispatch: {}
  schedule:
    - cron: "0 10 * * 1"

permissions:
  contents: write
  pull-requests: write

safe-outputs:
  create-pull-request: {}

engine: copilot
---

# Documentation Unbloat

Review `docs/getting-started.md` for verbosity and redundancy.

Remove or simplify:
- Sentences starting with "Note that", "Please be aware", or "It is important to"
- Duplicate information that appears elsewhere in the same file
- Code examples longer than 10 lines where a 3-line version conveys the same point
- Outdated warnings that no longer apply

Do NOT remove: Quick Start section, API reference tables, or any numbered step list.

Open a single PR with the changes. If the file is already concise, do nothing.
```

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Agent removes too much content | Add explicit preservation rules: "Do not remove sections marked with `<!-- keep -->`" |
| Proposed diff rewrites rather than trims | Enforce minimal change: "Remove or shorten — do not rewrite prose from scratch" |
| Agent reports "nothing to simplify" on very verbose docs | Sharpen the criteria: give a specific pattern to search for (e.g., "find all paragraphs with 'Note:' markers") |
| PR is opened every run even after merging | Add idempotency guard: "If an open PR already exists for this file, do not open another" |

---

## How to Verify It's Working

1. Find (or create) a verbose doc with at least 3 "Note that" sentences and a 20-line code example
2. Trigger `workflow_dispatch`
3. Confirm a PR opens with targeted cuts (not a rewrite)
4. Check the diff — does every removal make the doc better without losing information?
5. Merge and trigger again — confirm no duplicate PR opens

---

## Coaching Notes

Participants struggle to articulate "simplify" in a way the model can act on. The Socratic nudge: _"Read your body prompt. Could two people disagree about what counts as 'too verbose'? If yes, your criteria aren't specific enough."_

The difference between Unbloat and a human editing session is precision + repeatability. A human edits based on feel; the workflow edits based on explicit rules. That's a feature, not a limitation.

Fast squads: have them try combining 4-03 (accuracy) and 4-04 (quality) in sequence — Doc Updater fires first, Unbloat fires second. The chain produces both correct and clean docs.
