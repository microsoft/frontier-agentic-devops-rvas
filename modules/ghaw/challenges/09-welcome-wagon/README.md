# Activity 2-05: Welcome Wagon

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 30 minutes  
Prerequisites: Complete at least 2 activities from Track 1

---

## Build

A workflow that welcomes first-time contributors. When someone opens their first pull request, Welcome Wagon posts a greeting and links to the contribution guide and code of conduct.

New contributors may not know the project's process. A short welcome can set expectations and point them to the right documentation.

---

## What you'll practice

1. Build a workflow triggered by `on: pull_request: types: [opened]`
2. Detect first-time contributors with `author_association`
3. Post a personal welcome comment
4. Link to the contribution guide, code of conduct, and other useful resources
5. Set clear next steps for new contributors

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Run Welcome Wagon on your own repository if possible. Use its real contributor links and preferred tone. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `welcome-wagon.md` at that repo everywhere the guide references the sample repo, and use real CONTRIBUTING, docs, code of conduct, issue, or support links.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository you chose.

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
- [ ] Using a project, task, or workflow you own, discuss the first impression new contributors get and what an automated welcome should or should not handle.

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

- Pull Request Context (author_association): https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/

---

## Help

- "How do I detect first-time contributors?" → Use `github.event.pull_request.author_association`. If it's `NONE`, they're new to the repo
- "How do I reference CONTRIBUTING.md?" → Link to the actual `CONTRIBUTING.md` in your repository, using its owner, repository name, branch, and file path.
- "Workflow posts a comment even for existing contributors?" → Add a check in the body: "If `author_association` is not `NONE`, do nothing"
- "How do I test this if I'm the repo owner?" → Create a second test account (or use a friend's GitHub account) and have them open a PR

Ask your coach.
