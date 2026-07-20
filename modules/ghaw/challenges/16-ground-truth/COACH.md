# Coach Guide: Activity 3-06 — Ground Truth

---

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the customer practitioner to connect the exercise to work they actually own.

**Their question:** Coach conversation — where has an AI confidently produced numbers or facts it made up in your work, and how would feeding it deterministic data first change what you would trust it to output? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to recall a time an AI gave them confident but fabricated numbers or facts.
- Explore how feeding deterministic data first changes what they'd trust the output to be.
- Get them to identify one task where they'll ground the agent in real data before it reasons, next week.

## Coaching Philosophy

This activity teaches one of the most important production patterns in gh-aw: **grounding AI output in real data**. Squads at this level have seen agents produce confident-sounding but fabricated numbers. `pre-agent-steps:` is the solution: deterministic shell runs first, writes real values to files, and the agent reads those files.

**Key insight to surface:** The AI model is not a database. It cannot look up your open issue count — it will guess. `pre-agent-steps:` separates "gather facts" (shell, deterministic, reliable) from "reason about facts" (AI, creative, unreliable without grounding). That separation is the architecture of trustworthy automation.

**For `create-pull-request`:** The PR gate is about trust. Even when agents produce correct output, good teams don't merge automatically. `create-pull-request` is the "propose, don't impose" pattern — the agent does the work, a human approves the result.

---

## What `pre-agent-steps:` Does at Runtime

At execution time, gh-aw runs `pre-agent-steps:` as bash steps in the same runner environment as a standard GitHub Actions workflow. This happens **before** the AI model is invoked. Key facts:

1. All `$` expressions are resolved (e.g., `$` → `owner/repo`)
2. The `gh` CLI is available and pre-authenticated with `GITHUB_TOKEN`
3. Files written to `/tmp/` are available to the agent during its run
4. **`/tmp/` files are ephemeral** — they exist only for this run and are not committed anywhere
5. If a `pre-agent-steps:` command fails (non-zero exit), the workflow aborts before the agent runs

The agent accesses these files by reading from the filesystem in its execution context. Point squads at this in their body: "Read `/tmp/open-issues.txt` for the count."

---

## Expected Outcomes

A finished solution has:

**File structure:**
- `.github/workflows/16-ground-truth.md` — ~40–55 lines
- `.github/workflows/16-ground-truth.lock.yml` — auto-generated

**Frontmatter shape:**
```yaml
---
on:
  workflow_dispatch: {}

permissions:
  contents: write
  pull-requests: write

pre-agent-steps:
  - name: Fetch repository metrics
    run: |
      gh api "/repos/$/issues?state=open&per_page=100" \
        --jq 'length' > /tmp/open-issues.txt
      gh pr list --state open --json number --jq 'length' > /tmp/open-prs.txt
      git log -1 --format="%ci" > /tmp/last-commit.txt

safe-outputs:
  create-pull-request:
    base-branch: main
    title-prefix: "docs: update CONTRIBUTING.md with current project health"

engine: copilot
---
```

**Behavior:**
- `pre-agent-steps:` runs 3 `gh`/`git` commands, writes results to `/tmp/`
- Agent reads those files and uses the numbers to update `CONTRIBUTING.md`
- A PR is opened with the changes — no direct commit

---

## How `create-pull-request` Differs from Direct Commits

Without `create-pull-request`, if an agent modifies a file, those changes are committed directly to the default branch. With `create-pull-request`:

1. The agent's file changes are staged on a new branch
2. A pull request is opened against `base-branch`
3. No changes land on `main` until a human (or automation) merges the PR

This is the "propose, don't impose" pattern. It's not just about safety — it's about auditability. Stakeholders can see exactly what the agent changed, in the diff, before it affects anything.

**The contrast:** `safe-outputs: noop` (read-only) → `safe-outputs: create-pull-request` (write, but gated) → direct commit (write, ungated — not available as a safe-output by design).

---

## Common Blockers

### Blocker 1: Missing `pull-requests: write` permission

**Symptom:** Workflow runs, `pre-agent-steps:` succeeds, agent runs, but no PR appears. Permission error in logs.

**Cause:** Only `contents: write` was declared. `create-pull-request` needs both.

**Fix:**
```yaml
permissions:
  contents: write
  pull-requests: write
```

**Socratic response:** "Let's look at your permissions block. `create-pull-request` needs two permissions — which one is missing?"

---

### Blocker 2: `/tmp/` files are empty or missing

**Symptom:** Agent runs but uses wrong/fabricated numbers; dry-run shows empty files.

**Cause:** `gh api` command failed silently, or `jq` filter produced no output.

**Fix:** Add a validation step:
```yaml
pre-agent-steps:
  - name: Fetch repository metrics
    run: |
      gh api "/repos/$/issues?state=open&per_page=100" \
        --jq 'length' > /tmp/open-issues.txt
      cat /tmp/open-issues.txt   # debug: show value in logs
```

