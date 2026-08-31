# Activity 2-02: Review Buddy

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 30 minutes  
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
4. Post a structured review comment with:
   - Summary of changes (what files, how many lines)
   - Observations (e.g., "This is a big change" or "Test files look complete")
   - Suggestions for improvement (if any)

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Run Review Buddy on your own repository if possible. Real pull requests and review rules make the test meaningful. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `review-buddy.md` at that repo everywhere the guide references the sample repo, and test it on a real or representative pull request.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.

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

## Tips & Hints

- Pull request metadata: Use `github.event.pull_request` context variables to get file count, diff stats, title, description. You don't need to clone the repo.
- Diff analysis: The agent can read the PR description and reason about scope. You don't need deep code parsing for this activity.
- Observations matter: Pick observations that are meaningful (e.g., "Tests included" is good; "5 lines of code" is less helpful). Aim for 2–3 key points.
- Keep it positive: This is a friendly reviewer, not a harsh critic. Balance observations with encouragement.
- Large PR heuristic: Generally >500 lines added = "big change worth flagging"
- Tone: Conversational, helpful, avoiding jargon

---

## References

- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- Pull Request Context Variables: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Real-world example (PR Fix): https://github.com/githubnext/agentics/blob/main/workflows/pr-fix.md

---

## Help

- **Workflow does not trigger on a PR:** Ensure `on: pull_request: types: [opened]`, not `issues`.
- "Can't access PR stats?" → The agent can read `github.event.pull_request.*` variables. In your body, reference: "There are {number of files} changed, {additions} added, {deletions} removed"
- **Comment is too generic:** Name the evidence. For example: "This PR is focused: three files changed with clear intent."
- "Not sure what to observe?" → Look for: file count (small/medium/large), test coverage (tests touched?), description quality (complete or vague?)

Raise your hand.
