# Coach Guide: Challenge 3-05 — Ship It (The Capstone)

---

## Coaching Philosophy for This Challenge

This is **the capstone**. Squads that reach here are advanced. Your job is not to teach them new concepts—they've learned everything. Your job is to **help them integrate** and **celebrate the aha moment** when the whole system runs end-to-end.

**Key rule:** Help them break the problem into pieces. Observer → Triage → ChatOps. Get each working independently, then wire them together.

**Secondary rule:** If they get stuck in complexity, scale back. Two workflows + one manual step is better than five workflows broken. Celebrate what works.

---

## Expected Outcomes

A finished solution has:

**3 Workflows (minimum):**

1. **`event-observer.md`** (~20 lines)
   - Triggers on issue open
   - Writes JSON to `repo-memory/observations/YYYY-MM-DD-HH-mm.json`
   - Calls `safe-outputs: noop`

2. **`triage-meta-workflow.md`** (~35 lines)
   - Triggers on schedule (e.g., every 30 min)
   - Reads from `repo-memory/observations/**/*.json`
   - Creates a tracking issue with observed issues + checklist
   - Calls `safe-outputs: create-issue: lock-for-agent: true`

3. **`chatops-fixer.md`** (~25 lines)
   - Triggers on `issue_comment: types: [created]`
   - Detects `/fix` in comment body
   - Calls `safe-outputs: assign-to-agent: target: triggering, allowed: [copilot]`

**Optional 4th Workflow:**
- `pr-merger.md`: Auto-merge or label PRs from Copilot

**End-to-end flow:**
1. Open an issue (or scheduled observer triggers)
2. Observer records to repo-memory
3. Triage workflow creates tracking issue
4. Human (or bot) comments `/fix` on tracking issue
5. ChatOps workflow assigns to Copilot
6. Copilot creates a PR with the fix
7. (Optional) PR auto-merges or gets labeled

---

## Common Approaches

Squads will vary:

### Approach 1: "Minimum Viable" (most common)
- Observer + Triage + ChatOps: 3 workflows, each does one thing
- Manual PR merge (human approval step)
- Simple JSON for observations

**Pros:** Focused, achievable in 30 min, demonstrates the pattern
**Cons:** Less complete than the ideal

### Approach 2: "Full Factory"
- All 4 workflows: Observer, Triage, ChatOps, Auto-Merger
- Complex observation data (urgency, labels, priority)
- Automatic end-to-end with no human intervention

**Pros:** Production-grade
**Cons:** Risk of time-box overrun

### Approach 3: "Simplified Chain"
- Only Observer + manual steps (skip Triage and ChatOps)
- Emphasizes repo-memory data passing

**Cons:** Doesn't showcase orchestration fully, but acceptable if complexity blocks them

**Coach guidance:** Prefer Approach 1 (3 workflows) as the target. Approach 2 is ambitious but encouraged if squad is moving fast.

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Trying to build all 5 workflows at once
**Symptom:** Squad gets stuck on wiring, nothing works. Frustration mounts.

**Root cause:** Complexity overload. They're thinking systems instead of building incrementally.

**Coach response:**
- "Let's slow down. Build one workflow first. Get Observer writing to repo-memory. Test it in isolation."
- "Once Observer works, move to Triage. Each workflow should be a small, achievable piece."
- This is a fundamental **divide-and-conquer** lesson.

### Pitfall 2: Data doesn't flow between workflows
**Symptom:** Observer runs, but Triage can't read the JSON files.

**Root cause:** File path mismatch, glob filter issue, or data wasn't actually written.

**Coach response:**
- "Let's verify: does the Observer file show up in repo-memory branch?"
- "What path did Observer write to? What glob did Triage specify?"
- "Do they match? If Observer writes `observations/2026-05-28.json` and Triage uses `glob: observations/**/*.json`, they match."
- This is the classic repo-memory gotcha (see Challenge 3-01).

### Pitfall 3: Triage creates duplicate tracking issues
**Symptom:** Every 30 minutes, a new tracking issue is created instead of updating one.

**Root cause:** Missing `lock-for-agent: true` or `max: 1, close-older-issues: true`.

**Coach response:**
- "You need to prevent duplicates. Either use `lock-for-agent: true` on the trigger, or use `safe-outputs: create-issue: max: 1, close-older-issues: true` to keep only one active."
- "Which approach would you prefer?" → Guide them to the right pattern.

