Track: Production Patterns (Advanced 🟣)
Estimated time: 75 minutes
Tier: Bonus

---

## Background

Malicious code can arrive in a dependency update or an ordinary-looking refactor. The Malicious Code Scan reviews recent changes each day and opens alerts for human investigation — an additional detection signal for code-injection campaigns, compromised contributors, and dependency poisoning. It does not block changes, prevent deployment, or replace review and security controls.

Source: [`githubnext/agentics/workflows/daily-malicious-code-scan.md`](https://github.com/githubnext/agentics/blob/main/workflows/daily-malicious-code-scan.md)

## Behavior

- Runs daily on a cron schedule
- Reviews commits from the past N days (configurable)
- Checks changes for obfuscated logic, unexpected network calls, exfiltration patterns, dynamic-string `eval`/`exec`, and suspicious environment-variable access
- Opens a `create-issue` alert with the specific commit, file, and line number

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): tune the workflow to the real languages, recent commits, and suspicious pattern categories of a repo you own.

## Steps

1. Install and verify `gh aw` with the [GHAW setup guide](../../setup.md).

2. Pull the production workflow:
   ```bash
   gh aw add-wizard https://github.com/githubnext/agentics/blob/main/workflows/daily-malicious-code-scan.md
   ```

3. Read the suspicious-pattern definitions in the body. The AI uses these rules to flag code.

4. Customise the patterns for your language and threat model.

5. Compile:
   ```bash
   gh aw compile daily-malicious-code-scan
   ```

6. Test it by adding a benign-but-flaggable pattern to a branch (e.g., a base64-encoded eval), then manually triggering the scan.

7. Verify the alert issue contains enough detail to act on.

## Adapt it

- Scope the scan window: _"Review commits merged in the last 7 days"_ or _"Review all changes to `src/` since the last scan issue"_
- Add language-specific patterns: for Python, flag `exec(compile(...))` and `__import__`; for Node.js, flag `child_process.exec` with dynamic strings
- Set alert severity routing: critical patterns (exfiltration, credential access) open a high-priority issue; low-risk patterns (unusual imports) just add a comment
- Restrict false positives: _"Only flag the pattern in code added or modified in the last 7 days. Ignore pre-existing code."_

---

<details>
<summary>💡 Hints</summary>

"What patterns should I tell it to look for?"
→ Start with the classic supply-chain indicators:
- Base64/hex encoded strings being evaluated
- `fetch`, `http.request`, or `curl` calls to external URLs added in the last week
- Access to `process.env` / `os.environ` for keys like `TOKEN`, `SECRET`, `KEY`, `PASSWORD`
- Dynamic `require`/`import` with non-string arguments
- New files added to `.github/workflows/` that weren't in a PR

"How do I test this without writing real malicious code?"
→ Add a clearly fake pattern: `// SCAN-TEST: eval(Buffer.from('dGVzdA==').toString)`. The comment marks it as intentional, but the scanner can still flag it. Remove it after testing.

"This will have too many false positives"
→ Constrain aggressively: _"Only flag code added by commits from outside the organisation (check author's membership). Internal contributors are pre-screened."_

"Should alerts auto-revert the commit?"
→ Not in this activity. Use issue creation and human review as the gate. Auto-revert with the `revert-commit` safe output is an extension.

</details>
