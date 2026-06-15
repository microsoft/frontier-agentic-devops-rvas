# Coach Guide: Challenge 2-05 — Welcome Wagon

---

## Coaching Philosophy

This is the **heart of community-building automation**. Unlike triage or stale patrol (which maintain repo hygiene), Welcome Wagon changes how contributors *feel*. Your job: help squads see that automation can be warm, not just efficient. A good bot is an extension of your team's values.

**Key rule:** By minute 25, the squad should see a welcoming comment on a first-timer's PR and feel the difference it makes. That emotional connection is the learning.

---

## Expected Outcomes

A finished solution has these characteristics:

**File structure:**
- `.github/workflows/welcome-wagon.md` — ~30–40 lines (frontmatter + body)
- `.github/workflows/welcome-wagon.lock.yml` — auto-generated, ~70–90 lines

**Behavior:**
- Runs on PR open
- Detects first-time contributors (`author_association == 'NONE'`)
- Posts welcome comment ONLY for first-timers
- Skips if contributor is already known (MEMBER, COLLABORATOR, etc.)
- Comment is warm and includes 2–3 resources

**Example outcome:**
```
PR: "Add dark mode support" (by @first_time_user)

[Welcome Wagon runs]
Comment posted:

"🎉 Welcome to our community! Thanks so much for your first contribution!

We're excited to have you here. Here are some resources to help you succeed:

📖 **Getting Started:** https://github.com/myorg/myrepo/blob/main/CONTRIBUTING.md
📋 **Code of Conduct:** https://github.com/myorg/myrepo/blob/main/CODE_OF_CONDUCT.md
🚀 **Docs:** https://docs.example.com

A maintainer will review your PR soon. If you have any questions, don't hesitate to ask!"
```

---

## Common Approaches

All valid.

### Approach 1: Simple Author Check (Most Common)

Body checks `author_association` and conditionally posts:

```
If this is a first-time contributor (author_association == 'NONE'),
post a welcome comment with resources and encouragement.
Otherwise, do nothing.
```

**Pros:** Clear, teachable, fast  
**Cons:** No personalization beyond "welcome"

### Approach 2: Personalized Greeting

Body personalizes the greeting by including the author's username:

```
If first-timer:
  Post "Welcome, @{author_name}! Thanks for your first contribution..."
```

**Pros:** Feels more personal, stronger connection  
**Cons:** Slightly more complex prompt

### Approach 3: Conditional Resources

Branch on PR type:
- If first PR to code: offer code/testing resources
- If first PR to docs: offer writing resources

**Pros:** More helpful (targeted resources)  
**Cons:** More complex logic, saves for advanced students

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: Comments on Every PR (Not Just First-Timers)

**Symptom:** Veteran contributors get welcome comments too.

**Root cause:** Missing or incorrect author_association check.

**Coach response:**
- "Let's check your body. Are you filtering on `author_association`?"
- Show them: "You need to check: if `author_association == 'NONE'`, then post. Otherwise, skip."
- Point to GitHub docs: https://docs.github.com/en/actions/learn-github-actions/contexts#github-context

### Pitfall 2: Comment Feels Generic or Robotic

**Symptom:** Comment is bland ("Thanks for contributing").

**Root cause:** Squads don't personalize tone.

**Coach response:**
- "Read your comment out loud. Does it feel warm?"
- Suggest: Add emoji (🎉, 🚀, ❤️), use more personality, mention specific things they did well
- Model: "Instead of 'Thanks for contributing', try 'Welcome! We're excited to have you join our community!'"

### Pitfall 3: Resources Are Broken or Missing

**Symptom:** Links in comment are broken or don't exist.

**Root cause:** Squad guessed at URLs or didn't test them.

**Coach response:**
- "Let's verify each link. Does `CONTRIBUTING.md` exist in your repo?"
- Have them check: ls `.github/CONTRIBUTING.md` or `CONTRIBUTING.md` (location varies)
- GitHub URLs should follow: `https://github.com/OWNER/REPO/blob/main/FILE`

### Pitfall 4: Can't Test (Need New User Account)

**Symptom:** Squad is repo owner, so `author_association` is always `OWNER`. They can't test.

**Root cause:** Testing complexity—hard to simulate first-time contributor.

**Coach response:**
- "For testing, you have a few options:"
  - Ask a friend to open a PR from their account
  - Create a second GitHub account (takes 2 min)
  - Or: in the body, mock the condition: "For testing, assume `author_association == 'NONE'` and post the welcome comment"
