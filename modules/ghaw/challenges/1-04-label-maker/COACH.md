# Coach Guide: Challenge 1-04 — Label Maker

---

## Coaching Philosophy

This is the **event-driven classification challenge** — the capstone of Track 1. Squads are now confidently writing workflows triggered by real repository events (not schedules) and using AI to make meaningful decisions. Your job is to cement the pattern: event → query → classify → act.

**Key insight:** By now, squads should see that gh-aw workflows are deterministic (you specify the trigger, the data, and the decision) and auditable (logs show exactly what happened).

---

## Common Pitfalls & Coaching Responses

### Pitfall 1: Label names don't exist in the repo
**Symptom:** Workflow runs, agent picks a label, but nothing appears on the issue.

**Root cause:** Agent tried to apply a label (e.g., "bug-fix") that isn't defined in the repo's Labels list.

**Coach response:**
- "Let's check your repo's Labels. Go to the Labels tab and see what labels exist."
- Guide: "The allowlist in safe-outputs must match labels that actually exist in the repo."
- Quick fix: "Go create the labels first, then the agent can apply them."
- Pro tip: "Your allowlist can include labels that don't exist yet—GitHub will create them when applied. But it's better practice to define them upfront."

---

### Pitfall 2: Workflow doesn't fire on issue open
**Symptom:** They open an issue, but the workflow doesn't run.

**Root cause:** Either (a) frontmatter is missing `on: issues: types: [opened]`, or (b) they didn't save the file to the repo.

**Coach response:**
- "Let's verify your `on:` block. Do you have `on: issues: types: [opened]`?"
- Explain: "The workflow needs to be in the `.github/workflows/` directory and committed to the repo. It won't run if it's only in their local copy."
- Checklist: "Did you commit and push the workflow .md file?"

---

### Pitfall 3: Agent classification is wrong or inconsistent
**Symptom:** Agent labels one issue correctly, but misclassifies another with similar content.

**Root cause:** Instructions are ambiguous or the agent is working without enough context.

**Coach response:**
- "What's your classification logic? Read it out loud."
- Guide them to clearer rules: "If the title contains 'Bug:', it's a bug. If it contains 'Feature:', it's a feature. Otherwise, if the body has example code, it's likely a question."
- Test: "Open 5 test issues with different titles and see if the agent is consistent. Refine your logic based on the results."

---

### Pitfall 4: Overly permissive label allowlist
**Symptom:** Agent creates random labels not in the allowlist.

**Root cause:** Safe-outputs config doesn't actually specify an allowlist, or allowlist is too broad.

**Coach response:**
- "Your safe-outputs should specify exact labels. For example: `safe-outputs: add-labels: labels: [bug, feature, question]`"
- Show them: "This means the agent can ONLY apply these three labels. It can't invent others."
- Verify: "Check your frontmatter — is the allowlist enforced?"

---

### Pitfall 5: Agent doesn't have enough context
**Symptom:** Agent applies a generic label or asks for clarification instead of making a decision.

**Root cause:** Instructions don't tell the agent to read the full issue body or use specific heuristics.

**Coach response:**
- "What information is the agent using to classify? Just the title?"
- Guide: "Include something like: 'Read the title and body of the issue. Look for keywords like \"error\", \"question\", \"request\". Use these to decide the category.'"
- Reinforce: "More context = more confident classification."

---

### Pitfall 6: Wrong permissions for issue labeling
**Symptom:** Workflow runs but fails with a permission error when trying to apply labels.

**Root cause:** Permissions are too restrictive or don't include issues scope.

**Coach response:**
- "Check your permissions. To read and label issues, you need at least `issues: read`."
- Guide: "Actually, safe-outputs handles the write, so you might just need `contents: read`. But let's check the logs to see the actual error."

---

## Sample Solution

Here's a working `label-maker.md`:

```markdown
---
on:
  issues:
    types:
      - opened
  workflow_dispatch:

permissions:
  contents: read

safe-outputs:
  add-labels:
    labels:
      - bug
      - feature
      - question
      - documentation
      - help-wanted
  noop:

engines:
  - copilot
---

# Label Maker

Classify the newly opened issue and apply the appropriate label.

Read the issue title and body. Use these heuristics:
- If it describes a problem or error: label "bug"
- If it requests a new capability: label "feature"
- If it asks for help or clarification: label "question"
- If it's about docs: label "documentation"
- If the author is new and asking for guidance: label "help-wanted"

If none of these fit clearly, call noop (do not apply a label).

Explain your reasoning in a comment on the issue summarizing why you applied (or didn't apply) a label.
```

**Why this works:**
- `on: issues: types: [opened]` — fires when issues are opened
- `permissions: contents: read` — minimal
- `safe-outputs: add-labels:` with explicit allowlist — constrained labels
- `noop:` path — escape hatch for unclear cases
- `engines: [copilot]` — reliable default
- Body: clear heuristics with keywords and examples
- Includes feedback comment so user understands the classification

**Production-ready reference solution:** See `coaches/sample-solutions/track-1/1-04-label-maker.md`

---

## Time Management

Suggest this breakdown:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Verify repo has labels defined; discuss classification logic |
| Write the .md file | 8 min | Frontmatter + body with heuristics |
| Compile & test | 5 min | Fix any YAML errors |
| Create test issues | 10 min | Open 3-5 test issues with different content and verify labels |
| Refine | 2 min | Adjust classification logic if needed |

**Total: ~30 minutes.**

---

## Debugging Checklist

If a squad is stuck:

- [ ] Does the repo have labels defined? (go to Labels tab on GitHub)
- [ ] Are the labels in the safe-outputs allowlist? (check frontmatter)
- [ ] Is `on: issues: types: [opened]` in the frontmatter?
- [ ] Did they commit and push the workflow file?
- [ ] When they open an issue, does the workflow appear in Actions?
- [ ] Do the logs show the agent classifying the issue?
- [ ] Does the label appear on the issue?
- [ ] Is the safe-outputs allowlist enforced? (check the compiled `.lock.yml`)
- [ ] Did they add `noop:` for cases where no label applies?

---

## Extension Ideas

If a squad finishes early:

1. **Add a comment explaining the label:** Use `safe-outputs: add-comment:` alongside `add-labels:` so the agent explains its reasoning
   - Concept: multi-output workflows

2. **Batch triage:** Add `on: schedule: daily` to classify all unlabeled issues daily, not just new ones
   - Concept: combining event-driven and scheduled triggers

3. **PR labeling:** Change to `on: pull_request: types: [opened]` and classify PRs instead of issues
   - Concept: same pattern, different event type

4. **Advanced heuristics:** Use `tools: github: toolsets: [issues]` to query related issues and use similarity for classification
   - Concept: contextual decision-making with external data

5. **Multi-label assignment:** Allow the agent to apply multiple labels (e.g., "bug" + "needs-investigation")
   - Concept: richer classification beyond single-choice

---

## Key Takeaways for Coaches

- **Event-driven triage is production-grade:** This is exactly how the real issue-triage-agent in gh-aw works.
- **Classification is a core AI task:** Squads are now confident that natural language + clear heuristics = reliable automation.
- **Safe-outputs guardrails matter:** The allowlist and noop path make this workflow trustworthy at scale.
- **Real issues = real learning:** Testing with actual GitHub issues is far better than mocks.

This is the capstone of Track 1. Squads who finish it should feel ready for Track 2.