**Socratic response:** "Run `gh aw run 16-ground-truth --dry-run` and check whether the `/tmp/` files have values. What does `cat /tmp/open-issues.txt` output in the dry-run logs?"

---

### Blocker 3: Agent doesn't use the real numbers

**Symptom:** PR opens but `CONTRIBUTING.md` contains made-up numbers or placeholder text.

**Cause:** The body doesn't explicitly tell the agent to read the `/tmp/` files. Agents will not discover them on their own.

**Fix:** Be explicit in the body:
```
Read /tmp/open-issues.txt — this file contains exactly one integer: the number of open issues.
Read /tmp/open-prs.txt — this file contains exactly one integer: the number of open pull requests.
Use these exact values. Do not estimate or fabricate.
```

**Socratic response:** "Does your body tell the agent where to find the data? Show me the line where you reference the `/tmp/` files."

---

### Blocker 4: PR opens against wrong branch

**Symptom:** PR is opened but targets a branch that doesn't exist or isn't the default.

**Cause:** `base-branch: main` but the repo's default branch is `master` or something else.

**Fix:** Check `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` and use that value.

---

### Blocker 5: `$` not resolving

**Symptom:** `gh api` call fails with a URL that contains the literal string `$`.

**Cause:** Expression was placed outside a `run:` step, or inside a string that was not interpreted as a GitHub Actions expression.

**Fix:** `$` is valid inside `run:` in `pre-agent-steps:`. Confirm the expression is inside the `run:` block, not in a YAML comment or a string value assigned elsewhere.

---

## Solution Shape

Don't give the full workflow; describe what correct looks like.

A correct `16-ground-truth.md`:
- `pre-agent-steps:` with 3 named steps: one `gh api` for issues, one `gh pr list` for PRs, one `git log` for last commit
- Each writes a single value to a `/tmp/` file
- Body explicitly references each `/tmp/` file path and instructs the agent to use those exact values
- Body asks agent to update only the `## Project Health` section of `CONTRIBUTING.md`
- `safe-outputs: create-pull-request: base-branch: main` with a descriptive `title-prefix`
- Both `contents: write` and `pull-requests: write` in `permissions:`

---

## How to Verify It's Working

1. **Compile:** `gh aw compile 16-ground-truth` — no errors
2. **Dry-run:** `gh aw run 16-ground-truth --dry-run` — `pre-agent-steps:` output should show real numbers in `/tmp/` files
3. **Live run:** Trigger via `workflow_dispatch`
4. **PR check:** A PR should appear with a new branch; diff shows only `## Project Health` section changed in `CONTRIBUTING.md`
5. **Number accuracy:** Open the PR, check the numbers in `CONTRIBUTING.md`. Cross-check against `gh issue list --state open | wc -l` — numbers should match (within a few seconds of drift)

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Read & orient | 3 min | Understand pre-agent-steps flow |
| Write pre-agent-steps | 8 min | 3 fetch commands + write to /tmp/ |
| Write agent body | 7 min | Reference /tmp/ files, describe CONTRIBUTING.md update |
| Configure create-pull-request | 3 min | base-branch, title-prefix, permissions |
| Compile + dry-run | 5 min | Verify /tmp/ files populated in dry-run output |
| Live test | 4 min | Trigger, verify PR opens with real numbers |

**Total: ~30 minutes.**

---

## Extension Ideas (Fast Squads)

1. **More metrics:** Add contributors count (`gh api /repos/{owner}/{repo}/contributors --jq 'length'`), stars, or last release tag
2. **Conditional PR:** Only open a PR if the health metrics have changed since last week (compare against current `CONTRIBUTING.md` content)
3. **Scheduled run:** Change from `workflow_dispatch` to a weekly schedule
4. **Health trend:** Write metrics to `repo-memory` and have a separate workflow chart trends over time (combines 3-01 The Relay with this pattern)

---

## Key Takeaways for Coaches

- **Separation of concerns.** `pre-agent-steps:` = deterministic. Agent body = reasoning. This is good software architecture applied to AI workflows.
- **AI doesn't know your repo state.** This is not a flaw — it's by design. The agent's job is reasoning, not data fetching. `pre-agent-steps:` handles the fetch.
- **`create-pull-request` as a trust dial.** Squads may want to auto-merge. Push back gently: "When would you *not* want to auto-merge? Now build for that case." Most squads arrive at "keep the human in the loop for docs changes."

---

## Reference

**Reference solution note:** This repository does not include separate committed sample-solution files; use the inline sample and validation checklist above.
**pre-agent-steps:** https://github.github.com/gh-aw/reference/frontmatter/#pre-agent-steps  
**create-pull-request:** https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/#create-pull-request  
**gh CLI — gh api:** https://cli.github.com/manual/gh_api
