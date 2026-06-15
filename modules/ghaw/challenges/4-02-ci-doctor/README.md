**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Core

---

## Background

CI breaks at the worst times. Normally a developer has to open the Actions tab, scroll through log noise, and manually reason about root cause. CI Doctor automates that investigation: it fires on a failed workflow run, pulls the logs, analyses them, and opens a structured diagnostic issue with the root cause and suggested fix.

In `github/gh-aw`, this workflow proposed 13 PRs with a **69% merge rate** (9 merged). That's a CI-fix pipeline running mostly on autopilot.

Source: `githubnext/agentics/workflows/ci-doctor.md`

## What It Does

- Triggers on `on: workflow_run` when a target CI workflow completes with `conclusion: failure`
- Fetches the run logs from the GitHub API
- Analyses log output for the failure pattern (compile error, test failure, flaky test, etc.)
- Opens a `create-issue` with structured root-cause analysis and a suggested remediation

## What You'll Do

1. **Install gh aw** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/ci-doctor.md
   ```

3. **Inspect the frontmatter** — note how `workflow_run` trigger names the workflows it watches, and what `workflows:` / `types: [completed]` + a condition on `conclusion` looks like.

4. **Customise** for your repo — change `workflows:` to list the actual CI workflow names you want to watch (e.g., `[CI, tests, build]`).

5. **Compile**:
   ```bash
   gh aw compile .github/workflows/ci-doctor.md
   ```

6. **Trigger a test failure** (break a test intentionally in a branch, push, let CI fail) and watch the Doctor fire.

7. Commit both the workflow and its `.lock.yml`.

## Customize It

- Change the `workflows:` list to name exactly the CI workflows you want to monitor (use the exact workflow name from your `.github/workflows/` files)
- Tune the diagnostic prompt: add repo-specific context like "this repo uses Node 20" or "tests run with vitest"
- Adjust the issue template — add labels, assignees, or project board routing to the `create-issue` output
- Set `branches: [main]` if you only want to watch failures on main (not every branch)

## Success Criteria

- [ ] `.github/workflows/ci-doctor.md` exists with valid gh-aw frontmatter
- [ ] Trigger is `on: workflow_run` scoped to at least one named workflow
- [ ] `types: [completed]` is present and the body handles the `conclusion: failure` check
- [ ] `safe-outputs: create-issue` is declared
- [ ] `.github/workflows/ci-doctor.lock.yml` compiles without errors
- [ ] Intentional CI failure causes Doctor to open a diagnostic issue
- [ ] Issue contains: failure summary, likely root cause, suggested fix

---

<details>
<summary>💡 Hints</summary>

**"How does workflow_run know which run failed?"**
→ `github.event.workflow_run.conclusion` is `"failure"` on failures. Include a check in your body: _"Only investigate if the triggering workflow concluded with failure."_

**"How do I fetch the logs?"**
→ The `tools: github: toolsets: [actions]` toolset gives the agent access to run logs. Alternatively, include explicit log fetching instructions pointing to `github.event.workflow_run.logs_url`.

**"My CI doesn't fail often — how do I test this?"**
→ Add a temporary step to a test workflow: `run: exit 1`. Push to a branch, let it fail, then revert.

**"The issue body is too long / too noisy"**
→ Constrain the prompt: _"Keep the issue body to 3 sections: 1) What failed, 2) Likely cause, 3) Suggested fix. Max 200 words."_

**"workflow_run vs push — what's the difference for this use case?"**
→ `workflow_run` lets you react to another workflow completing (including in other branches). `push` would fire before CI results are known.

</details>

---

<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-02-ci-doctor/Student/README.md" class="btn btn--primary">📘 Student Guide</a>
<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-02-ci-doctor/Coach/README.md" class="btn btn--ghost">🎓 Coach Guide</a>
