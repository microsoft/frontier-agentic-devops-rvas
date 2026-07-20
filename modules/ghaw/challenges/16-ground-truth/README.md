# Activity 3-06: Ground Truth

**Track:** Continuous Intelligence (Advanced 🔴)  
**Estimated time:** 30 minutes  
**Prerequisites:** Activity 00, full Track 2, Activities 3-01 and 3-02

---

## What You'll Build

A workflow that runs deterministic shell commands *before* the AI model starts — using `pre-agent-steps:` — to fetch real, live repo metrics via the `gh` CLI. The agent is given those numbers and uses them to update `CONTRIBUTING.md` with a "## Project Health" section. Instead of committing directly, it opens a pull request via the `create-pull-request` safe-output, keeping a human in the loop.

**Why this matters:** AI models hallucinate numbers. If you ask "how many open issues does this repo have?" without giving the model real data, it will guess. `pre-agent-steps:` closes that gap: shell commands run first, write real data to files, and the agent reads those files before reasoning. The result is grounded, accurate output — not plausible fiction.

---

## Goals

By the end of this activity, your squad will:

1. ✅ Use `pre-agent-steps:` to fetch real repo metrics via `gh` CLI
2. ✅ Pass those metrics to the agent via files
3. ✅ Have the agent update `CONTRIBUTING.md` with live data
4. ✅ Open a PR (not a direct commit) using `create-pull-request`
5. ✅ Compile and dry-run successfully

---

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This activity is most valuable when the grounded facts come from a repository whose health summary your team might actually publish. Pick a repository in an org you control where live issue, PR, commit, or release metrics would make a useful `CONTRIBUTING.md` update.
>
> - **Have a candidate repo?** Use it everywhere this guide references the sample repo, and point the `pre-agent-steps:` commands at that repo's real issues, PRs, commits, and contribution docs.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

## Background: `pre-agent-steps:`

`pre-agent-steps:` is a list of named shell steps that run before the AI model is invoked. They behave like GitHub Actions `run:` steps — you get full access to `gh`, `jq`, environment variables, and `$` expressions.

```yaml
pre-agent-steps:
  - name: Fetch repository metrics
    run: |
      gh api "/repos/$/issues?state=open&per_page=100" \
        --jq 'length' > /tmp/open-issues.txt
      gh pr list --state open --json number --jq 'length' > /tmp/open-prs.txt
      git log -1 --format="%ci" > /tmp/last-commit.txt
```

The files written to `/tmp/` are ephemeral — they exist only for the duration of this workflow run. The agent can read them directly by path.

**Key point:** These steps run as deterministic shell — no AI involved. The AI model is only called after `pre-agent-steps:` completes.

---

## Background: `create-pull-request`

The `create-pull-request` safe-output tells the gh-aw runtime to open a pull request containing any files the agent modified during its run. The agent does not commit directly; changes are staged and a PR is opened for human review.

```yaml
safe-outputs:
  create-pull-request:
    base-branch: main
    title-prefix: "docs: update CONTRIBUTING.md with current project health"
```

The `title-prefix` sets the PR title. The agent can suggest additional context in the PR body.

---

## Activity

### Step 1: Write the `pre-agent-steps:`

Fetch at least 3 real data points before the agent runs:

- **Open issue count:** Use `gh api` with a `--jq 'length'` filter
- **Open PR count:** Use `gh pr list --state open --json number --jq 'length'`
- **Last commit date:** Use `git log -1 --format="%ci"`

Write each value to a `/tmp/` file.

### Step 2: Write the agent body

In the workflow body, instruct the agent to:

1. Read the `/tmp/` files to get the real numbers
2. Update `CONTRIBUTING.md` by adding (or replacing) a `## Project Health` section with those numbers
3. Keep the rest of `CONTRIBUTING.md` intact

Tell the agent explicitly where to find the data:

```
Read /tmp/open-issues.txt for the current open issue count.
Read /tmp/open-prs.txt for the number of open pull requests.
Read /tmp/last-commit.txt for the date of the last commit.
```

### Step 3: Configure `create-pull-request`

Add `create-pull-request` to `safe-outputs` with a `base-branch` of `main`. The agent's changes to `CONTRIBUTING.md` will land in a new branch, and a PR will be opened automatically.

### Step 4: Set permissions

`create-pull-request` requires both `contents: write` (to push a branch) and `pull-requests: write` (to open the PR). Both must be declared.

### Step 5: Compile and dry-run

```bash
gh aw compile 16-ground-truth
gh aw run 16-ground-truth --dry-run
```

The dry-run will execute `pre-agent-steps:` and show you the values captured — a quick sanity check before running for real.

---

## Success Criteria

- [ ] `.github/workflows/16-ground-truth.md` compiles without errors
- [ ] `pre-agent-steps:` fetches at least 3 real metrics and writes them to `/tmp/`
- [ ] Agent body references those `/tmp/` files explicitly
- [ ] `CONTRIBUTING.md` is updated with a `## Project Health` section containing real numbers
- [ ] A PR is opened — not a direct commit
- [ ] PR title matches `title-prefix`
- [ ] Numbers in the PR are accurate (match what `gh` CLI would return for the repo)
- [ ] `permissions: contents: write` and `pull-requests: write` are both declared
- [ ] Coach conversation — where has an AI confidently produced numbers or facts it made up in your work, and how would feeding it deterministic data first change what you would trust it to output? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Gotchas

- **`$`** — this expression works inside `run:` steps in `pre-agent-steps:`. It resolves to `owner/repo` at runtime.
- **`/tmp/` files are ephemeral** — they are created fresh each run and are not committed. The agent reads them during its session; they do not persist after the run.
- **Missing `CONTRIBUTING.md`** — if the file doesn't exist, the agent will create it. That's fine — just note the PR will contain a new file, not a patch.
- **PR target branch** — `base-branch: main` assumes your default branch is `main`. Change to `master` or your actual default if needed.
- **Permissions scope** — `contents: write` alone is not enough; you also need `pull-requests: write` for the PR to open.

---

## Tips & Hints

- **Test `pre-agent-steps:` first.** Add a step that `cat`s the `/tmp/` files and check the dry-run output. If the files are empty or missing, fix the fetch commands before involving the AI.
- **Be explicit in the body.** Agents do better when you say "The file `/tmp/open-issues.txt` contains exactly one number — the count of open issues" rather than leaving them to discover the file.
- **Keep the PR small.** Instruct the agent to only modify the `## Project Health` section, not rewrite the whole file. Smaller diffs are easier to review.
- **`workflow_dispatch:` for testing.** Add it alongside your primary trigger so you can run on demand during development.

---

## References

- **pre-agent-steps:** https://github.github.com/gh-aw/reference/frontmatter/#pre-agent-steps
- **create-pull-request safe-output:** https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/#create-pull-request
- **gh CLI — gh api:** https://cli.github.com/manual/gh_api
- **gh CLI — gh pr list:** https://cli.github.com/manual/gh_pr_list

---

## Stuck?

- **"`pre-agent-steps:` not running?"** → Check indentation. `pre-agent-steps:` is a top-level frontmatter key, same level as `on:` and `permissions:`.
- **"Agent is using the wrong numbers"** → Verify the `/tmp/` files contain what you expect. Add a `cat /tmp/open-issues.txt` step to `pre-agent-steps:` and check dry-run output.
- **"PR not opening — permission error"** → Ensure both `contents: write` and `pull-requests: write` are in `permissions:`.
- **"Agent modified the wrong part of CONTRIBUTING.md"** → Be more explicit in the body: "Only add or replace the section that begins with `## Project Health`. Do not modify any other section."

Ask your coach.

---
