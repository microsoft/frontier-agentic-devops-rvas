# Challenge 2-03: Slash & Burn

**Track:** Repo Concierge (Intermediate 🟡)  
**Estimated time:** 30 minutes  
**Prerequisites:** Complete at least 2 challenges from Track 1

---

## What You'll Build

A workflow that responds to slash commands in issue comments. When a team member comments `/summarize` on an issue, your workflow reads the entire issue thread and posts a concise summary. This is the gateway to interactive automation—using comments as a command interface for your agent.

**Why this matters:** Slash commands are how you turn your agents into tools your team *actively uses* during their daily work. Instead of running on a schedule, they respond to intent. `/summarize` is a perfect example: reviewers need quick context without scrolling 50 comments.

---

## Goals

By the end, your squad will:

1. ✅ Build a workflow triggered by `on: issue_comment: types: [created]`
2. ✅ Implement slash-command detection (parsing the comment body for `/command`)
3. ✅ Implement the `/summarize` command that reads issue + comments and posts a summary
4. ✅ Handle rate limiting and prevent duplicate command runs (`lock-for-agent`)
5. ✅ Post a summary comment with:
   - Issue title and status (open/closed)
   - Key decisions or blockers mentioned
   - List of action items or next steps (if any)

---

## Challenge

Create a gh-aw workflow named `slash-commands.md` in `.github/workflows/` that:

- **Triggers on:** Comments on issues (`on: issue_comment: types: [created]`)
- **Detects:** When a comment body contains `/summarize`
- **Executes `/summarize` by:**
  - Reading the full issue (title, body, state)
  - Reading all comments in the thread
  - Extracting key decisions, blockers, and action items
  - Posting a structured summary comment
- **Prevents duplicate runs** using `lock-for-agent: true`
- **Summary comment includes:**
  - Concise issue description (1–2 sentences)
  - Key decisions or discussion points (if any)
  - Blockers or concerns (if any)
  - Action items and owners (if assigned)
  - Status recommendation (e.g., "Ready to close" or "Awaiting feedback")

---

## Success Criteria

- [ ] `.github/workflows/slash-commands.md` exists with valid gh-aw frontmatter
- [ ] Frontmatter includes `on: issue_comment:` with `types: [created]` and `lock-for-agent: true`
- [ ] Body detects slash commands (checks for `/summarize` in comment text)
- [ ] Workflow only executes for `/summarize` (ignores other comments)
- [ ] `.github/workflows/slash-commands.lock.yml` compiles without errors
- [ ] Manual test: post a comment `/summarize` on a test issue
- [ ] The workflow runs (visible in Actions tab)
- [ ] A summary comment appears within 30 seconds
- [ ] Summary includes:
  - Issue title and current state
  - At least 2 key points from the discussion
  - Next steps or recommendation
- [ ] Only authorized users (repo members) can trigger the command

---

## Tips & Hints

- **Slash command pattern:** Check if `github.event.comment.body` contains `/summarize`. In the workflow body, reference: "If the comment includes `/summarize`, read the issue..."
- **Lock for agent:** Always use `lock-for-agent: true` on comment-triggered workflows to prevent simultaneous runs on the same issue
- **Permissions:** Use `min-integrity: approved` to restrict command access to repo members/owners (defense against spam)
- **Checkout:** Set `checkout: false` (agent doesn't need code, only metadata)
- **Key extraction:** Look for:
  - Explicit decision statements ("We decided to...")
  - Blockers ("This is blocked by...")
  - Action items ("TODO:", "@mention", "next step")
- **Summary tone:** Professional, clear, scannable (use lists and bold text)

---

## References

- **GitHub API Toolset:** https://github.github.com/gh-aw/reference/tools/github/
- **Safe Outputs (add-comment):** https://github.github.com/gh-aw/reference/safe-outputs/
- **Slash Command Pattern:** https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-interactive-chatops/
- **Issue Comment Context:** https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
- **Real-world example:** `/q` slash command at https://github.com/githubnext/agentics/blob/main/workflows/q.md

---

## Stuck?

- **"Workflow triggers on every comment?"** → Add `if:` condition to check for `/summarize` in comment body
- **"How do I access the issue body and comments?"** → Use the GitHub API to fetch the issue and its comments. The agent can call these via the `tools: github:` toolset
- **"Duplicate summaries appearing?"** → Add `lock-for-agent: true` to the trigger to prevent concurrent runs
- **"Unauthorized users can trigger the command?"** → Use `min-integrity: approved` in permissions to restrict to repo members
- **"Summary is missing key points?"** → Instruct the AI to look for specific keywords: "Decisions", "Blockers", "Next Steps"

Ask your coach.
