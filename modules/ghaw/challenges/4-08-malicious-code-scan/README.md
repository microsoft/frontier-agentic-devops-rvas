**Track:** Production Patterns (Advanced 🟣)
**Estimated time:** 30 minutes
**Tier:** Bonus

---

## Background

Supply-chain attacks are subtle: malicious code appears as a normal dependency update or an innocent-looking refactor. By the time a human reviewer notices, it may have already shipped. The Malicious Code Scan runs daily, reviews recent code changes for suspicious patterns, and alerts before anything reaches production.

This is your automated defence layer against code-injection campaigns, compromised contributors, and dependency poisoning. Sourced from `githubnext/agentics`.

Source: [`githubnext/agentics/workflows/daily-malicious-code-scan.md`](https://github.com/githubnext/agentics/blob/main/workflows/daily-malicious-code-scan.md)

## What It Does

- Runs daily on a cron schedule
- Reviews commits from the past N days (configurable)
- Analyses changes for: obfuscated logic, unexpected network calls, exfiltration patterns, eval/exec of dynamic strings, suspicious env variable access
- Opens a `create-issue` alert for anything worth investigating — with the specific commit, file, and line number

## What You'll Do

1. **Install [`gh aw`](https://github.com/github/gh-aw)** (if not already done):
   ```bash
   curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
   ```

2. **Pull the production workflow**:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/daily-malicious-code-scan.md
   ```

3. **Read the suspicious-pattern definitions** in the body — these are the heuristics the AI uses to flag code.

4. **Customise** the patterns for your language and threat model.

5. **Compile**:
   ```bash
   gh aw compile daily-malicious-code-scan
   ```

6. **Test it** by adding a benign-but-flaggable pattern to a branch (e.g., a base64-encoded eval), then manually triggering the scan.

7. Verify the alert issue contains enough detail to act on.

## Customize It

- Scope the scan window: _"Review commits merged in the last 7 days"_ or _"Review all changes to `src/` since the last scan issue"_
- Add language-specific patterns: for Python, flag `exec(compile(...))` and `__import__`; for Node.js, flag `child_process.exec` with dynamic strings
- Set alert severity routing: critical patterns (exfiltration, credential access) open a high-priority issue; low-risk patterns (unusual imports) just add a comment
- Restrict false-positive noise: _"Only flag if the pattern appears in code added or modified in the last 7 days — not in pre-existing code"_

## Success Criteria

- [ ] `.github/workflows/daily-malicious-code-scan.md` exists with valid frontmatter
- [ ] `schedule: cron` trigger is set
- [ ] Scan window (days / commits) is defined in the body
- [ ] At least 3 suspicious pattern categories are named in the body
- [ ] `safe-outputs: create-issue` is declared
- [ ] `.lock.yml` compiles without errors
- [ ] Test pattern (benign flaggable code) causes the scan to open an alert issue
- [ ] Alert issue contains: file path, commit SHA, line number, and explanation of why it was flagged
- [ ] Coach conversation — what would it take for you to rely on a daily agent scanning your code changes for supply-chain red flags, and how would you handle false positives without tuning out the real threats? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

<details>
<summary>💡 Hints</summary>

**"What patterns should I tell it to look for?"**
→ Start with the classic supply-chain indicators:
- Base64/hex encoded strings being evaluated
- `fetch`, `http.request`, or `curl` calls to external URLs added in the last week
- Access to `process.env` / `os.environ` for keys like `TOKEN`, `SECRET`, `KEY`, `PASSWORD`
- Dynamic `require`/`import` with non-string arguments
- New files added to `.github/workflows/` that weren't in a PR

**"How do I test this without writing real malicious code?"**
→ Add a clearly fake pattern: `// SCAN-TEST: eval(Buffer.from('dGVzdA==').toString)` — the comment marks it as intentional, but the pattern is flaggable. Remove it after testing.

**"This will have too many false positives"**
→ Constrain aggressively: _"Only flag code added by commits from outside the organisation (check author's membership). Internal contributors are pre-screened."_

**"How is this different from CodeQL / SAST tools?"**
→ Complementary, not competing. [CodeQL code scanning](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning-with-codeql) knows ASTs and known CVE patterns. This agent reasons about intent, context, and novel patterns that rule-based tools miss. Run both.

**"Should alerts auto-revert the commit?"**
→ Not in this challenge. Issue creation + human review is the right gate here. Auto-revert is a more advanced pattern with revert-commit safe-output — that's an extension.

</details>

