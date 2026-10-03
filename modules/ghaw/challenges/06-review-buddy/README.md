# Activity 2-02: Review buddy

**Session outcome:** Your workflow comments on new pull requests with a diff summary and at least two observations about the changes. Human reviewers still decide whether to approve and merge.

## Build

Build a workflow that reviews pull requests when they open. Review Buddy analyzes the diff and comments on large changes, missing tests, or incomplete descriptions. It does not merge or reject the pull request.

The workflow handles mechanical checks before a human review.

---

## What you'll practice

1. Build a workflow triggered by `on: pull_request: types: [opened]`
2. Analyze PR metadata (files changed, additions/deletions)
3. Write review instructions that go beyond hardcoded rules
4. Post a review comment with the summary, observations, and optional suggestions specified in the activity

---

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `review-buddy.md` at a repo you own and test it on a real or representative pull request.

---

## Activity

Create a gh-aw workflow named `review-buddy.md` in `.github/workflows/` that:

- Runs when a pull request opens
- Analyzes:
  - Number of files changed
  - Total lines added/deleted
  - File types (code, tests, docs)
  - PR title and description quality (e.g., "Is there a meaningful description?")
- Posts a comment with:
  - A friendly greeting thanking the author
  - A summary of what changed (e.g., "This PR modifies 5 files with 200 additions and 50 deletions")
  - At least 2 observations about the PR (e.g., "Test files are included" or "This is a large change; reviewers may take longer")
  - Optional suggestions (e.g., "Consider breaking this into smaller PRs" if very large)
  - An encouraging sign-off (e.g., "Looking forward to reviewing!")

---

## Tips and troubleshooting

- Use `github.event.pull_request` context variables to get file count, diff stats, title, and description. You don't need to clone the repo.
- Choose 2–3 observations that help reviewers, such as whether tests are included.
- Keep the tone conversational and encouraging.
- Flag PRs with >500 added lines as large changes.
- If the workflow does not trigger on a PR, use `on: pull_request: types: [opened]`, not `issues`.
- If the comment is generic, name the evidence, for example "This PR changes three files and includes tests for the new behavior."

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- Pull Request Context Variables: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Real-world example (PR Fix): https://github.com/githubnext/agentics/blob/main/workflows/pr-fix.md
