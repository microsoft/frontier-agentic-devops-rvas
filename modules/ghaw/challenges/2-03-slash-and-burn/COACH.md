# Coach Guide: Challenge 2-03 — Slash & Burn

---

## Coaching Philosophy

This is the **ChatOps entry point**—moving from passive (reactions to events) to active (users commanding agents). Squads learn that slash commands transform workflows into tools their team *uses*. Your job: help them see that `/summarize` is genuinely useful and that the pattern generalizes (to `/triage`, `/explain`, etc.).

**Key rule:** By minute 25, the squad should see a `/summarize` comment trigger a summary response. That moment—"I asked the agent a question and it answered"—is transformative.

---

## Expected Outcomes

A finished solution has these characteristics:

**File structure:**
- `.github/workflows/slash-commands.md` — ~35–50 lines (frontmatter + body)
- `.github/workflows/slash-commands.lock.yml` — auto-generated, ~80–100 lines

**Behavior:**
- Workflow runs on new comments
- Only executes when comment contains `/summarize`
- Reads full issue + all comments
- Posts summary comment within 30 seconds
- Ignores other comments (no accidental triggers)

**Example outcome:**
```
Issue: "Performance regression in login flow"
[Lots of comments with discussion...]

Comment posted: `/summarize`

[Bot replies]:
## Summary

**Issue:** Performance degradation when users log in (>2s latency).

**Key Discussion:**
- Root cause: N+1 query in auth middleware (identified by @alice)
- Agreed to add caching layer (Redis)
- Blocked on security review from @bob

**Action Items:**
- [ ] Implement Redis cache (assigned @charlie)
- [ ] Security review (waiting for @bob)

**Status:** Blocked pending review. Expected resolution this week.
```

---

## Common Approaches

All valid.

### Approach 1: Simple Slash Check (Most Common)

Frontmatter uses `if:` to gate execution:

```yaml
on:
  issue_comment:
    types: [created]

env:
  TRIGGER_COMMAND: /summarize
```

Body says: "If the comment starts with `/summarize`, read the issue and all comments, then post a summary."

**Pros:** Clear, teachable, focuses on command detection  
**Cons:** Doesn't scale to multiple commands easily

### Approach 2: Multi-Command Router

Body checks for multiple commands:

```
If comment contains '/summarize': [summarize logic]
Else if comment contains '/triage': [triage logic]
Else: do nothing
```

**Pros:** More scalable, teaches conditional branching  
**Cons:** Longer body, more complex

### Approach 3: Conditional Workflow with `if:`

Frontmatter uses `if:` to gate the entire job:

```yaml
on:
  issue_comment:
    types: [created]

jobs:
  summarize:
    if: contains(github.event.comment.body, '/summarize')
```

