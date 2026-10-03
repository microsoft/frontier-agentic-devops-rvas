# Activity 2-05: Welcome wagon

## Build

Build a workflow that welcomes first-time contributors. When someone opens their first pull request, Welcome Wagon posts a greeting and links to the contribution guide and code of conduct.

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
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `welcome-wagon.md` at a repo you own and use its real CONTRIBUTING, code of conduct, and issue/support links.

---

## Activity

Create a gh-aw workflow named `welcome-wagon.md` in `.github/workflows/` that:

- Runs when a pull request opens
- Uses `author_association` to detect first-time contributors
- Only posts a comment if it's a first-time contributor (skip if `author_association` is `COLLABORATOR`, `MEMBER`, or `OWNER`)
- Welcome comment includes:
  - A greeting (e.g., "Welcome to our community!")
  - Thank you for contributing
  - 2–3 helpful links (contribution guide, code of conduct, issue tracker, docs, etc.)
  - Encouragement and next steps (e.g., "A maintainer will review soon")
  - Offer to help if they have questions

---

## Tips and troubleshooting

- `github.event.pull_request.author_association` is `NONE` for a contributor's first interaction with the repo, compared with `OWNER`, `MEMBER`, `COLLABORATOR`, or `CONTRIBUTOR`. Instruct the agent: "Welcome the contributor if `author_association == 'NONE'`. Otherwise, do nothing."
- Include the contribution guide (CONTRIBUTING.md), code of conduct (CODE_OF_CONDUCT.md), issue tracker, documentation URL, or Discord/Slack channel if you have one.
- Keep the greeting welcoming without talking down to the contributor.
- Use GitHub's repo URLs where possible because they auto-resolve.
- If the workflow comments on existing contributors, add this check to the body: "If `author_association` is not `NONE`, do nothing."
- To test as the repo owner, have a second account open the pull request.

---

## References

- Pull Request Context (author_association): https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#github-context
- Safe Outputs (add-comment): https://github.github.com/gh-aw/reference/safe-outputs/
- GitHub tool permissions: https://github.github.com/gh-aw/reference/permissions/
