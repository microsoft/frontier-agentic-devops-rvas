# Activity 3-06: Ground Truth

Track: Continuous Intelligence (Advanced 🔴)  
Estimated time: 30 minutes  
Prerequisites: Activity 00, full Track 2, Activities 3-01 and 3-02

---

## Build

A workflow that runs shell commands through `pre-agent-steps:` before the AI model starts, fetching live repository metrics with the `gh` CLI. The agent uses those numbers to update the `## Project Health` section in `CONTRIBUTING.md`, then opens a pull request through `create-pull-request`.

Without measured data, AI models may invent numbers. `pre-agent-steps:` writes real values to files first, so the agent reads facts instead of guessing.

---

## What you'll practice

1. Fetch repository metrics with `pre-agent-steps:` and the `gh` CLI
2. Pass those metrics to the agent through files
3. Update `CONTRIBUTING.md` with measured data
4. Open a PR, not a direct commit, with `create-pull-request`
5. Compile and dry-run the workflow

---

> [!IMPORTANT]
> Bring your own repo (do this first)
>
> Use a repository where live issue, PR, commit, or release metrics belong in `CONTRIBUTING.md`. Point `pre-agent-steps:` at that repo's real data. No candidate repo yet? Use the provided sample repo from setup.

## Background: `pre-agent-steps:`

`pre-agent-steps:` is a list of named shell steps that run before the AI model. They behave like GitHub Actions `run:` steps and can use `gh`, `jq`, environment variables, and `$` expressions.

```yaml
pre-agent-steps:
  - name: Fetch repository metrics
    run: |
      gh api "/repos/$/issues?state=open&per_page=100" \
        --jq 'length' > /tmp/open-issues.txt
      gh pr list --state open --json number --jq 'length' > /tmp/open-prs.txt
      git log -1 --format="%ci" > /tmp/last-commit.txt
```

Files written to `/tmp/` exist only for the workflow run. The agent can read them directly by path.

These steps run as deterministic shell commands. The AI model starts only after `pre-agent-steps:` completes.

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

- Open issue count: Use `gh api` with a `--jq 'length'` filter
- Open PR count: Use `gh pr list --state open --json number --jq 'length'`
- Last commit date: Use `git log -1 --format="%ci"`

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

The dry run executes `pre-agent-steps:` and shows the captured values. Check them before a live run.

---

## Gotchas & Troubleshooting

- `$` resolves to `owner/repo` inside `pre-agent-steps:` run steps. Files written to `/tmp/` exist only for the run and are not committed.
- Test `pre-agent-steps:` first: add a `cat` step for each `/tmp/` file and check the dry-run output before involving the AI model. If the agent uses wrong numbers later, this is the first thing to re-check.
- `pre-agent-steps:` is a top-level frontmatter key, same indentation level as `on:` and `permissions:`.
- If `CONTRIBUTING.md` is missing, the agent creates it — the PR will contain a new file rather than a patch.
- `create-pull-request` requires both `contents: write` and `pull-requests: write`; a missing permission causes a PR permission error. `base-branch: main` assumes the default branch is `main` — change it if needed.
- Keep the PR small: tell the agent explicitly to only add/replace the `## Project Health` section and leave the rest of the file untouched.
- Add `workflow_dispatch:` alongside the primary trigger so you can run on demand while developing.

---

## References

- pre-agent-steps: https://github.github.com/gh-aw/reference/frontmatter/#pre-agent-steps
- create-pull-request safe-output: https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/#create-pull-request
- gh CLI — gh api: https://cli.github.com/manual/gh_api
- gh CLI — gh pr list: https://cli.github.com/manual/gh_pr_list
