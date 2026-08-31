Track: Production Patterns (Advanced 🟣)
Estimated time: 60 minutes
Tier: Bonus

---

## Background

Documentation often accumulates repeated text, stale warnings, and long examples. The Documentation Unbloat workflow reviews one target document and opens a focused pull request that cuts unnecessary text without rewriting the whole file.

Source: [`githubnext/agentics/workflows/unbloat-docs.md`](https://github.com/githubnext/agentics/blob/main/workflows/unbloat-docs.md)

## Behavior

- Targets specific documentation files for simplification review
- Finds repeated text, excessive hedging, outdated warnings, and over-long examples
- Opens focused PRs that remove unnecessary text
- Each PR is intentionally small (one file, one concern)

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): target the README, contributing guide, or runbook of a repo you own, with your own preservation rules.

## Steps

1. Install and verify `gh aw` with the [GHAW setup guide](../../setup.md).

2. Pull the production workflow:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/unbloat-docs.md
   ```

3. Choose one bloated document, such as README.md, a long CONTRIBUTING.md, or a file crowded with notes and warnings.

4. Customise the workflow to target that file and define your project's simplification rules.

5. Compile:
   ```bash
   gh aw compile unbloat-docs
   ```

6. Dry-run against your bloated doc:
   ```bash
   gh aw run unbloat-docs --dry-run
   ```

7. Review the proposed PR diff. Confirm that it matches what you would cut manually.

## Adapt it

- Set one target file in the body: _"Review `docs/getting-started.md` only."_ A single-file scope produces better diffs.
- Define what "simplify" means for your project: _"Remove duplicate notes, shorten examples to the minimum that demonstrates the point, delete any section that duplicates the README"_
- Add PR label `docs-unbloat` so these PRs are filterable
- Adjust the schedule or make it `workflow_dispatch` only if you want manual control

---

<details>
<summary>💡 Hints</summary>

"The agent keeps removing content I actually want"
→ Add a preservation rule to the body: _"Do not remove: examples, API references, or any section starting with `## Quick Start`."_

"How is Unbloat different from Doc Updater?"
→ Doc Updater fixes accuracy (code changed, documentation did not). Unbloat reduces unnecessary length (the document was always too long). Use them in sequence: run Updater first, then Unbloat.

"My docs don't have obvious bloat"
→ Look for: sentences starting with "Note that", "Please be aware", "It is important to". These almost always can be cut or rewritten more directly.

"The PR is huge — 50 files changed"
→ The production workflow targets one or two files per run. Narrow your scope in the body, and use `create-pull-request` with a focused branch name.

</details>
