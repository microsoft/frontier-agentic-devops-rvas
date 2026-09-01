## Background

The Issue Triage Agent reads each new issue, compares it with the repository's label taxonomy, and applies allowed labels.

Source: [`github/gh-aw/.github/workflows/issue-triage-agent.md`](https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md)

## What It Does

- Triggers on `on: issues: types: [opened, reopened]`
- Reads the issue title and body
- Looks up available labels using `tools: github: toolsets: [issues, labels]`
- Applies 1–3 relevant labels from a defined allowlist
- Posts a short classification comment explaining the categorisation

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): customise the workflow with the real labels, issue patterns, and comment style of a repo you own.

## Steps

1. Install and verify `gh aw` with the [GHAW setup guide](../../setup.md).

2. Pull the production workflow as your starting point:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md
   ```

3. Inspect the downloaded file in `.github/workflows/issue-triage-agent.md`. Compare its frontmatter with the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax): `on:`, `permissions:`, `safe-outputs:`, and `tools:`.

4. Customise the workflow for your repo (see below).

5. Compile the workflow:
   ```bash
   gh aw compile issue-triage-agent
   ```

6. Dry-run the workflow:
   ```bash
   gh aw run issue-triage-agent --dry-run
   ```

7. Commit both `.github/workflows/issue-triage-agent.md` and the generated `.lock.yml`.

## Adapt it

Replace the default allowlist with your repo's actual labels:
- Open your repo's Labels page and copy the exact label names
- Edit the triage prompt to reference only those labels (prevents hallucination of non-existent tags)
- Add a short description of each label so the agent understands when to apply it
- Change the classification comment style. A one-line comment such as "Categorised as: bug, backend" is enough.

---

<details>
<summary>💡 Hints</summary>

"The agent is applying labels that don't exist in my repo"
→ Your allowlist is the guard. Add explicit instructions: _"Only apply labels from this list: [bug, enhancement, docs, question]. Never invent labels."_ Run `gh label list` to get the exact names.

"Workflow runs but nothing happens"
→ Check the Actions tab for the run log. Permissions might be missing: grant at minimum `issues: write` for `add-labels` and `add-comment` (see [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token)).

"What's the difference between `add-labels` and `set-labels`?"
→ `add-labels` appends to existing labels; `set-labels` replaces them. Use `add-labels` unless you want to own the full label set.

</details>
