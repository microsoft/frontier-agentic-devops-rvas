**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Core

---

## Background

The Issue Triage Agent is the _"hello world" of agentic workflows_ — it's the first example shown in Claude Code's documentation and the pattern that introduces thousands of developers to `gh aw`. When a new issue lands in your repo, it reads the body, matches it against your label taxonomy, and applies the right tags automatically. No more stale unlabelled backlogs.

Source: [`github/gh-aw/.github/workflows/issue-triage-agent.md`](https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md)

## What It Does

- Triggers on `on: issues: types: [opened, reopened]`
- Reads the issue title and body
- Looks up available labels using `tools: github: toolsets: [issues, labels]`
- Applies 1–3 relevant labels from a defined allowlist
- Posts a short classification comment explaining the categorisation

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This activity is most valuable when the triage agent learns your real label taxonomy and keeps working on your team's incoming issues. Pick a repository in an org you control where unlabelled or inconsistently labelled issues create real backlog noise.
>
> - **Have a candidate repo?** Use it everywhere this guide references the sample repo, and customise the workflow with that repo's real labels, issue patterns, and classification comment style.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

## What You'll Do

1. **Install [`gh aw`](https://github.com/github/gh-aw)** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow** as your starting point:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md
   ```

3. **Inspect the downloaded file** in `.github/workflows/issue-triage-agent.md`. Compare its frontmatter with the [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions): `on:`, `permissions:`, `safe-outputs:`, and `tools:`.

4. **Customise** the workflow for your repo (see below).

5. **Compile** the workflow:
   ```bash
   gh aw compile issue-triage-agent
   ```

6. **Dry-run** the workflow:
   ```bash
   gh aw run issue-triage-agent --dry-run
   ```

7. Commit both `.github/workflows/issue-triage-agent.md` and the generated `.lock.yml`.

## Customize It

Replace the default allowlist with your repo's actual labels:
- Open your repo's Labels page and copy the exact label names
- Edit the triage prompt to reference only those labels (prevents hallucination of non-existent tags)
- Add a short description of each label so the agent understands when to apply it
- Change the classification comment style — a one-liner "Categorised as: bug, backend" is fine

## Success Criteria

- [ ] `.github/workflows/issue-triage-agent.md` exists and has valid gh-aw frontmatter
- [ ] Trigger is `on: issues: types: [opened, reopened]`
- [ ] `tools: github: toolsets: [issues, labels]` is present
- [ ] `safe-outputs` includes `add-labels` and `add-comment`
- [ ] Allowlist contains only labels that exist in your repo
- [ ] `.github/workflows/issue-triage-agent.lock.yml` compiles without errors
- [ ] Dry-run completes and shows expected label assignments in output
- [ ] Live test: open a new issue and verify labels + comment appear
- [ ] Coach conversation — if you deployed this proven triage agent on your busiest repo tomorrow, what would you measure to decide whether it is actually saving the team time rather than adding noise? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

<details>
<summary>💡 Hints</summary>

**"The agent is applying labels that don't exist in my repo"**
→ Your allowlist is the guard. Add explicit instructions: _"Only apply labels from this list: [bug, enhancement, docs, question]. Never invent labels."_

**"How do I see what labels I have?"**
→ `gh label list` — or open the repository's **Issues** → **Labels** page in GitHub.

**"Workflow runs but nothing happens"**
→ Check the Actions tab for the run log. Permissions might be missing: use the [GITHUB_TOKEN permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication) model and grant at minimum `issues: write` for `add-labels` and `add-comment`.

**"Can I add more than one comment type?"**
→ Yes. `safe-outputs: add-comment: {}` allows multiple comment calls in a single run.

**"What's the difference between `add-labels` and `set-labels`?"**
→ `add-labels` appends to existing labels; `set-labels` replaces them. Use `add-labels` unless you want to own the full label set.

</details>

