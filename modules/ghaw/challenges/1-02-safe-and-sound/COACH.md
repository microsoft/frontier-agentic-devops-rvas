# Coach Guide: Challenge 1-02 — Safe & Sound

---

## Coaching Philosophy

This is the **permission & safety challenge**. It's not about complexity—it's about internalizing two truths:

1. **Every workflow must call a safe-output** (or it fails)
2. **Permissions should be minimal** (read-only by default, never overpermission)

Your job is to build confidence in the safety model. When squads see that `noop` is a legitimate success state, they start trusting gh-aw's guardrails.

---

## Common Pitfalls & Coaching Responses

### Pitfall 1: Forgot to declare safe-outputs in frontmatter
**Symptom:** Compilation succeeds, but workflow fails with "no safe-output was called" or similar error.

**Root cause:** They wrote the body but forgot that safe-outputs is a **frontmatter declaration**, not a runtime instruction.

**Coach response:**
- "Safe-outputs aren't just instructions in the body—they're declarations in the frontmatter. It's like saying to GitHub: 'This workflow *might* create an issue, and here are the rules.'"
- Show them:
  ```yaml
  safe-outputs:
    create-issue:
      title-prefix: "[Scan] "
    noop:
  ```
- Explain: "Now when the agent runs, it knows it can either create an issue OR call noop. Nothing else."

---

### Pitfall 2: Only declared one safe-output (usually forgot `noop:`)
**Symptom:** Workflow has `safe-outputs: create-issue:` but when the condition isn't met, the agent doesn't know what to do.

**Root cause:** They didn't realize the agent needs an escape hatch for the "don't create" case.

**Coach response:**
- "Your safe-outputs only has `create-issue:`. What should the agent do if the condition isn't met?"
- Guide: "Add `noop:` to your safe-outputs. It means 'do nothing, but signal success.'"
- Reinforce: "Noop is not a failure; it's the safety valve. Every conditional workflow needs it."

---

### Pitfall 3: Overpermissioning
**Symptom:** Workflow has `permissions: write-all` or `permissions: pull-requests: write` when it doesn't need it.

**Root cause:** Misunderstanding that safe-outputs has its own permission model.

**Coach response:**
- "Why does this workflow need pull-request write access?"
- Guide them: "If you're only *reading* the repo and *creating an issue*, that's `contents: read` and `safe-outputs` handles the rest."
- Explain: "safe-outputs is like a separate layer. Your code = minimal permissions. safe-outputs = explicit, scoped writes."
- Real example: "If your workflow queries issues and creates issues, use `contents: read`. The GitHub Actions token isn't writing PRs—safe-outputs is writing issues."

---

### Pitfall 4: Conditional logic too vague for the agent
**Symptom:** Agent creates an issue when it shouldn't, or vice versa.

**Root cause:** Instructions like "create an issue if things look bad" without defining "bad."

**Coach response:**
- "What does 'bad' mean in your workflow?"
- Guide them to measurable conditions: "If the repo has >10 TODO comments" or "if any file is >1000 lines."
- Test: "Simplify to a trivial condition first—like 'file count > 5'—and get that working. Then iterate."

---

### Pitfall 5: Not including `workflow_dispatch` for testing
**Symptom:** They can't test the workflow without waiting for a schedule.

**Root cause:** They only wrote `on: schedule:` or `on: push:` without `workflow_dispatch:`.

**Coach response:**
- "Add `workflow_dispatch:` to your `on:` so you can test manually from the Actions tab."
- Show: "In the Actions tab, you'll see a 'Run workflow' button. Click it, select a branch, and the workflow runs immediately."
- This speeds up iteration dramatically.

---

### Pitfall 6: Indentation errors in safe-outputs block
**Symptom:** YAML parse error during compilation.

**Root cause:** Safe-outputs isn't indented correctly or mixed tabs/spaces.

