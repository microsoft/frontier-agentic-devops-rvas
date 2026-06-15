# Challenge 2-06: Mix & Match

**Track:** Repo Concierge (Intermediate 🟡)  
**Estimated time:** 30 minutes  
**Prerequisites:** Challenge 00, at least 2 Track 1 challenges, Challenge 2-01

---

## What You'll Build

A weekly-scheduled gh-aw workflow that composes itself from reusable parts. Instead of writing every prompt from scratch, you'll author a shared helper snippet — `lib/repo-stats-helper.md` — and `imports:` it into your workflow. The agent reads the helper, analyzes repo health, and posts a digest as a GitHub **Discussion** using the `create-discussion` safe-output.

**Why this matters:** In production, teams maintain shared prompt libraries: tone guidelines, formatting rules, domain context. `imports:` lets you reference those without copy-pasting them into every workflow. And `create-discussion` keeps stakeholders informed through async, searchable posts — not a stream of noisy issues.

---

## Goals

By the end, your squad will:

1. ✅ Author a reusable Markdown snippet in `lib/`
2. ✅ Import it into a workflow using `imports:`
3. ✅ Schedule the workflow to run weekly
4. ✅ Post a repo health digest as a GitHub Discussion (not an issue)
5. ✅ Compile and validate with `gh aw compile`

---

## Background: `imports:`

The `imports:` field in gh-aw frontmatter lets a workflow pull in one or more Markdown files before executing. The imported content is merged into the agent's context — as if you had written it inline.

```yaml
imports:
  - ./lib/repo-stats-helper.md
```

Paths are relative to the repository root. The helper file is plain Markdown — no special syntax, no frontmatter. It's just context you want every workflow that imports it to share.

**Use cases:** shared formatting instructions, org-wide tone guidelines, reusable analysis templates, domain vocabulary.

---

## Background: `create-discussion`

The `create-discussion` safe-output tells the gh-aw runtime to post the agent's output as a GitHub Discussion rather than creating an issue or PR comment.

```yaml
safe-outputs:
  create-discussion:
    category: "General"
```

The `category` must match a Discussion category that **already exists** in the repo's Discussion settings. The agent needs `permissions: discussions: write` for this to work.

---

## Challenge

### Step 1: Create the helper snippet

Create `lib/repo-stats-helper.md` in your repository. This file should contain instructions for how the agent should format a repo health summary — for example:

- What sections to include (open issues, open PRs, recent activity, health rating)
- The tone and length of the summary
- Any formatting rules (use tables, bullet points, etc.)

Keep it focused. A good helper is 10–20 lines of clear instructions that any workflow could usefully import.

### Step 2: Create the workflow

Create `.github/workflows/2-06-mix-and-match.md` with:

- **`imports:`** referencing your helper: `./lib/repo-stats-helper.md`
- **`on:`** scheduled weekly (e.g., every Monday at 9am UTC)
- **`permissions:`** including `discussions: write`
- **`safe-outputs:`** with `create-discussion: category: "General"`
- **Agent body:** Ask the agent to analyze the repo's health and produce a digest. Tell it the output will be posted as a Discussion.

### Step 3: Enable Discussions

Make sure GitHub Discussions is enabled for your repository (Settings → Features → Discussions). Create a "General" category if one doesn't exist.

### Step 4: Compile and validate

```bash
gh aw compile .github/workflows/2-06-mix-and-match.md
```

No errors? You're ready to test. Trigger manually with `workflow_dispatch` to verify the Discussion appears.

---

## Success Criteria

- [ ] `lib/repo-stats-helper.md` exists and contains meaningful formatting instructions
- [ ] `.github/workflows/2-06-mix-and-match.md` has `imports: [./lib/repo-stats-helper.md]` in frontmatter
- [ ] Trigger is `on: schedule:` (weekly)
- [ ] `safe-outputs: create-discussion: category: "General"` is declared
- [ ] `permissions: discussions: write` is set
- [ ] Compiled `.lock.yml` exists without errors
- [ ] Running the workflow creates a Discussion post, not an issue
- [ ] The Discussion content matches the format defined in your helper

---

## Tips & Hints

- **Import paths are relative to the repo root**, not to the workflow file. `./lib/repo-stats-helper.md` works from any workflow in `.github/workflows/`.
- **Discussion category must exist first.** If the category doesn't exist in your repo settings, the runtime will error. Create it manually before testing.
- **Add `workflow_dispatch:` alongside your schedule** during development so you can trigger the workflow manually without waiting for Monday.
- **The helper is context, not code.** Write it like you're briefing a smart colleague: "When summarizing repo health, always include a traffic-light rating (🟢/🟡/🔴) at the top."

---

## References

- **imports:** https://github.github.com/gh-aw/reference/frontmatter/#imports
- **create-discussion safe-output:** https://github.github.com/gh-aw/reference/safe-outputs/#create-discussion
- **GitHub Discussions:** https://docs.github.com/en/discussions

---

## Stuck?

- **"Compile says import not found"** → Double-check the path. It's relative to repo root, so `./lib/repo-stats-helper.md` means the file lives at `lib/repo-stats-helper.md` from the root.
- **"Discussion not appearing"** → Verify `permissions: discussions: write` is in frontmatter and the category name matches exactly (case-sensitive).
- **"Category doesn't exist"** → Go to your repo → Settings → Features → Discussions → Manage. Add a "General" category.
- **"How do I test the schedule without waiting a week?"** → Add `on: workflow_dispatch: {}` to your trigger block and run it manually from the Actions tab.

Ask your coach.

---

*Next: Challenge 2-05 — Welcome Wagon, or continue to Track 3 — Continuous Intelligence for advanced patterns.*
