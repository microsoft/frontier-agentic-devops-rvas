**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Bonus

---

## Background

Every project accumulates doc debt: verbose intros, duplicate sections, outdated warnings, nested caveats-of-caveats. The Documentation Unbloat workflow finds this bloat and opens focused PRs that trim it — no rewrites, just surgical simplification.

The production version in `githubnext/agentics` achieved an **85% merge rate** — 88 merged PRs out of 103 proposed. Maintainers love it because each PR is small, targeted, and easy to review.

Source: `githubnext/agentics/workflows/unbloat-docs.md`

## What It Does

- Targets specific documentation files for simplification review
- Identifies: redundancy, excessive hedging, outdated warnings, over-long examples
- Opens focused PRs with verbosity removed and clarity improved
- Each PR is intentionally small (one file, one concern)

## What You'll Do

1. **Install gh aw** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/unbloat-docs.md
   ```

3. **Identify a bloated doc** in your repo — README.md, a long CONTRIBUTING.md, or any doc with "Note:", "Warning:", "Important:" every third paragraph.

4. **Customise** the workflow to target that file and define your project's simplification rules.

5. **Compile**:
   ```bash
   gh aw compile .github/workflows/unbloat-docs.md
   ```

6. **Dry-run** against your bloated doc:
   ```bash
   gh aw run --dry-run .github/workflows/unbloat-docs.md
   ```

7. Review the proposed PR diff — does it match what you'd have cut manually?

## Customize It

- Set the target file explicitly in the body: _"Review `docs/getting-started.md` only"_ — single-file focus produces better diffs
- Define what "simplify" means for your project: _"Remove duplicate notes, shorten examples to the minimum that demonstrates the point, delete any section that duplicates the README"_
- Add PR label `docs-unbloat` so these PRs are filterable
- Adjust the schedule or make it `workflow_dispatch` only if you want manual control

## Success Criteria

- [ ] `.github/workflows/unbloat-docs.md` exists with valid gh-aw frontmatter
- [ ] Target document is explicitly named in the workflow body
- [ ] `safe-outputs: create-pr` is declared
- [ ] Simplification criteria are specific, not vague ("make it shorter" is too vague — "remove duplicate warnings and shorten code examples to one line" is good)
- [ ] `.github/workflows/unbloat-docs.lock.yml` compiles without errors
- [ ] Dry-run proposes at least one real simplification
- [ ] Proposed PR diff is focused (one file, clean changes)
- [ ] Coach conversation — where has documentation bloat in your projects actually pushed contributors away, and how would you keep an agent from cutting something important while it trims the fat? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

<details>
<summary>💡 Hints</summary>

**"The agent keeps removing content I actually want"**
→ Add a preservation rule to the body: _"Do not remove: examples, API references, or any section starting with `## Quick Start`."_

**"How is Unbloat different from Doc Updater?"**
→ Doc Updater fixes accuracy (code changed, docs didn't). Unbloat fixes verbosity (doc was always too long). They compose well — run Updater first, then Unbloat.

**"My docs don't have obvious bloat"**
→ Look for: sentences starting with "Note that", "Please be aware", "It is important to". These almost always can be cut or rewritten more directly.

**"The PR is huge — 50 files changed"**
→ The production workflow targets one or two files per run. Narrow your scope in the body, and use `create-pr` with a focused branch name.

**"Should I run this on a schedule or manually?"**
→ Start with `workflow_dispatch` so you control when it runs. Graduate to a weekly cron once you trust the output.

</details>

---

<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-04-doc-unbloat/Student/README.md" class="btn btn--primary">📘 Student Guide</a>
<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-04-doc-unbloat/Coach/README.md" class="btn btn--ghost">🎓 Coach Guide</a>
