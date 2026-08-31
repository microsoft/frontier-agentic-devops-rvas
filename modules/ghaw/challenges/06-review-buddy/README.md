# Activity 2-02: Review Buddy

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 75 minutes  
Prerequisites: Complete at least 2 activities from Track 1

---

## Build

A workflow that reviews pull requests when they open. Review Buddy analyzes the diff and comments on large changes, missing tests, or incomplete descriptions. It does not merge or reject the pull request.

The workflow handles mechanical checks before a human review. Reviewers can spend their time on design, correctness, and risk.

---

## What you'll practice

1. Build a workflow triggered by `on: pull_request: types: [opened]`
2. Analyze PR metadata (files changed, additions/deletions)
3. Write review instructions that go beyond hardcoded rules
4. Post a structured review comment with a summary, observations, and optional suggestions (see Activity below)

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `review-buddy.md` at a repo you own and test it on a real or representative pull request.

---

## Activity

Create a gh-aw workflow named `review-buddy.md` in `.github/workflows/` that:

- Triggers on: Pull request opened
- Analyzes:
  - Number of files changed
  - Total lines added/deleted
  - File types (code, tests, docs)
  - PR title and description quality (e.g., "Is there a meaningful description?")
- Posts a comment with:
  - A friendly greeting thanking the author
  - A summary of what changed (e.g., "This PR modifies 5 files with 200 additions and 50 deletions")
  - At least 2 observations about the PR (e.g., "Test files are included" or "⚠️ This is a large change; reviewers may take longer")
  - Optional suggestions (e.g., "Consider breaking this into smaller PRs" if very large)
  - An encouraging sign-off (e.g., "Looking forward to reviewing!")

---

## Tips & Troubleshooting

- Pull request metadata: Use `github.event.pull_request` context variables to get file count, diff stats, title, description. You don't need to clone the repo.
- Observations matter: Pick observations that are meaningful (e.g., "Tests included" is good; "5 lines of code" is less helpful). Aim for 2–3 key points.
- Tone: Conversational and encouraging, not a harsh critic.
- Large PR heuristic: Generally >500 lines added = "big change worth flagging"
- Workflow does not trigger on a PR: ensure `on: pull_request: types: [opened]`, not `issues`.
- Comment too generic? Name the evidence, for example "This PR is focused: three files changed with clear intent."

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- Pull Request Context Variables: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Real-world example (PR Fix): https://github.com/githubnext/agentics/blob/main/workflows/pr-fix.md
