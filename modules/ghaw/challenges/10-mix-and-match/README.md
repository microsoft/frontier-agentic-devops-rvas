# Activity 2-06: Mix & Match

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 30 minutes  
Prerequisites: Activity 00, at least 2 Track 1 activities, Activity 2-01

---

## Build

A weekly gh-aw workflow that imports shared instructions from `lib/repo-stats-helper.md`. The agent uses the helper to analyze repository status and posts the digest as a GitHub Discussion through `create-discussion`.

Teams often repeat the same prompt rules across workflows. `imports:` keeps those rules in one file. `create-discussion` publishes a searchable digest without adding another issue to the backlog.

---

## What you'll practice

1. Author a reusable Markdown snippet in `lib/`
2. Import it into a workflow with `imports:`
3. Schedule the workflow weekly
4. Post a repository-status digest as a GitHub Discussion, not an issue
5. Compile and validate it with `gh aw compile`

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use your own repository if possible. Base the helper and digest on its real health signals, Discussion category, and audience. Use the setup sample only for practice.
>
> - Have a candidate repo? Install or point `10-mix-and-match.md` at that repo everywhere the guide references the sample repo, and write `lib/repo-stats-helper.md` around its real issues, PRs, tests, docs, and reporting tone.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository you chose.

---

## Background: `imports:`

The `imports:` field loads one or more Markdown files before the workflow runs. gh-aw adds the imported content to the agent's context as inline instructions.

```yaml
imports:
  - ./lib/repo-stats-helper.md
```

Paths are relative to the repository root. The helper is plain Markdown with no frontmatter.

Use cases: shared formatting instructions, org-wide tone guidelines, reusable analysis templates, domain vocabulary.

---

## Background: `create-discussion`

The `create-discussion` safe-output tells the gh-aw runtime to post the agent's output as a GitHub Discussion rather than creating an issue or PR comment.

```yaml
safe-outputs:
  create-discussion:
    category: "General"
```

The `category` must match a Discussion category that already exists in the repo's Discussion settings. The agent needs `permissions: discussions: write` for this to work.

---

## Activity

### Step 1: Create the helper snippet

Create `lib/repo-stats-helper.md` in your repository. This file should contain instructions for how the agent should format a repository-status summary — for example:

- What sections to include (open issues, open PRs, recent activity, health rating)
- The tone and length of the summary
- Any formatting rules (use tables, bullet points, etc.)

Keep it focused. A good helper is 10–20 lines of clear instructions that any workflow could usefully import.

### Step 2: Create the workflow

Create `.github/workflows/10-mix-and-match.md` with:

- `imports:` referencing your helper: `./lib/repo-stats-helper.md`
- `on:` scheduled weekly (e.g., every Monday at 9am UTC)
- `permissions:` including `discussions: write`
- `safe-outputs:` with `create-discussion: category: "General"`
- Agent body: Ask the agent to analyze the repository's status and produce a digest. Tell it the output will be posted as a Discussion.

### Step 3: Enable Discussions

Make sure GitHub Discussions is enabled for your repository (Settings → Features → Discussions). Create a "General" category if one doesn't exist.

### Step 4: Compile and validate

```bash
gh aw compile 10-mix-and-match
```

No errors? You're ready to test. Trigger manually with `workflow_dispatch` to verify the Discussion appears.

---

## Success Criteria

- [ ] `lib/repo-stats-helper.md` exists and contains meaningful formatting instructions
- [ ] `.github/workflows/10-mix-and-match.md` has `imports: [./lib/repo-stats-helper.md]` in frontmatter
- [ ] Trigger is `on: schedule:` (weekly)
- [ ] `safe-outputs: create-discussion: category: "General"` is declared
- [ ] `permissions: discussions: write` is set
- [ ] Compiled `.lock.yml` exists without errors
- [ ] Running the workflow creates a Discussion post, not an issue
- [ ] The Discussion content matches the format defined in your helper
- [ ] Using a project, task, or workflow you own, identify repeated prompt guidance that belongs in a shared imported library.

---

## Tips & Hints

- Import paths are relative to the repo root, not to the workflow file. `./lib/repo-stats-helper.md` works from any workflow in `.github/workflows/`.
- Discussion category must exist first. If the category doesn't exist in your repo settings, the runtime will error. Create it manually before testing.
- Add `workflow_dispatch:` alongside your schedule during development so you can trigger the workflow manually without waiting for Monday.
- The helper is context, not code. Write it like you're briefing a smart colleague: "When summarizing repository status, start with a plain status marker: green (on track), yellow (needs attention), or red (blocked)."

---

## References

- imports: https://github.github.com/gh-aw/reference/frontmatter/#imports
- create-discussion safe-output: https://github.github.com/gh-aw/reference/safe-outputs/#create-discussion
- GitHub Discussions: https://docs.github.com/en/discussions

---

## Help

- "Compile says import not found" → Double-check the path. It's relative to repo root, so `./lib/repo-stats-helper.md` means the file lives at `lib/repo-stats-helper.md` from the root.
- "Discussion not appearing" → Verify `permissions: discussions: write` is in frontmatter and the category name matches exactly (case-sensitive).
- "Category doesn't exist" → Go to your repo → Settings → Features → Discussions → Manage. Add a "General" category.
- "How do I test the schedule without waiting a week?" → Add `on: workflow_dispatch: {}` to your trigger block and run it manually from the Actions tab.

Ask your coach.

---

*Next: Activity 2-05 — Welcome Wagon, or continue to Track 3 — Continuous Intelligence for advanced patterns.*