**Pros:** Efficient (doesn't even compile if command not present)  
**Cons:** Less accessible to beginners

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Workflow Triggers on Every Comment

**Symptom:** Every comment posted to the issue triggers a workflow run.

**Root cause:** Missing `if:` check or body doesn't filter for `/summarize`.

**Coach response:**
- "Look at the Actions tab. Did every single comment trigger a run?"
- "Your body needs to check: 'If the comment contains `/summarize`, then proceed. Otherwise, do nothing.'"
- Show them: in the body, add `if comment starts with "/summarize"` check before posting summary

### Pitfall 2: Concurrent Runs / Duplicate Summaries

**Symptom:** Multiple copies of the summary comment appear.

**Root cause:** Workflow ran concurrently without `lock-for-agent: true`.

**Coach response:**
- "Add `lock-for-agent: true` to the `on: issue_comment:` trigger"
- Explain: "This prevents multiple agents from running on the same issue simultaneously"
- Show the frontmatter section:
  ```yaml
  on:
    issue_comment:
      types: [created]
      lock-for-agent: true
  ```

### Pitfall 3: Unauthorized Users Triggering Commands

**Symptom:** Any comment with `/summarize` triggers the workflow, even from external contributors.

**Root cause:** No `min-integrity` check or permissions too open.

**Coach response:**
- "This is a security concern. You should restrict `/summarize` to repo members."
- "Add `min-integrity: approved` to your permissions — only approved members can trigger"
- Point to security as the reason: "Public contributors shouldn't trigger admin commands"

### Pitfall 4: Agent Can't Access Full Issue Thread

**Symptom:** Summary is incomplete (missing comments or discussion).

**Root cause:** Agent doesn't know how to fetch issue details or comments.

**Coach response:**
- "The GitHub API lets you fetch the issue and all its comments. In your body, instruct the agent: 'Use the GitHub API to fetch all comments on this issue.'"
- Point to: `tools: github: toolsets: [issues, comments]` in frontmatter
- Suggest: "Tell the agent the exact data you need: title, body, state, all comments"

### Pitfall 5: Summary Is Too Long or Rambling

**Symptom:** Comment is 50+ lines, hard to scan.

**Root cause:** Agent wasn't given clarity on length and structure.

**Coach response:**
- "Tell the agent to be concise: 'Keep the summary under 200 words. Use bullet points for readability.'"
- Provide structure: "Format as: **Issue**, **Key Discussion**, **Action Items**, **Status**"
- Model it: "Here's what a good summary looks like [show example]"

### Pitfall 6: Command Doesn't Recognize `/summarize` Typos

**Symptom:** User posts `/summarise` (UK spelling) or `/summ` (shorthand); workflow doesn't trigger.

**Root cause:** Exact string matching on `/summarize`.

**Coach response:**
- "For now, stick with exact matching: `/summarize` only."
- Explain: "Production systems do fuzzy matching, but that's advanced. For learning, exact is safer."
- Optionally: "If you want, you could check for `contains(comment, '/summ')` but be careful of false positives"

---

## Sample Solution

This is a complete, working `slash-commands.md`. Share **only after 20+ min of struggle**; ask them to type it out.

```markdown
---
on:
  issue_comment:
    types: [created]
    lock-for-agent: true

permissions:
  issues: read
  contents: read

safe-outputs:
  add-comment: {}

engines:
  - copilot
---

# Slash Commands: /summarize

Check if the comment contains the `/summarize` command. If it does, read the entire
issue (title, body, state) and all comments in the thread. Then post a structured
summary comment.

If the comment does NOT contain `/summarize`, do nothing (call noop if needed).

## Summary Structure

When posting the summary, include:

1. **Issue Title & State** — Concise description (1 sentence)
2. **Key Decisions** — What did the team decide? (bullets, if any)
3. **Blockers** — What's blocking progress? (bullets, if any)
4. **Action Items** — What needs to happen next? Include assignees if mentioned (bullets)
5. **Status** — Is this ready to close? Waiting for something? One sentence.

Keep the summary under 250 words. Use markdown formatting (bold, bullets, links).
Be professional but friendly.
```

**Why this works:**
- `on: issue_comment: types: [created]` — triggers on new comments
- `lock-for-agent: true` — prevents concurrent runs
- `permissions: issues: read` — can read issue + comments
- `checkout: false` (implicit) — doesn't need code
- `safe-outputs: add-comment: {}` — can post summary
- Body: natural language, clear instruction to check for `/summarize` first, then posts structured summary
- `engines: [copilot]` — free, good at summarization

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Read challenge, understand slash commands |
| Write frontmatter | 5 min | Set up `on: issue_comment:`, `lock-for-agent:`, `permissions`, `safe-outputs` |
| Write body | 8 min | Draft command detection + summary logic |
| Compile & test | 9 min | Compile, create test issue + add many comments, then post `/summarize` |
| Debug | 4 min | Fix any issues (missing comments, auth errors, etc.) |
| Celebrate | 1 min | Discuss what you built |

**Total: ~30 minutes.**

---

## Extension Ideas (for Fast Squads)

If finished in <20 minutes:

1. **Add `/triage` command:** Similar to `/summarize`, but classifies the issue and suggests labels
   - **Concept:** Multiple slash commands in one workflow

2. **Add `/explain` command:** Posts an explanation of technical decisions in the issue
   - **Concept:** Command with more complex logic

3. **Rate-limit per user:** Track how many `/summarize` commands each user has run today; warn if >10
   - **Concept:** User-level rate limiting, `user-rate-limit` in frontmatter

4. **React with 👀 instead of command:** Change trigger from comment to reaction emoji
   - **Concept:** Different interaction patterns

5. **Threaded replies:** Post summary as a reply to the original `/summarize` comment (using reply syntax)
   - **Concept:** GitHub comment threading API

---

## Debugging Checklist

If a squad is stuck:

- [ ] Is trigger `on: issue_comment: types: [created]`?
- [ ] Is `lock-for-agent: true` present?
- [ ] Did they compile? (`gh aw compile slash-commands.md`)
- [ ] Did they create a test issue + several comments + then post `/summarize`?
- [ ] Is there a workflow run in the Actions tab?
- [ ] Does the body check for `/summarize` before posting summary?
- [ ] Is `min-integrity: approved` set (or intentionally omitted)?
- [ ] Is the summary comment appearing?

---

## Key Takeaways for Coaches

- **ChatOps is powerful:** Slash commands turn workflows into tools. This changes mindset from "automation happens to me" to "I invoke automation when I need it."
- **Security matters:** Restrict command access early. This is good practice.
- **Concurrency kills:** `lock-for-agent: true` is non-negotiable for event-triggered workflows.
- **Summarization is hard:** Agents struggle to extract *key* points. Guide them on what matters in your repo's context.

---

## Reference

**Sample Solution Location:** `coaches/sample-solutions/track-2/2-03-slash-and-burn.md`  
**/q Command (Real):** https://github.com/githubnext/agentics/blob/main/workflows/q.md  
**/plan Command (Real):** https://github.com/githubnext/agentics/blob/main/workflows/plan.md  
**ChatOps Blog Post:** https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-interactive-chatops/