### Pitfall 4: ChatOps `/fix` command not triggering
**Symptom:** Squad comments `/fix` on the tracking issue, but nothing happens.

**Root cause:** Workflow trigger isn't set up correctly, or the `if:` condition doesn't match.

**Coach response:**
- "Let's check the trigger. You have `on: issue_comment: types: [created]`?"
- "Now check the `if:` condition. It should be something like: `if: contains(github.event.comment.body, '/fix')`"
- "And `lock-for-agent: true` to prevent race conditions?"
- Have them walk through the logic.

### Pitfall 5: `assign-to-agent` call fails
**Symptom:** Logs show "assign-to-agent safe-output failed" or "Copilot not available".

**Root cause:** Frontmatter configuration is wrong, or target is invalid.

**Coach response:**
- "Check your `safe-outputs:` section. It should look like:"
  ```yaml
  safe-outputs:
    assign-to-agent:
      target: triggering
      allowed: [copilot]
  ```
- "Does that match what you have?"
- If still failing: "Is Copilot available in this repo? (It should be by default.)"

### Pitfall 6: Too much time spent on PR auto-merge
**Symptom:** Squad spends 20 min trying to get PR auto-merge working and runs out of time.

**Root cause:** Overambition. Workflow 4 (PR Merger) is optional and complex.

**Coach response:**
- "Let's pause on auto-merge. You've built Observer → Triage → ChatOps. That's the core factory. That's the win."
- "For the merge step, we can do it manually or with a simple label for now."
- "If time allows, we can add it. But the main pattern is proven."
- This is a **scope management** moment.

### Pitfall 7: Workflows don't run in the right order
**Symptom:** Triage runs before Observer has time to write data.

**Root cause:** No coordination—workflows are asynchronous and can't depend on each other.

**Coach response:**
- "Workflows don't wait for each other. You have a few options:"
  - Observer writes data continuously. Triage runs on a schedule and reads *whatever data exists*.
  - Or: Triage runs infrequently enough that Observer has time to write before the next triage run.
  - Or: Manual triggering for testing (use `workflow_dispatch` on Triage to test with existing data).
- "For this challenge, running on a schedule (every 30 min) is fine—there will be data by then."

### Pitfall 8: Slash command body check is wrong
**Symptom:** ChatOps workflow triggers on *any* comment, not just `/fix`.

**Root cause:** Missing the body check, or `if:` condition is always true.

**Coach response:**
- "Your `if:` condition should check if the comment contains `/fix`. Try:"
  ```yaml
  if: contains(github.event.comment.body, '/fix')
  ```
- "Test by commenting `/fix` and commenting `hello` separately. Only `/fix` should trigger the workflow."

---

## Coaching Questions

1. **"Draw me the flow. Observer → ? → ? → ?"** → Test their mental model
2. **"How does data flow from Observer to Triage?"** → Should answer: "Through repo-memory"
3. **"What happens if Triage creates a duplicate tracking issue?"** → Should recognize the problem and propose a fix
4. **"Show me your ChatOps `/fix` check. How do you detect the command?"** → Look at the `if:` condition
5. **"If you're out of time, which piece is least important to finish?"** → Wisdom: PR auto-merge is nice-to-have, not must-have
6. **"Run through the end-to-end. What would you see at each step?"** → Narrative verification

---

## Sample Solution

This is complex, so I'll give **compact examples** of each workflow. Have squad flesh them out.

**1. `event-observer.md`:**

```markdown
---
on:
  issues:
    types: [opened]

permissions:
  contents: read
  issues: read

safe-outputs:
  noop:

tools:
  github:
    toolsets: [issues]
  repo-memory:
    file-glob: 'observations/**/*.json'

engines:
  - copilot

checkout: false
---

# Event Observer

Record each new issue as an observation to repo-memory.

Fetch the issue details: title, labels, urgency (guess based on labels or title).

Write to repo-memory as JSON:
```json
{
  "timestamp": "2026-05-28T14:54:00Z",
  "type": "issue_opened",
  "number": 42,
  "title": "...",
  "labels": [...],
  "urgency": "high"
}
```

File path: `observations/{timestamp}.json` where timestamp is YYYY-MM-DD-HH-MM-SS.

After writing, call noop.
```

**2. `triage-meta-workflow.md`:**

