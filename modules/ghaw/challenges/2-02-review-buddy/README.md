# Challenge 2-02: Review Buddy

**Track:** Repo Concierge (Intermediate 🟡)  
**Estimated time:** 30 minutes  
**Prerequisites:** Complete at least 2 challenges from Track 1

---

## What You'll Build

A workflow that reviews pull requests as soon as they're opened. Your Review Buddy analyzes the diff, spots obvious issues (large changes, missing tests, incomplete descriptions), and posts a structured comment with observations and suggestions. It doesn't merge or reject anything—it's a friendly reviewer helping the PR author make their code better.

**Why this matters:** PR reviews are where code quality gatekeeping happens. An automated first pass that flags common issues (large files, test coverage gaps) saves reviewers time and helps new contributors write better code from the start.

---

## Goals

By the end, your squad will:

1. ✅ Build a workflow triggered by `on: pull_request: types: [opened]`
2. ✅ Analyze PR metadata (files changed, additions/deletions)
3. ✅ Implement AI-powered code review logic (not hardcoded rules)
4. ✅ Post a structured review comment with:
   - Summary of changes (what files, how many lines)
   - Observations (e.g., "This is a big change" or "Test files look complete")
   - Suggestions for improvement (if any)

---

## Challenge

Create a gh-aw workflow named `review-buddy.md` in `.github/workflows/` that:

- **Triggers on:** Pull request opened
- **Analyzes:**
  - Number of files changed
  - Total lines added/deleted
  - File types (code, tests, docs)
  - PR title and description quality (e.g., "Is there a meaningful description?")
- **Posts a comment** with:
  - A friendly greeting thanking the author
  - A summary of what changed (e.g., "This PR modifies 5 files with 200 additions and 50 deletions")
  - At least 2 observations about the PR (e.g., "Good — test files are included" or "⚠️ This is a large change; reviewers may take longer")
  - Optional suggestions (e.g., "Consider breaking this into smaller PRs" if very large)
  - An encouraging sign-off (e.g., "Looking forward to reviewing!")

---

## Success Criteria

- [ ] `.github/workflows/review-buddy.md` exists with valid gh-aw frontmatter
- [ ] Trigger is `on: pull_request: types: [opened]`
- [ ] Safe-outputs includes `add-comment` (no label application needed here)
- [ ] `.github/workflows/review-buddy.lock.yml` compiles without errors
- [ ] You manually test by creating a test PR in your repo
- [ ] The workflow runs and posts a comment within 30 seconds of PR creation
- [ ] The comment is friendly and includes at least:
  - A thank-you message
  - Summary of changed files/lines
  - 2+ observations
  - An encouraging sign-off
- [ ] The comment feels useful (not spam)

---

## Tips & Hints

- **Pull request metadata:** Use `github.event.pull_request` context variables to get file count, diff stats, title, description. You don't need to clone the repo.
- **Diff analysis:** The agent can read the PR description and reason about scope. You don't need deep code parsing for this challenge.
- **Observations matter:** Pick observations that are meaningful (e.g., "Tests included" is good; "5 lines of code" is less helpful). Aim for 2–3 key points.
- **Keep it positive:** This is a friendly reviewer, not a harsh critic. Balance observations with encouragement.
- **Large PR heuristic:** Generally >500 lines added = "big change worth flagging"
- **Tone:** Conversational, helpful, avoiding jargon

---

## References

- **GitHub API Toolset:** https://github.github.com/gh-aw/reference/tools/github/
- **Safe Outputs (add-comment):** https://github.github.com/gh-aw/reference/safe-outputs/
- **Pull Request Context Variables:** https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
- **Real-world example (PR Fix):** https://github.com/githubnext/agentics/blob/main/workflows/pr-fix.md

---

## Stuck?

- **"Workflow doesn't trigger on PR?"** → Ensure `on: pull_request: types: [opened]` — not `issues`
- **"Can't access PR stats?"** → The agent can read `github.event.pull_request.*` variables. In your body, reference: "There are {number of files} changed, {additions} added, {deletions} removed"
- **"Comment is too generic?"** → Rewrite to be specific. Instead of "Good PR", try: "This PR is focused and well-scoped — just 3 files changed with clear intent"
- **"Not sure what to observe?"** → Look for: file count (small/medium/large), test coverage (tests touched?), description quality (complete or vague?)

Raise your hand.
