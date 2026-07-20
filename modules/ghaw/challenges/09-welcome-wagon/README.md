# Activity 2-05: Welcome Wagon

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 30 minutes  
Prerequisites: Complete at least 2 activities from Track 1

---

## What You'll Build

A workflow that welcomes first-time contributors to your repo. When someone opens their first pull request, your Welcome Wagon posts a warm greeting and offers resources (contribution guide, code of conduct, and more). This teaches you contributor detection and turns automation into genuine community-building.

Why this matters: First-time contributors may be unfamiliar with a project. A warm, helpful bot makes them feel welcome and reduces friction. Many open-source projects use this pattern to set expectations and direct new contributors to documentation.

---

## Goals

By the end, your squad will:

1. ✅ Build a workflow triggered by `on: pull_request: types: [opened]`
2. ✅ Detect first-time contributors using `author_association` field
3. ✅ Post a personalized welcome comment
4. ✅ Include resources (links to contribution guide, code of conduct, etc.)
5. ✅ Make new contributors feel valued and supported

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> This activity is most valuable when Welcome Wagon uses your own repository's contributor flow, links, and tone, so first-time contributors keep getting useful guidance after the session. Treat the setup sample as practice, not the default destination.
>
> - Have a candidate repo? Install or point `welcome-wagon.md` at that repo everywhere the guide references the sample repo, and use real CONTRIBUTING, docs, code of conduct, issue, or support links.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

---

## Activity

Create a gh-aw workflow named `welcome-wagon.md` in `.github/workflows/` that:

- Triggers on: Pull request opened
- Detects: Is this the author's first PR to the repo? (use `author_association`)
- Only posts a comment if it's a first-time contributor (skip if `author_association` is `COLLABORATOR`, `MEMBER`, or `OWNER`)
- Welcome comment includes:
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
- [ ] Discuss what first impression new contributors get from your project today, and what you would trust an automated welcome to handle versus what should stay a personal touch. Connect it to a project, task, or workflow you own.

---

## Tips & Hints

- Author association field: GitHub provides `github.event.pull_request.author_association` with values: `OWNER`, `MEMBER`, `COLLABORATOR`, `CONTRIBUTOR`, `NONE`
  - `NONE` = first time they've interacted with this repo
  - Use this to detect first-timers
- Conditional logic: Check: "Is `author_association == 'NONE'`? If yes, welcome. If no, do nothing."
- Resources to include: Contribution guide (CONTRIBUTING.md), code of conduct (CODE_OF_CONDUCT.md), issue tracker, documentation URL, Discord/Slack channel (if you have one)
- Tone: Enthusiastic, welcoming, not condescending. These are the people who make your project grow.
- Links: Use GitHub's repo URLs where possible (they auto-resolve)

---

## References

- Pull Request Context (author_association): https://docs.github.com/en/actions/learn-github-actions/contexts#github-context
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/

---

## Stuck?

- "How do I detect first-time contributors?" → Use `github.event.pull_request.author_association`. If it's `NONE`, they're new to the repo
- "How do I reference CONTRIBUTING.md?" → Link to the actual `CONTRIBUTING.md` in your repository, using its owner, repository name, branch, and file path.
- "Workflow posts a comment even for existing contributors?" → Add a check in the body: "If `author_association` is not `NONE`, do nothing"
- "How do I test this if I'm the repo owner?" → Create a second test account (or use a friend's GitHub account) and have them open a PR

Ask your coach.
