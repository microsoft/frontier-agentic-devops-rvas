# Challenge 2-05: Welcome Wagon

**Track:** Repo Concierge (Intermediate 🟡)  
**Estimated time:** 30 minutes  
**Prerequisites:** Complete at least 2 challenges from Track 1

---

## What You'll Build

A workflow that welcomes first-time contributors to your repo. When someone opens their first pull request, your Welcome Wagon springs into action, posting a warm greeting and offering resources (contribution guide, code of conduct, etc.). This teaches you **contributor detection** and turns automation into genuine community-building.

**Why this matters:** First-time contributors are nervous. A warm, helpful bot makes them feel welcome and reduces friction. Many open-source projects use this pattern to set tone and direct newbies to docs.

---

## Goals

By the end, your squad will:

1. ✅ Build a workflow triggered by `on: pull_request: types: [opened]`
2. ✅ Detect first-time contributors using `author_association` field
3. ✅ Post a personalized welcome comment
4. ✅ Include resources (links to contribution guide, code of conduct, etc.)
5. ✅ Make new contributors feel valued and supported

---

## Challenge

Create a gh-aw workflow named `welcome-wagon.md` in `.github/workflows/` that:

- **Triggers on:** Pull request opened
- **Detects:** Is this the author's first PR to the repo? (use `author_association`)
- **Only posts a comment if** it's a first-time contributor (skip if `author_association` is `COLLABORATOR`, `MEMBER`, or `OWNER`)
- **Welcome comment includes:**
  - A warm greeting (e.g., "Welcome to our community! 🎉")
  - Thank you for contributing
  - 2–3 helpful links (contribution guide, code of conduct, issue tracker, docs, etc.)
  - Encouragement and next steps (e.g., "A maintainer will review soon")
  - Offer to help if they have questions

---

## Success Criteria

- [ ] `.github/workflows/welcome-wagon.md` exists with valid gh-aw frontmatter
- [ ] Trigger is `on: pull_request: types: [opened]`
- [ ] Frontmatter includes conditional check (or body checks): only posts for first-time contributors
- [ ] Safe-outputs includes `add-comment`
- [ ] `.github/workflows/welcome-wagon.lock.yml` compiles without errors
- [ ] Manual test: create a test PR from a new user account (or use a test account)
- [ ] Verify: comment appears ONLY for first-time contributors
- [ ] Verify: comment does NOT appear if you (repo owner) open a PR
- [ ] Comment includes:
  - Warm greeting
  - Thank you message
  - At least 2 helpful links or resources
  - Encouragement
- [ ] Comment is friendly, not robotic

---

## Tips & Hints

- **Author association field:** GitHub provides `github.event.pull_request.author_association` with values: `OWNER`, `MEMBER`, `COLLABORATOR`, `CONTRIBUTOR`, `NONE`
  - `NONE` = first time they've interacted with this repo
  - Use this to detect first-timers
- **Conditional logic:** Check: "Is `author_association == 'NONE'`? If yes, welcome. If no, do nothing."
- **Resources to include:** Contribution guide (CONTRIBUTING.md), code of conduct (CODE_OF_CONDUCT.md), issue tracker, documentation URL, Discord/Slack channel (if you have one)
- **Tone:** Enthusiastic, welcoming, not condescending. These are the people who make your project grow.
- **Links:** Use GitHub's repo URLs where possible (they auto-resolve)

---

## References

- **Pull Request Context (author_association):** https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
- **Safe Outputs (add-comment):** https://github.github.com/gh-aw/reference/safe-outputs/
- **GitHub API Toolset:** https://github.github.com/gh-aw/reference/tools/github/

---

## Stuck?

- **"How do I detect first-time contributors?"** → Use `github.event.pull_request.author_association`. If it's `NONE`, they're new to the repo
- **"How do I reference CONTRIBUTING.md?"** → Use a GitHub URL: `https://github.com/YOUR_ORG/YOUR_REPO/blob/main/CONTRIBUTING.md`
- **"Workflow posts a comment even for existing contributors?"** → Add a check in the body: "If `author_association` is not `NONE`, do nothing"
- **"How do I test this if I'm the repo owner?"** → Create a second test account (or use a friend's GitHub account) and have them open a PR

Ask your coach.
