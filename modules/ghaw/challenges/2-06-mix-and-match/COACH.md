# Coach Guide: Challenge 2-06 — Mix & Match

---

## Coaching Philosophy

This challenge introduces two production-grade concepts in tandem: **workflow composition** (`imports:`) and **async reporting** (`create-discussion`). Neither is hard to use — but neither is obvious if you've only seen basic gh-aw examples.

**Key insight to surface:** Copy-pasting prompts across workflows is tech debt. `imports:` is the gh-aw answer to DRY (Don't Repeat Yourself). Help squads see that the helper file is a first-class artifact that deserves the same care as code.

**For `create-discussion`:** Discussions are the right channel for async reporting. Issues imply action required. A weekly repo health digest is not a to-do item — it's information. That framing helps squads make better output-routing decisions.

---

## Expected Outcomes

A finished solution has:

**File structure:**
- `lib/repo-stats-helper.md` — 10–25 lines of formatting/analysis instructions
- `.github/workflows/2-06-mix-and-match.md` — ~25–35 lines
- `.github/workflows/2-06-mix-and-match.lock.yml` — auto-generated

**Frontmatter shape:**
```yaml
---
imports:
  - ./lib/repo-stats-helper.md

on:
  schedule:
    - cron: "0 9 * * 1"   # every Monday at 9am UTC
  workflow_dispatch: {}    # for testing

permissions:
  discussions: write

safe-outputs:
  create-discussion:
    category: "General"

engines:
  - copilot
---
```

**Behavior:**
- Weekly schedule (or manual dispatch during testing)
- Imports helper context before executing
- Agent produces a repo health digest
- Output is posted as a Discussion in the "General" category

---

## What `imports:` Actually Does

`imports:` causes the referenced Markdown file(s) to be prepended to the agent's context before the workflow body is evaluated. The helper content is not executed — it's context. Think of it as a system prompt extension.

Import paths are relative to the **repository root**, not the workflow file location. So `./lib/repo-stats-helper.md` resolves from the root regardless of where the workflow lives.

**Multiple imports are supported:**
```yaml
imports:
  - ./lib/repo-stats-helper.md
  - ./lib/tone-guidelines.md
```

---

## Common Blockers

### Blocker 1: Import path not found

**Symptom:** Compile error — "import not found" or similar.

**Cause:** File is in the wrong location, or path is written relative to the workflow file instead of repo root.

**Fix:** The path `./lib/repo-stats-helper.md` resolves to `lib/repo-stats-helper.md` from the repo root. Confirm with `ls lib/` from the repo root.

**Socratic response:** "Where did you create the helper file? Let's check `ls lib/` from the root and compare to your import path."

---

### Blocker 2: Discussion category doesn't exist

**Symptom:** Workflow runs, no Discussion appears, runtime logs show a category error.

**Cause:** The category specified in `create-discussion: category:` doesn't exist in the repo's Discussion settings, or Discussions isn't enabled at all.

**Fix:**
1. Enable Discussions: Settings → Features → Discussions ✓
2. Add the category: Settings → Features → Discussions → Manage categories → New category
3. Category name is **case-sensitive** — `"General"` ≠ `"general"`

**Socratic response:** "Is the Discussion category created in repo settings? Go to Settings → Discussions and check."

---

### Blocker 3: Missing `permissions: discussions: write`

**Symptom:** Workflow compiles, runs, but no Discussion is created. Permission error in logs.

**Cause:** `discussions: write` is not declared in frontmatter.

**Fix:** Add it explicitly:
```yaml
permissions:
  discussions: write
```

**Note:** This is separate from `issues: write` and `pull-requests: write`. It's easy to forget.

---

### Blocker 4: Helper file has frontmatter (causes parse errors)

**Symptom:** Import succeeds but agent context is noisy, or compile warns about unexpected YAML.

**Cause:** Squad added `---` frontmatter to the helper file, treating it like a workflow.

**Fix:** Helper files are plain Markdown — no frontmatter, no `---` delimiters. Just content.

---

## Solution Shape

Don't give squads the full answer; describe what a correct solution looks like.

A correct `lib/repo-stats-helper.md`:
- Plain Markdown (no frontmatter)
- Defines: what sections to include in a health digest, what tone and length to use, any formatting rules (tables, emojis, traffic-light indicators)
- 10–25 lines — specific enough to be useful, short enough to stay focused

A correct `2-06-mix-and-match.md`:
- `imports:` with relative path to helper
- `on: schedule:` with a valid weekly cron, plus `workflow_dispatch:` for testing
- `permissions: discussions: write`
- `safe-outputs: create-discussion: category: "General"`
- Body: instructs the agent to analyze repo health and produce a digest in the format described by the imported helper

---

## How to Verify It's Working

1. **Compile check:** `gh aw compile .github/workflows/2-06-mix-and-match.md` — no errors
2. **Import check:** Inspect the compiled `.lock.yml` — the helper's content should appear merged into the agent context
3. **Manual trigger:** Run via `workflow_dispatch` from the Actions tab
4. **Discussion created:** Navigate to the repo's Discussions tab — a new post should appear in "General" within seconds of the workflow completing
5. **Content check:** The Discussion should follow the formatting rules defined in the helper (not arbitrary formatting)

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Read challenge, understand imports + create-discussion |
| Create helper | 5 min | Author `lib/repo-stats-helper.md` |
| Write workflow | 7 min | frontmatter + agent body |
| Enable Discussions | 3 min | Repo settings, create "General" category |
| Compile & test | 10 min | Compile, trigger manually, verify Discussion appears |
| Refine | 2 min | Adjust helper content if output format is off |

**Total: ~30 minutes.**

---

## Extension Ideas (Fast Squads)

1. **Multiple helpers:** Import both a tone guide and a stats guide. Does composition work as expected?
2. **Separate category:** Create a "Weekly Digest" Discussion category and route there instead of "General"
3. **Compare:** Write the same workflow without `imports:` — copy the helper content inline. Is the output different? Better or worse?
4. **Chain the digest:** Have another workflow react to the Discussion being created (using `discussion` event trigger)

---

## Key Takeaways for Coaches

- **`imports:` = DRY for AI context.** It's not magic — it's just context prepending. But it's powerful: one helper update propagates to every workflow that imports it.
- **`create-discussion` = right channel for right content.** Not everything should be an issue. Help squads build the habit of matching output type to content type.
- **Helper quality matters.** A vague helper produces vague output. A specific helper (with concrete formatting rules) produces structured, consistent Discussions.

---

## Reference

**Sample Solution Location:** `coaches/sample-solutions/track-2/2-06-mix-and-match.md`  
**imports:** https://github.github.com/gh-aw/reference/frontmatter/#imports  
**create-discussion:** https://github.github.com/gh-aw/reference/safe-outputs/#create-discussion  
**GitHub Discussions API:** https://docs.github.com/en/rest/discussions