- Normalize: "This is a real testing challenge in CI/CD. Production workflows often use dummy accounts or test workflows."

### Pitfall 5: Over-Long Comment

**Symptom:** Comment is 50+ lines (too much information for a new contributor).

**Root cause:** Including every possible resource.

**Coach response:**
- "Keep it to 2–3 key resources. New contributors are overwhelmed; too many links hurt more than help."
- Suggest: "Start with: Contribution guide, Code of Conduct, and one more (docs or Discord)"

### Pitfall 6: Permissions Error When Posting

**Symptom:** Workflow runs but comment never appears; logs show permission error.

**Root cause:** `pull-requests: read` is too restrictive (needs write).

**Coach response:**
- "Check your permissions. To post a comment, the agent needs `pull-requests: write` or you need `safe-outputs: add-comment:` (which grants that automatically)"
- Show: `permissions: pull-requests: read` is for *reading* PRs; `add-comment` safe-output upgrades to write

---

## Sample Solution

This is a complete, working `welcome-wagon.md`. Share **only after 20+ min of struggle**; ask them to type it out.

```markdown
---
on:
  pull_request:
    types: [opened]

permissions:
  pull-requests: read

safe-outputs:
  add-comment: {}

engines:
  - copilot
---

# Welcome Wagon

When a new PR is opened, check if this is the author's first contribution to the repo.
Use the `author_association` field: if it's `NONE`, this is a first-time contributor.

If first-time:
  Post a warm welcome comment that includes:
  - A greeting (e.g., "Welcome to our community! 🎉")
  - Thanks for contributing
  - 2-3 helpful links (contribution guide, code of conduct, docs, etc.)
  - Encouragement

If NOT first-time (author_association is MEMBER, COLLABORATOR, or OWNER):
  Do nothing.

Keep the comment friendly and concise. New contributors should feel welcomed, not overwhelmed.
```

**Why this works:**
- `on: pull_request: types: [opened]` — triggers when new PR created
- `permissions: pull-requests: read` — can read PR context
- `safe-outputs: add-comment: {}` — can post comment
- Body: clear author_association check, warm tone, resource inclusion
- `engines: [copilot]` — good at personalization and tone

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Read challenge, understand author_association |
| Write frontmatter | 4 min | Set up `on: pull_request:`, `permissions`, `safe-outputs`, `engines` |
| Write body | 8 min | Draft author_association check + welcome message with resources |
| Compile & test | 10 min | Compile, create test PR (or use alternate account), verify |
| Refine tone | 3 min | Make comment warmer if needed |
| Celebrate | 2 min | Discuss what you built |

**Total: ~30 minutes.**

---

## Extension Ideas (for Fast Squads)

If finished in <20 minutes:

1. **Personalize by PR type:** Different welcome messages for code vs. docs PRs
   - **Concept:** Conditional messaging

2. **Add a help label:** Apply `first-time-contributor` label so maintainers know to be extra helpful
   - **Concept:** Using labels for workflow routing

3. **Post resource links as replies:** Use GitHub's reply-to-comment API to thread the resources separately
   - **Concept:** Comment threading

4. **Post to Discussions instead:** Welcome message goes to a "New Contributors" discussion
   - **Concept:** Different safe-outputs target

5. **Track and report:** Count first-time contributors weekly and post a summary discussion
   - **Concept:** Combining Welcome Wagon with metrics collection

---

## Debugging Checklist

If a squad is stuck:

- [ ] Is trigger `on: pull_request: types: [opened]`?
- [ ] Did they compile?
- [ ] Does `.lock.yml` exist?
- [ ] Did they create/simulate a first-time PR?
- [ ] Is there a workflow run in the Actions tab?
- [ ] Is the comment appearing?
- [ ] Does the body check `author_association == 'NONE'`?
- [ ] Are the resource links valid?
- [ ] Is the tone warm, not robotic?

---

## Key Takeaways for Coaches

- **Automation has soul:** Squads often think of automation as cold/efficient. But bots can be warm, welcoming, human.
- **First impressions matter:** New contributors' first experience shapes whether they return. A good Welcome Wagon builds loyalty.
- **Personalization scales:** Humans can't greet 100 new contributors personally. Bots can—and do it consistently.
- **Community, not gatekeeping:** This is different from triage or stale-patrol. This is about inclusion, not enforcement.

---

## Reference

**Sample Solution Location:** `coaches/sample-solutions/track-2/2-05-welcome-wagon.md`  
**GitHub Author Association:** https://docs.github.com/en/actions/learn-github-actions/contexts#github-context  
**Pull Request Context:** https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
