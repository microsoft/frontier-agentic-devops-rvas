# Coach Guide: Challenge 2-01 — Triage Bot

---

## Coaching Philosophy

This is the **entry point to event-driven automation**. Squads shift from manual triggers (`workflow_dispatch`) to reactive workflows (GitHub events). Your job: help them see that the *compile → run → observe loop* still holds—it just fires automatically now.

**Key rule:** By minute 25, every squad should see their triage label + comment appear on their test issue. That "wow, it worked automatically" moment is the entire goal.

---

## Expected Outcomes

A finished solution has these characteristics:

**File structure:**
- `.github/workflows/triage-bot.md` — ~25–35 lines (frontmatter + body)
- `.github/workflows/triage-bot.lock.yml` — auto-generated, ~60–80 lines

**Behavior:**
- Workflow runs on issue open (visible in Actions tab)
- One label from the allowlist is applied to the test issue
- A comment appears on the test issue within 30 seconds of creation
- Comment text includes:
  - The category (e.g., "This looks like a **bug**")
  - A reason (1 sentence)
  - An encouraging next step

**Example outcome:**
```
Issue: "Login button doesn't work on mobile"
Label applied: bug
Comment:
"Thanks for reporting this! We've categorized this as a **bug** — 
something isn't working as expected. A maintainer will investigate soon. 
In the meantime, let us know if you can share your browser/device details."
```

---

## Common Approaches

All valid. Squads will vary based on comfort with prompt writing.

### Approach 1: Simple Classification (Most Common)

Frontmatter lists all 5 labels with `safe-outputs: add-labels`. Body says:

```
Analyze this issue and pick the best label.
If you're uncertain, default to 'question'.
```

**Pros:** Fast, clear, low confusion  
**Cons:** Less robust AI reasoning (but good enough for learning)

### Approach 2: Detailed Decision Tree

Body includes reasoning steps:

```
First, look for keywords:
- If "broken", "error", "crash" → bug
- If "add feature", "we should" → feature-request
- If missing examples or clarity → documentation
- Otherwise → question
If none fit, use question as default.
Then post a comment explaining your choice.
```

**Pros:** More predictable, teaches structured prompts  
**Cons:** Longer, slightly over-engineered for 2-01

### Approach 3: Keyword + AI Hybrid

Mix a bash pre-step that extracts keywords with AI reasoning:

```
Pre-step: grep issue title/body for "bug", "feature", "docs", etc.
Agent: Use grep results as a hint; apply your judgment and post comment.
```

**Pros:** Teaching advanced patterns early  
**Cons:** Adds complexity; save for Track 3

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Workflow Doesn't Trigger

**Symptom:** Squads create test issue; nothing happens (no comment, no label).

**Root cause:** Most likely `on: issues:` is missing or malformed. Sometimes they use `on: issue:` (singular, wrong).

**Coach response:**
- "Did you set `on: issues: types: [opened]` in the frontmatter?"
- Show them: `issue_comment` (for comments) vs `issues` (for issue events)
- Have them recompile: `gh aw compile triage-bot.md`
- Then create a fresh test issue to trigger it

### Pitfall 2: Label Not Applied (But Comment Posted)

**Symptom:** Comment appears, but no label.

**Root cause:** Label name doesn't match the allowlist exactly, or permissions are too restrictive.

**Coach response:**
- "What label were you trying to apply?"
- Ask them to check: `safe-outputs: add-labels:` — is the label listed there?
- Spell-check together. YAML is case-sensitive.
- Also check permissions: should be at minimum `issues: read` or `contents: read` (safe-outputs handles writes)

### Pitfall 3: No Comment Posted

**Symptom:** Label applies correctly, but no comment appears.

**Root cause:** Typo in frontmatter (`add-comment` vs `add_comment`), or body instructions don't mention "post a comment."

**Coach response:**
- "Let's look at your frontmatter. Is `add-comment` listed under `safe-outputs:`?"
- Point them to: https://github.github.com/gh-aw/reference/safe-outputs/
- Suggest: "Make sure your body says something like: 'Post a comment explaining which category you chose.'"

### Pitfall 4: Generic/Robotic Comment

**Symptom:** Comment reads like a bot (no warmth, no personality).

**Root cause:** Squads don't realize the comment tone is part of the user experience.

**Coach response:**
- "Read your comment out loud. Would you want to receive that as a contributor?"
- Suggest: "Add your repo's voice. Instead of 'Category assigned: bug', try 'Thanks for reporting this! We've categorized it as a **bug**.'"
- Show them the sample solution's comment style (below)

### Pitfall 5: Overly Specific Label Rules

**Symptom:** Squads try to apply 20 labels or add logic for specific keywords.

**Root cause:** They're not trusting the AI to reason.

**Coach response:**
- "The AI is good at categorization. You don't need hardcoded rules."
- Suggest reducing to 4–5 labels: `bug`, `feature-request`, `documentation`, `question`, `duplicate`
- Emphasize: "Simpler allowlist = safer, faster, easier to debug"

### Pitfall 6: Permissions Set to `write-all`

