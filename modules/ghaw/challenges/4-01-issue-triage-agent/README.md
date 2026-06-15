**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Core

---

## Background

The Issue Triage Agent is the _"hello world" of agentic workflows_ — it's the first example shown in Claude Code's documentation and the pattern that introduces thousands of developers to `gh aw`. When a new issue lands in your repo, it reads the body, matches it against your label taxonomy, and applies the right tags automatically. No more stale unlabelled backlogs.

The real production version lives at `github/gh-aw/.github/workflows/issue-triage-agent.md`.

## What It Does

- Triggers on `on: issues: types: [opened, reopened]`
- Reads the issue title and body
- Looks up available labels using `tools: github: toolsets: [issues, labels]`
- Applies 1–3 relevant labels from a defined allowlist
- Posts a short classification comment explaining the categorisation

## What You'll Do

1. **Install gh aw** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow** as your starting point:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/issue-triage-agent.md
   ```

3. **Inspect the downloaded file** in `.github/workflows/issue-triage-agent.md`. Note the frontmatter structure: `on:`, `permissions:`, `safe-outputs:`, and `tools:`.

4. **Customise** the workflow for your repo (see below).

5. **Compile** the workflow:
   ```bash
   gh aw compile .github/workflows/issue-triage-agent.md
   ```

6. **Dry-run** with a real issue number:
   ```bash
   gh aw run --dry-run .github/workflows/issue-triage-agent.md --event issue --issue 1
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

---

<details>
<summary>💡 Hints</summary>

**"The agent is applying labels that don't exist in my repo"**
→ Your allowlist is the guard. Add explicit instructions: _"Only apply labels from this list: [bug, enhancement, docs, question]. Never invent labels."_

**"How do I see what labels I have?"**
→ `gh label list` — or visit `github.com/YOUR_ORG/YOUR_REPO/labels`

**"Workflow runs but nothing happens"**
→ Check the Actions tab for the run log. Permissions might be missing: you need at minimum `issues: write` for `add-labels` and `add-comment`.

**"Can I add more than one comment type?"**
→ Yes. `safe-outputs: add-comment: {}` allows multiple comment calls in a single run.

**"What's the difference between `add-labels` and `set-labels`?"**
→ `add-labels` appends to existing labels; `set-labels` replaces them. Use `add-labels` unless you want to own the full label set.

</details>

---

<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-01-issue-triage-agent/Student/README.md" class="btn btn--primary">📘 Student Guide</a>
<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-01-issue-triage-agent/Coach/README.md" class="btn btn--ghost">🎓 Coach Guide</a>
