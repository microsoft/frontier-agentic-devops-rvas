# Activity 3-06: Ground Truth

Track: Continuous Intelligence (Advanced 🔴)  
Estimated time: 30 minutes  
Prerequisites: Activity 00, full Track 2, Activities 3-01 and 3-02

---

## Build

A workflow that runs shell commands through `pre-agent-steps:` before the AI model starts. The commands fetch live repository metrics with the `gh` CLI. The agent uses those numbers to update the `## Project Health` section in `CONTRIBUTING.md`, then opens a pull request through `create-pull-request`.

AI models may invent numbers when the prompt lacks data. `pre-agent-steps:` writes measured values to files before the model runs. The agent then reads those files instead of guessing.

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
> Use a repository in an organization you control. Choose one where live issue, pull request, commit, or release metrics belong in `CONTRIBUTING.md`.
>
> - Have a candidate repo? Use it everywhere this guide references the sample repo, and point the `pre-agent-steps:` commands at that repo's real issues, PRs, commits, and contribution docs.
> - No suitable repo yet? Use the provided sample repo from setup as the safe practice target.
>
> Tell the facilitator which repository and metrics you chose.

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

## Success Criteria

- [ ] `.github/workflows/16-ground-truth.md` compiles without errors
- [ ] `pre-agent-steps:` fetches at least 3 real metrics and writes them to `/tmp/`
- [ ] Agent body references those `/tmp/` files explicitly
- [ ] `CONTRIBUTING.md` is updated with a `## Project Health` section containing real numbers
- [ ] A PR is opened instead of a direct commit
- [ ] PR title matches `title-prefix`
- [ ] Numbers in the PR are accurate (match what `gh` CLI would return for the repo)
- [ ] `permissions: contents: write` and `pull-requests: write` are both declared
- [ ] Using a project, task, or workflow you own, discuss where AI-generated facts have been unreliable and how deterministic input would change what you trust.

---

## Gotchas

- **Repository expression:** `$` resolves to `owner/repo` inside `pre-agent-steps:` run steps.
- **Temporary files:** `/tmp/` files are created for each run and are not committed.
- **Missing `CONTRIBUTING.md`:** The agent creates the file. The PR will contain a new file rather than a patch.
- **Target branch:** `base-branch: main` assumes the default branch is `main`. Change it when needed.
- **Permissions:** `create-pull-request` needs both `contents: write` and `pull-requests: write`.

---

## Tips & Hints

- Test `pre-agent-steps:` first. Add a step that `cat`s the `/tmp/` files and check the dry-run output. If the files are empty or missing, fix the fetch commands before involving the AI.
- Name each file and its contents in the body. For example: "The file `/tmp/open-issues.txt` contains the open issue count."
- Keep the PR small. Instruct the agent to only modify the `## Project Health` section, not rewrite the whole file. Smaller diffs are easier to review.
- `workflow_dispatch:` for testing. Add it alongside your primary trigger so you can run on demand during development.

---

## References

- pre-agent-steps: https://github.github.com/gh-aw/reference/frontmatter/#pre-agent-steps
- create-pull-request safe-output: https://github.github.com/gh-aw/reference/safe-outputs-pull-requests/#create-pull-request
- gh CLI — gh api: https://cli.github.com/manual/gh_api
- gh CLI — gh pr list: https://cli.github.com/manual/gh_pr_list

---

## Help

- "`pre-agent-steps:` not running?" → Check indentation. `pre-agent-steps:` is a top-level frontmatter key, same level as `on:` and `permissions:`.
- "Agent is using the wrong numbers" → Verify the `/tmp/` files contain what you expect. Add a `cat /tmp/open-issues.txt` step to `pre-agent-steps:` and check dry-run output.
- **PR permission error:** Ensure `permissions:` includes both `contents: write` and `pull-requests: write`.
- "Agent modified the wrong part of CONTRIBUTING.md" → Be more explicit in the body: "Only add or replace the section that begins with `## Project Health`. Do not modify any other section."

Ask your coach.

---