```markdown
---
on:
  schedule:
    - cron: '*/30 * * * *'
  workflow_dispatch:

permissions:
  contents: read
  issues: write

safe-outputs:
  create-issue:
    lock-for-agent: true
    max: 1
    close-older-issues: true

tools:
  repo-memory:
    file-glob: 'observations/**/*.json'

engines:
  - copilot

checkout: false

max-effective-tokens: 3000000
---

# Triage Meta-Workflow

Read observations from repo-memory. Create a tracking issue.

1. Read all JSON files from observations/
2. Parse each one: extract title, urgency, number
3. Group by urgency (high, medium, low)
4. Create an issue titled "Triage Report" with:
   - [ ] Checkboxes for each observed issue
   - Section for high-urgency items (at top)
   - Call to action: "Review these issues. If critical, comment `/fix` on this issue."

After creating issue, call noop.
```

**3. `chatops-fixer.md`:**

```markdown
---
on:
  issue_comment:
    types: [created]

if: contains(github.event.comment.body, '/fix')

permissions:
  contents: read
  issues: read
  pull_requests: write

safe-outputs:
  assign-to-agent:
    target: triggering
    allowed: [copilot]

tools:
  github:
    toolsets: [issues]

engines:
  - copilot

checkout: false

lock-for-agent: true
---

# ChatOps Fixer

When someone comments `/fix` on an issue, assign it to the Copilot coding agent.

1. Read the comment and the issue
2. Extract sub-issues or tasks from the issue (if any)
3. Assign to Copilot with instructions: "Fix the issues mentioned in this issue. Create a PR with your fixes."
4. Call assign-to-agent safe-output

Copilot will take it from here.
```

---

## Why This Works

- **Observer:** Simple data collection. Writes to repo-memory. Tests the "producer" pattern.
- **Triage:** Meta-workflow reading that data. Demonstrates consumption and decision-making.
- **ChatOps:** Interactive layer. Shows how humans (or other workflows) trigger the pipeline.
- **Together:** A complete autonomous factory that responds to events, triages, and acts.
- **Pattern:** This is the "Factory Capstone" from the dossier—event → persist → triage → act.

---

## Time Management

This is ambitious for 30 min. Here's a suggested flow:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 5 min | Understand the factory concept. Sketch the flow. |
| Build Observer | 8 min | Write, compile, test. Verify repo-memory file appears. |
| Build Triage | 8 min | Write, compile, test. Create a tracking issue. |
| Build ChatOps | 6 min | Write, compile, test `/fix` command. |
| End-to-end test | 2 min | Trigger flow, watch it happen |
| Celebrate | 1 min | Victory lap 🎉 |

**If running late:** Skip PR auto-merge. Get Observer → Triage → ChatOps working.

---

## Extension Ideas (Bonus)

1. **PR Auto-Merger:** Add a 4th workflow that auto-merges Copilot's PR if all checks pass.
2. **Escalation:** If Copilot's fix fails 3 times, escalate to a human-review issue.
3. **Metrics:** Add Overseer to track how many issues this factory fixes per week.
4. **Multi-language:** Extend Observer to monitor multiple repos (org-wide factory).

---

## Debugging Checklist

- [ ] Observer workflow compiles and runs?
- [ ] JSON files appear in repo-memory branch?
- [ ] Triage workflow compiles and runs?
- [ ] Tracking issue created?
- [ ] `lock-for-agent: true` preventing duplicates?
- [ ] ChatOps workflow has correct `/fix` trigger?
- [ ] ChatOps successfully calls `assign-to-agent`?
- [ ] Copilot receives the assignment?

---

## Key Takeaways for Coaches

- **This is the capstone.** Squads who finish this understand production automation.
- **Celebrate the "aha moment."** When they see Observer → Triage → ChatOps → Copilot all run end-to-end, that's the moment they "get it."
- **Systems thinking matters.** This challenge teaches composition and orchestration, not just individual workflows.
- **Scope is OK to reduce.** If they build a solid 2-workflow system instead of 4, that's still a huge win.
- **Document the flow.** A squad that can explain "issue comes in, gets recorded, gets triaged, gets fixed" has internalized the pattern.

---

## Beyond This Challenge

Squads that finish Ship It are ready for:
- Production agentic automation
- Real codebases with complex workflows
- Building teams around autonomous systems
- The Future™
