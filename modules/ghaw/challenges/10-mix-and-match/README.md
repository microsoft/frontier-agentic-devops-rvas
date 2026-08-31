# Activity 2-06: Mix & Match

Track: Repo Concierge (Intermediate 🟡)  
Estimated time: 105 minutes  
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

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): point `10-mix-and-match.md` at a repo you own and write `lib/repo-stats-helper.md` around its real issues, PRs, and reporting tone.

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

## Tips & Troubleshooting

- The helper is context, not code. Write it like you're briefing a smart colleague: "When summarizing repository status, start with a plain status marker: green (on track), yellow (needs attention), or red (blocked)."
- Add `workflow_dispatch:` alongside your schedule during development so you can trigger the workflow manually without waiting for Monday.
- "Import not found" means the path is wrong: it is relative to the repo root, so `./lib/repo-stats-helper.md` lives at `lib/repo-stats-helper.md`.
- Discussion not appearing? Check `permissions: discussions: write` and that the category name matches exactly (case-sensitive). Create the category in Settings → Features → Discussions → Manage if it does not exist.

---

## References

- imports: https://github.github.com/gh-aw/reference/frontmatter/#imports
- create-discussion safe-output: https://github.github.com/gh-aw/reference/safe-outputs/#create-discussion
- GitHub Discussions: https://docs.github.com/en/discussions
