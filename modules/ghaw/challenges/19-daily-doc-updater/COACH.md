---

## Facilitated application

**Required facilitator check-in:** before completion, ask the customer practitioner to connect the exercise to work they actually own.

**Discuss:** Which docs in your projects silently rot as the code evolves, and what would it take for you to trust an agent's documentation PRs enough to review and merge them regularly? Connect it to a project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to name docs in their projects that silently drift from the code.
- Explore what would make them trust and actually merge an agent's documentation PRs.
- Have them choose one doc set they'll put under a daily doc-updater next week.

## What This Activity Teaches

Scheduled automation with `create-pull-request` safe-output. Participants learn to think about docs as a living artefact that drifts from code, how to write prompts that detect drift (not just "review docs"), and how to produce focused, mergeable PRs rather than wholesale rewrites.


Official grounding: when customer delivery team members are unsure whether a frontmatter field or permission is valid, anchor them in the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions) and [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) docs before they tune the agent prompt.

---

## Expected Solution Shape

```markdown
---
on:
  schedule:
    - cron: "0 9 * * *"
  workflow_dispatch: {}

permissions:
  contents: write
  pull-requests: write

safe-outputs:
  create-pull-request: {}

engine: copilot
---

# Daily Documentation Updater

Review the documentation in `docs/` against the current codebase.

Focus on:
- API endpoints documented in `docs/api.md` that no longer match `src/routes/`
- Configuration options listed in `docs/config.md` that don't exist in `src/config.ts`
- Code examples that reference deprecated function signatures

For each piece of outdated content found, open a separate PR with the correction.
Keep each PR to a single file change. Write accurate, minimal diffs — do not rewrite sections that are still correct.

If no drift is found, do nothing.
```

The key elements: `workflow_dispatch` alongside cron (for testing), `contents: write` + `pull-requests: write`, a focused doc scope, and explicit "if nothing found, do nothing."

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| Can't trigger manually | Add `workflow_dispatch: {}` to `on:` block |
| PR contains changes to 20+ files | Constrain scope in body: "Review only `docs/api.md`" |
| Agent keeps proposing the same PR every day | Add: "Do not open a PR if an open PR for this file already exists" |
| PR diff rewrites entire sections | Add: "Make minimal changes. Only modify lines that are factually incorrect." |
| Cron fires at unexpected times | Remind: cron is UTC. `0 9 * * *` = 9am UTC, which may be afternoon/evening locally |

---

## How to Verify It's Working

1. Introduce deliberate doc drift — change a function name in code but leave the doc unchanged
2. Trigger the workflow manually (`workflow_dispatch`)
3. Confirm a PR opens referencing the specific drifted line
4. Check the PR diff is focused (not a full rewrite)
5. Merge the PR — confirm the workflow doesn't propose the same change again next run

---

## Coaching Notes

Focused PRs are easier to review than one large rewrite. Participants often produce one big PR that rewrites everything. Redirect: _"Would you review and merge a 200-file PR? What scope would make this change practical to review?"_

The "if nothing found, do nothing" instruction is important — without it, the agent may open empty PRs or cosmetic changes just to have output. Ask participants: _"What happens if the agent runs every day but there's nothing to fix?"_
