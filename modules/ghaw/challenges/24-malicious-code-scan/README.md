**Session outcome:** Your daily workflow scans recent commits for suspicious patterns in the repository's languages and opens issues with commit and code references. It does not block changes or replace human review.

## Background

Malicious code can arrive in a dependency update or an ordinary-looking refactor. The Malicious Code Scan reviews recent changes each day and opens alerts for human investigation. It can help detect code-injection campaigns, compromised contributors, and dependency poisoning. It does not block changes, prevent deployment, or replace review and security controls.

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

6. Add a harmless test pattern to a branch, such as a base64-encoded eval in a comment, then trigger the scan manually.

7. Verify the alert issue contains enough detail to act on.

## Adapt it

- Scope the scan window: _"Review commits merged in the last 7 days"_ or _"Review all changes to `src/` since the last scan issue"_
- Add language-specific patterns: for Python, flag `exec(compile(...))` and `__import__`; for Node.js, flag `child_process.exec` with dynamic strings
- Set alert severity routing: critical patterns (exfiltration, credential access) open a high-priority issue; low-risk patterns (unusual imports) just add a comment
- Restrict false positives: _"Only flag the pattern in code added or modified in the last 7 days. Ignore pre-existing code."_

---

<details>
<summary>Hints</summary>

Start with these supply-chain indicators:
- Base64/hex encoded strings being evaluated
- `fetch`, `http.request`, or `curl` calls to external URLs added in the last week
- Access to `process.env` / `os.environ` for keys like `TOKEN`, `SECRET`, `KEY`, `PASSWORD`
- Dynamic `require`/`import` with non-string arguments
- New files added to `.github/workflows/` that weren't in a PR

Test with a clearly fake pattern: `// SCAN-TEST: eval(Buffer.from('dGVzdA==').toString)`. The comment marks it as intentional, but the scanner can still flag it. Remove it after testing.

To limit false positives, narrow the prompt: _"Only flag code added by commits from outside the organisation (check author's membership). Internal contributors are pre-screened."_

Use issue creation and human review in this activity. You can add automatic reverts with the `revert-commit` safe output later.

</details>
