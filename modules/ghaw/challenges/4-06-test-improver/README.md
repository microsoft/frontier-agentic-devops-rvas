**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Bonus

---

## Background

The Test Improver is the *consumer* half of the causal chain that begins with Daily Testify. Where Testify identifies what's wrong, the Test Improver writes the fix — it detects coverage gaps in your codebase and opens PRs with the new tests already written.

Run together, the pair operates as an autonomous testing pipeline: analyst identifies gaps, implementer fills them, PRs land for human review. The pattern comes from `githubnext/agentics` and pairs naturally with the issues created by Challenge 4-05.

Source: `githubnext/agentics/workflows/daily-test-improver.md`

## What It Does

- Runs daily on a cron schedule
- Scans the codebase for functions, methods, or paths with no corresponding test coverage
- Writes new tests incrementally — one focused PR at a time
- Uses `safe-outputs: create-pr` so maintainers review before merge

## What You'll Do

1. **Install gh aw** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/daily-test-improver.md
   ```

3. **Inspect the body** — note how it scopes what "improvement" means and how it structures PRs to be small and reviewable.

4. **Customise** the workflow for your language, framework, and coverage targets.

5. **Compile**:
   ```bash
   gh aw compile .github/workflows/daily-test-improver.md
   ```

6. **Dry-run** to preview what tests it would write:
   ```bash
   gh aw run --dry-run .github/workflows/daily-test-improver.md
   ```

7. Evaluate the preview — would you merge those tests?

## Customize It

- Specify your test framework explicitly in the body: `"Tests are written in pytest with fixtures in conftest.py"` or `"Tests use Jest with React Testing Library"`
- Set a coverage target: _"Focus on functions in `src/` that have no corresponding test in `tests/`"_
- Control PR size: _"Open one PR per file modified. Each PR should add at most 3 new test cases."_
- If using the Testify causal chain (4-05): instruct the Improver to check for open issues labelled `test-improvement` and act on them first

## Success Criteria

- [ ] `.github/workflows/daily-test-improver.md` exists with valid frontmatter
- [ ] `schedule: cron` trigger is set
- [ ] Test framework and language are specified in the body
- [ ] Coverage gap detection logic is in the body (not just "write more tests")
- [ ] `safe-outputs: create-pr` is declared
- [ ] `.lock.yml` compiles without errors
- [ ] Dry-run produces at least one new test file or function
- [ ] Proposed test is syntactically valid for your framework

---

<details>
<summary>💡 Hints</summary>

**"The generated tests are trivial / always pass trivially"**
→ Add a quality constraint: _"Do not write tests that only assert the function returns something. Each test must assert a specific value, side-effect, or error condition."_

**"How do I scope it to only untested code?"**
→ Give it a heuristic: _"For each public function in `src/`, check if a test file in `tests/` imports or calls that function. If not, it needs a test."_

**"This + Testify — how does the chain actually connect?"**
→ Add to the Improver body: _"Before scanning for gaps, check open issues labelled `test-improvement`. If any exist, implement the test described in the issue body first. Close the issue in the PR."_

**"The PR has test failures itself"**
→ That's expected when the agent writes tests for code with bugs — the test is correct, the code isn't. This is useful signal. Don't filter it out.

**"Should Testify and Improver run at the same time?"**
→ Offset them: Testify at 9am, Improver at 10am. This gives Testify time to create issues that Improver can then pick up in the same day's run.

</details>

---

<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-06-test-improver/Student/README.md" class="btn btn--primary">📘 Student Guide</a>
<a href="https://github.com/microsoft/frontier-ghaw-hackathon/blob/main/challenges/track-4-production-patterns/4-06-test-improver/Coach/README.md" class="btn btn--ghost">🎓 Coach Guide</a>
