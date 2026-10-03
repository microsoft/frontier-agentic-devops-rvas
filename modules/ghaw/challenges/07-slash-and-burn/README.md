# Activity 2-03: Issue comment commands

## Build

Build a workflow that responds to slash commands in issue comments. When a team member comments `/summarize`, the workflow reads the issue thread and posts a short summary.

Slash commands let teammates run an agent when they need it. `/summarize` gives reviewers context without making them read a long thread.

---

## What you'll practice

1. Build a workflow triggered by `on: issue_comment: types: [created]`
2. Detect slash commands in the comment body
3. Implement `/summarize` by reading the issue and its comments
4. Handle rate limits and prevent duplicate runs with `lock-for-agent`
5. Post a summary comment with issue status, key decisions/blockers, and action items (see Activity below)

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `slash-commands.md` at a repo you own and test `/summarize` on an issue with discussion history.

---

## Activity

Create a gh-aw workflow named `slash-commands.md` in `.github/workflows/` that:

- Runs on issue comments (`on: issue_comment: types: [created]`)
- Detects `/summarize` in the comment body
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

## Tips and troubleshooting

- Check if `github.event.comment.body` contains `/summarize`. Write an instruction such as: "If the comment includes `/summarize`, read the issue..."
- Always use `lock-for-agent: true` on comment-triggered workflows to prevent simultaneous runs on the same issue.
- Use `min-integrity: approved` to restrict command access to repo members/owners and prevent spam.
- Set `checkout: false` because the agent needs only metadata.
- Tell the agent to look for:
  - Explicit decision statements ("We decided to...")
  - Blockers ("This is blocked by...")
  - Action items ("TODO:", "@mention", "next step")
- Use lists to make the summary easy to scan.
- If the workflow triggers on every comment, add an `if:` condition that checks for `/summarize` in the comment body.
- If concurrent runs produce duplicate summaries, confirm `lock-for-agent: true` is set.
- If the summary misses key points, specify keywords such as decisions, blockers, and next steps.

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- Slash Command Pattern: https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-interactive-chatops/
- Issue Comment Context: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Real-world example: `/q` slash command at https://github.com/githubnext/agentics/blob/main/workflows/q.md