**Coach response:**
- "Let's look at your frontmatter. Safe-outputs is indented under the root, right?"
- Show them correct:
  ```yaml
  ---
  on: schedule: ...
  permissions: ...
  safe-outputs:
    create-issue:
      title-prefix: "[...]"
    noop:
  engines: ...
  ---
  ```
- Remind: "2 or 4 spaces per level, consistent throughout."

---

## Sample Solution

Here's a working `safe-sound.md` that scans for TODOs:

```markdown
---
on:
  workflow_dispatch:
  schedule:
    - cron: '0 8 * * *'

permissions:
  contents: read

safe-outputs:
  create-issue:
    title-prefix: '[TODO Scan] '
  noop:

engines:
  - copilot

tools:
  github:
    toolsets:
      - issues
---

# Safe & Sound: TODO Scan

Your task:
1. Use bash and git to find all TODO comments in the repository (search for "TODO:" or "FIXME:")
2. Count them
3. If there are more than 3 TODOs, create an issue titled "TODOs found in repo" with a list of files and counts
4. If there are 3 or fewer TODOs, call noop (do nothing, but signal success)

Keep the logic clear and the issue body concise — just filename and count, no code snippets.
```

**Why this works:**
- Declares both `create-issue:` and `noop:`
- `permissions: contents: read` — minimal
- Uses bash tool (simpler than git API for this use case)
- Clear condition: >3 TODOs = issue, ≤3 = noop
- `workflow_dispatch:` lets them test immediately
- Body: clear, measurable instructions

**Production-ready reference solution:** See `coaches/sample-solutions/track-1/1-02-safe-and-sound.md`

---

## Time Management

Suggest this breakdown:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Discuss safe-outputs + noop model |
| Write the .md file | 10 min | Create frontmatter with both safe-outputs, write condition |
| Compile & debug | 5 min | Fix any YAML indentation issues |
| Manual trigger + verify | 10 min | Test both paths (noop and issue creation) |

**Total: ~30 minutes.**

---

## Debugging Checklist

If a squad is stuck:

- [ ] Does the frontmatter have both `safe-outputs: create-issue:` and `safe-outputs: noop:`?
- [ ] Is `safe-outputs:` indented at the root level, not nested under `on:` or `permissions:`?
- [ ] Are permissions set to `contents: read` or similar (not `write-all`)?
- [ ] Did `gh aw compile` succeed and produce `.lock.yml`?
- [ ] Is `workflow_dispatch:` in the `on:` block so they can test manually?
- [ ] When they trigger manually, do the logs show the agent deciding between paths?
- [ ] Does the "no-op" case succeed (look for "noop called" in logs)?
- [ ] Does the "create issue" case succeed (check the Issues tab)?

---

## Extension Ideas

If a squad finishes early:

1. **Add result tracking:** Use `safe-outputs: create-issue: max: 1` and `close-older-issues: true` so only the latest scan issue exists
   - Concept: lifecycle management of automated issues

2. **Parameterize the threshold:** Instead of hardcoding >3 TODOs, have the agent read a config file (e.g., `.github/todo-config.json`)
   - Concept: external configuration + agent adaptation

3. **Multiple conditions:** Have three paths: (1) ≤2 TODOs = silent noop, (2) 3-10 TODOs = create issue, (3) >10 TODOs = create issue + add high-priority label
   - Concept: nuanced conditional logic in natural language

4. **Add a safety check:** Before creating the issue, have the agent verify that an issue with the same title doesn't already exist
   - Concept: idempotency and avoiding duplicates

5. **Run on PR:** Trigger on `pull_request: types: [opened]`, scan the PR diff for new TODOs, and comment on the PR
   - Concept: event-driven safety gates

---

## Key Takeaways for Coaches

- **Safe-outputs is the contract:** It's not a suggestion; it's a declaration. No workflow works without it.
- **Noop is not failure:** When squads see a successful noop, they start understanding the safety model.
- **Minimal permissions by default:** This is a habit worth building early. Read-only first; escalate only if needed.
- **This challenge builds trust:** After Challenge 1-02, squads believe gh-aw can be trusted in production.
