# Ch53: Risk-tiered merge

**Session outcome:** Low-risk pull requests in one customer repository merge themselves once checks pass. Everything else waits for the reviewers its risk tier requires. You verify both paths with real pull requests.

> [!IMPORTANT]
> **Auto-merge is not "no review".** It means the owner decided in advance which changes don't need a human. Write that decision down in `risk-tiers.json`, and keep it small.

## How it works

| Tier | Examples | What merges it |
|---|---|---|
| `risk:low` | Docs, tests, Dependabot patch bumps | Required checks only. The gate queues auto-merge. |
| `risk:medium` | Ordinary source changes | Required checks plus one approval from someone other than the author. |
| `risk:high` | Workflows, infrastructure, auth, migrations, major upgrades | Required checks plus an approval, and code owner review through the ruleset. |

A workflow classifies each pull request by **what it touches and how much**, not by who wrote it. It labels the tier and fails a required `risk-gate` check until the tier's approvals exist. Agent and human pull requests follow the same rules.

## Tasks

### Part A: Decide the tiers

1. With the repository owner, list the paths that must never merge without a human. Start with `.github/workflows/**`, `.github/CODEOWNERS`, infrastructure, authentication, and database migrations.
2. List the paths where a wrong change is cheap to revert, usually docs and tests.
3. Copy the starter into the repository:

   ```bash
   CURRICULUM=/absolute/path/to/frontier-agentic-devops-rvas
   R="$CURRICULUM/modules/ghec/resources/agentic-sdlc"
   mkdir -p .github/scripts .github/workflows
   cp "$R/risk-tiers.json" .github/risk-tiers.json
   cp "$R/risk-gate.cjs" .github/scripts/risk-gate.cjs
   cp "$R/risk-gate.yml" .github/workflows/risk-gate.yml
   node --test "$R/risk-gate.test.cjs"
   ```

4. Edit `.github/risk-tiers.json` to match step 1 and 2. Keep `maxLowChangedLines` small. Raise it later, with evidence from ch58.

### Part B: Wire the controls

5. Add every high-risk path to `CODEOWNERS`, owned by a team that can review it.
6. In **Settings > General > Pull Requests**, enable **Allow auto-merge**.
7. Create or update the branch ruleset (see ch08) to:
   - require the CI checks **and** `risk-gate`;
   - require pull requests with **0** required approvals, because the gate sets the count per tier;
   - require review from **Code Owners**;
   - require the branch to be up to date, or turn on the **merge queue**. If you use the queue, make sure CI and `risk-gate` also run on `merge_group`.
8. Merge the three files to the default branch. `pull_request_target` runs the default-branch copy, so the gate only works after that merge.

### Part C: Prove each path

9. **Low:** open a docs-only pull request. Expect label `risk:low`, a passing gate, and auto-merge enabled. It merges when CI finishes.
10. **Medium:** change a source file. Expect `risk:medium` and a failing gate. Approve as a second person and confirm the gate re-runs and passes.
11. **High:** edit a workflow file. Expect `risk:high`, a code owner request, and no merge until the code owner approves.
12. **Should do nothing:** approve your own pull request. The gate must not count it.
13. **Dependabot:** if Dependabot has an open patch update to a manifest, confirm it lands as `low`. Confirm a minor update lands as `medium`.

### Part D: Keep the escape hatch

14. Record who can remove the `risk-gate` requirement, and how fast. After any incident traced to an auto-merged change, narrow `low` first, then investigate.

## Hints

- **Why `pull_request_target`?** Dependabot and fork pull requests get a read-only token on `pull_request`. The gate only reads file names and reviews through the API and never checks out the pull request's code. Keep it that way.
- The gate counts the **latest** review per person. A later "Request changes" cancels an earlier approval.
- Auto-merge needs the ruleset's required checks to exist. With no required checks, GitHub merges at once.
- Ruleset `bypass` lists defeat the gate. Keep them short and visible in the audit log.

## Common failures

| Symptom | Likely cause |
|---|---|
| No `risk-gate` check appears | The workflow isn't on the default branch yet. |
| Gate passes but nothing merges | A required check is pending, or auto-merge is off in settings. |
| Low-tier pull request stays medium | A file falls outside `low` paths. The gate's log lists it. |
| Gate fails with `REPO and PR_NUMBER are required` | The workflow's env block was edited. Restore it. |

## Cleanup

Remove the `risk-gate` required check and the files if the owner doesn't want to keep them. Delete test branches.