**Symptom:** Frontmatter has `permissions: write-all` or `issues: write`.

**Root cause:** Misunderstanding; they think the agent needs write permissions directly.

**Coach response:**
- "Why do you think the agent itself needs write access?"
- Guide: "The agent reads the issue (needs `read`). Safe-outputs handles writing the label and comment — that's already configured."
- Show: `permissions: issues: read` or even `permissions: {}` (defaults to minimal)

---

## Sample Solution

This is a complete, working `triage-bot.md`. Share **only if a squad is truly stuck after 20+ min**, and ask them to type it out themselves.

```markdown
---
on:
  issues:
    types: [opened]

permissions:
  issues: read

safe-outputs:
  add-labels:
    allowlist: [bug, feature-request, documentation, question, duplicate]
  add-comment: {}

engines:
  - copilot
---

# Issue Triage Bot

Read this newly opened issue. Classify it into one of these categories:

- **bug**: Something is broken or doesn't work
- **feature-request**: A new capability or improvement
- **documentation**: Docs need clarification, examples, or correction
- **question**: User asking for help or information
- **duplicate**: Looks like an existing issue

Choose the best fit. If unsure, default to "question".

Apply one label from the list above using the safe-outputs tool.

Then post a friendly comment on the issue with:
1. The category you chose (make it bold)
2. A brief reason (1 sentence)
3. An encouraging next step (e.g., "thanks for reporting" or "we'll prioritize this")

Keep the comment warm and welcoming—this is our first interaction with the contributor.
```

**Why this works:**
- `on: issues: types: [opened]` — fires immediately when new issue created
- `permissions: issues: read` — minimal, agent doesn't write directly
- `safe-outputs: add-labels: allowlist:` — gates to 5 safe choices
- `safe-outputs: add-comment:` — permission granted to post comment
- Body: natural language, clear decision tree, emphasizes friendliness
- `engines: [copilot]` — free, reliable for classification

---

## Time Management

Suggest this breakdown:

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Read the challenge, ask questions |
| Write frontmatter | 5 min | Set up `on:`, `permissions`, `safe-outputs`, `engines` |
| Write body | 7 min | Draft classification logic + comment template |
| Compile & test | 8 min | Compile, create test issue, watch Actions tab |
| Debug & refine | 5 min | Fix any label/comment issues |
| Celebrate | 2 min | Discuss what you learned |

**Total: ~30 minutes.**

---

## Extension Ideas (for Fast Squads)

If a squad finishes in <20 minutes:

1. **Add PR triage:** Change trigger to `on: pull_request: types: [opened]` and classify PRs by size (xs/s/m/l/xl) based on diff stats
   - **Concept:** Event triggers beyond `issues`

2. **Conditional duplicate detection:** If the AI picks `duplicate`, post a follow-up comment with a link to the suspected original issue
   - **Concept:** Multi-step workflows, conditional logic

3. **Auto-assign to a team:** Use `safe-outputs: assign:` to assign the issue to a maintainer if it's labeled `bug`
   - **Concept:** Chaining multiple safe-outputs

4. **Add a status label:** Use `safe-outputs: add-labels:` to add a status label like `status/pending-review` in addition to the category
   - **Concept:** Multiple label application

5. **Scheduled batch triage:** Create a second workflow that runs daily and triages all *unlabeled* issues (use `on: schedule:`)
   - **Concept:** Batch vs. event-driven; combining two workflows

---

## Debugging Checklist (For You, the Coach)

If a squad is stuck:

- [ ] Is the workflow file named `triage-bot.md` in `.github/workflows/`?
- [ ] Did they run `gh aw compile triage-bot.md`?
- [ ] Does `.lock.yml` exist? (`ls .github/workflows/triage-bot.lock.yml`)
- [ ] Is frontmatter valid YAML? (spaces, not tabs; proper indentation)
- [ ] Is `on: issues:` spelled correctly? (not `issue:`)
- [ ] Are `add-labels` and `add-comment` listed in `safe-outputs:`?
- [ ] Did they create a fresh test issue *after* compiling?
- [ ] Are there logs in the Actions tab? (click the workflow run)
- [ ] Is the label in the allowlist? (check spelling, case)
- [ ] Is the comment appearing (even if label is wrong)?

If all check out and it still doesn't work, escalate to Ripley or check the Actions logs for the specific error message.

---

## Key Takeaways for Coaches

- **Event-driven = reactive:** This is the paradigm shift from Challenge 00. Celebrate that.
- **Safe-outputs = guardrails:** The allowlist isn't a limitation; it's what makes automation safe
- **Test rigorously:** Squads often forget to compile *or* forget to create a fresh issue after compiling
- **Tone matters:** Emphasize that the comment is part of the user experience—not just task completion
- **Small wins:** A working triage bot is genuinely useful. Squads should leave this challenge feeling "I could use this in my real repo"

---

## Reference

**Sample Solution Location:** `coaches/sample-solutions/track-2/2-01-triage-bot.md`  
**Issue Triage Agent (Real):** https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md  
**Safe Outputs Reference:** https://github.github.com/gh-aw/reference/safe-outputs/
