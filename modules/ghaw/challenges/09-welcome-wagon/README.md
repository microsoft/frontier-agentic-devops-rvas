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

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `welcome-wagon.md` at a repo you own and use its real CONTRIBUTING, code of conduct, and issue/support links. No candidate repo yet? Use the setup sample.

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

## Tips & Hints

- Author association field: `github.event.pull_request.author_association` is `NONE` for a contributor's first interaction with the repo (vs. `OWNER`, `MEMBER`, `COLLABORATOR`, `CONTRIBUTOR`). Check: "Is `author_association == 'NONE'`? If yes, welcome. If no, do nothing."
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

- "How do I reference CONTRIBUTING.md?" → Link to the actual `CONTRIBUTING.md` in your repository, using its owner, repository name, branch, and file path.
- "Workflow posts a comment even for existing contributors?" → Add a check in the body: "If `author_association` is not `NONE`, do nothing"
- "How do I test this if I'm the repo owner?" → Create a second test account (or use a friend's GitHub account) and have them open a PR
