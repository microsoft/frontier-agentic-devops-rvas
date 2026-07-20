**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Bonus

---

## Background

Most workflows are generalists. Daily Testify is a specialist: a workflow with deep testing expertise baked directly into its prompt, running every day to scrutinise your test suite and create issues for concrete improvement opportunities.

In `github/gh-aw`, this pattern produced 19 issues, 13 of which led to merged PRs — a **100% causal chain merge rate**. Every issue that got acted on resulted in merged code. This is the *producer* half of a causal chain: it creates the issues; the Test Improver (4-06) acts on them.

Source: [`github/gh-aw/.github/workflows/daily-testify-uber-super-expert.md`](https://github.com/github/gh-aw/blob/main/.github/workflows/daily-testify-uber-super-expert.md)

## What It Does

- Runs daily on a cron schedule
- Analyses your test suite with embedded domain expertise (test quality, coverage gaps, anti-patterns)
- Creates issues for specific, actionable improvements — not vague suggestions
- Uses `create-issue` only (no PRs) — keeps the signal clean and human-reviewed before action

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This activity is most valuable when Testify studies a real test suite and files issues your team might actually act on. Pick a repository in an org you control where test quality, missing edge cases, or brittle tests matter.
>
> - **Have a candidate repo?** Use it everywhere this guide references the sample repo, and customise the expert persona around that repo's real language, framework, test layout, and quality bar.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

## What You'll Do

1. **Install [`gh aw`](https://github.com/github/gh-aw)** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/github/gh-aw/blob/main/.github/workflows/daily-testify-uber-super-expert.md
   ```

3. **Read the prompt body carefully** — notice how the "uber expert" persona is established. This is the key technique: writing a rich, opinionated system prompt inside the workflow body.

4. **Customise** the expertise to match your test framework and language.

5. **Compile**:
   ```bash
   gh aw compile daily-testify-uber-super-expert
   ```

6. **Trigger manually** and examine the first issue it creates — is it actionable?

## Customize It

- Replace the test framework reference with yours: jest, pytest, rspec, vitest, go test, etc.
- Add repo-specific context to the expert persona: _"This repo uses integration tests extensively; unit test coverage below service boundaries is low"_
- Adjust what counts as "an improvement worth raising": _"Only create an issue if it covers: a missing edge case, an untested error path, or a test that passes for the wrong reason"_
- Set the issue template: label `testing`, assign to a test owner, add to a project board

## Success Criteria

- [ ] `.github/workflows/daily-testify-uber-super-expert.md` exists with valid frontmatter
- [ ] `schedule: cron` trigger is set
- [ ] Expert persona is established in the body (specific, not generic)
- [ ] `safe-outputs: create-issue` is declared — **no** `create-pull-request` here
- [ ] `.lock.yml` compiles without errors
- [ ] Manually triggered run creates at least one actionable issue
- [ ] Issue body is specific: names a file, a function, or a concrete gap — not "add more tests"
- [ ] Coach conversation — what does good test quality really mean for one codebase you own, and which of those judgments would you encode into an agent that files daily testing issues? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

<details>
<summary>💡 Hints</summary>

**"What makes a good 'uber expert' persona?"**
→ Specificity. Don't write "you are a testing expert". Write: "You are an expert in Node.js testing with Jest. You know that `describe` nesting beyond 3 levels is a smell, that `expect.assertions(n)` prevents silent passes in async tests, and that snapshot tests without meaningful expectations are noise."

**"The issues it creates are too vague"**
→ Add an output constraint: _"Each issue must name: 1) the file, 2) the function or test, 3) exactly what is missing or wrong, 4) a one-sentence fix suggestion."_

**"How does this connect to Test Improver (4-06)?"**
→ Test Improver watches for issues with a specific label (e.g., `test-improvement`) and turns them into PRs. Label your Testify issues consistently so the chain connects.

**"I don't have many tests yet"**
→ That's fine — the agent will tell you _where_ tests are missing, which is useful signal even before the Test Improver acts.

**"Should I use create-pull-request instead?"**
→ No. This is an intentional design: human review between analysis and action. The 100% merge rate comes from that review gate, not from skipping it.

</details>

