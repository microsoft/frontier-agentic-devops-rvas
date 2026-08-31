# Activity 2-03: Issue Comment Commands

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 30 minutes  
Prerequisites: Complete at least 2 activities from Track 1

---

## Build

A workflow that responds to slash commands in issue comments. When a team member comments `/summarize`, the workflow reads the issue thread and posts a short summary.

Slash commands let teammates run an agent when they need it. `/summarize` gives reviewers context without making them read a long thread.

---

## What you'll practice

1. Build a workflow triggered by `on: issue_comment: types: [created]`
2. Detect slash commands in the comment body
3. Implement `/summarize` by reading the issue and its comments
4. Handle rate limits and prevent duplicate runs with `lock-for-agent`
5. Post a summary comment with:
   - Issue title and status (open/closed)
   - Key decisions or blockers mentioned
   - List of action items or next steps (if any)

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Run `/summarize` on your own repository if possible. Choose an issue with enough discussion to test the summary. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `slash-commands.md` at that repo everywhere the guide references the sample repo, and test on an issue where the discussion history is genuinely useful.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository and issue you chose.

---

## Activity

Create a gh-aw workflow named `slash-commands.md` in `.github/workflows/` that:

- Triggers on: Comments on issues (`on: issue_comment: types: [created]`)
- Detects: When a comment body contains `/summarize`
- Executes `/summarize` by:
  - Reading the full issue (title, body, state)
  - Reading all comments in the thread
  - Extracting key decisions, blockers, and action items
  - Posting a structured summary comment
- Prevents duplicate runs using `lock-for-agent: true`
- Summary comment includes:
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
- [ ] Using a project, task, or workflow you own, discuss which context your team rebuilds from long threads and which slash command would help.

---

## Tips & Hints

- Slash command pattern: Check if `github.event.comment.body` contains `/summarize`. In the workflow body, reference: "If the comment includes `/summarize`, read the issue..."
- Lock for agent: Always use `lock-for-agent: true` on comment-triggered workflows to prevent simultaneous runs on the same issue
- Permissions: Use `min-integrity: approved` to restrict command access to repo members/owners (defense against spam)
- Checkout: Set `checkout: false` (agent doesn't need code, only metadata)
- Key extraction: Look for:
  - Explicit decision statements ("We decided to...")
  - Blockers ("This is blocked by...")
  - Action items ("TODO:", "@mention", "next step")
- Summary tone: Professional, clear, scannable (use lists and bold text)

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- Slash Command Pattern: https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-interactive-chatops/
- Issue Comment Context: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Real-world example: `/q` slash command at https://github.com/githubnext/agentics/blob/main/workflows/q.md

---

## Help

- "Workflow triggers on every comment?" → Add `if:` condition to check for `/summarize` in comment body
- "How do I access the issue body and comments?" → Use the GitHub API to fetch the issue and its comments. The agent can call these via the `tools: github:` toolset
- "Duplicate summaries appearing?" → Add `lock-for-agent: true` to the trigger to prevent concurrent runs
- "Unauthorized users can trigger the command?" → Use `min-integrity: approved` in permissions to restrict to repo members
- "Summary is missing key points?" → Instruct the AI to look for specific keywords: "Decisions", "Blockers", "Next Steps"

Ask your coach.
