# Activity S02: Fix injection vulnerabilities

**Session outcome:** You've merged a reviewed fix that uses a safe API at the execution sink. Behavior tests and a default-branch rescan confirm it.

Start with the [remediation checklist](../../resources/start-remediation.md), then use this case for an injection finding. The XSS and authorization cases are alternatives.

## Description

Injection happens when an application treats user-controlled data as part of a
database query, command, or template expression. Attackers can change the logic to
steal data, bypass authentication, or destroy records. Input validation can enforce
an input policy, but it can't reliably prevent injection. **Stop it at the execution
sink:** use parameter binding or ORM-safe APIs for database operations, and keep data
separate from code at command and template sinks.

CodeQL flags SQL and NoSQL injection vulnerabilities in Juice Shop's backend routes. Pick one alert, read the code, work out how an attacker would exploit it, and fix it. Record the verified fix and a prevention pattern your team can reuse.

## Objectives

- Filter Security → Code scanning alerts to show injection-related alerts (search for `sql` or `injection`)
- Pick one alert and read its vulnerable code path with Copilot's help
- Replace unsafe query construction with parameterized queries or ORM-safe alternatives. For command or template injection, use the sink-specific safe API or design rather than input sanitization alone. Test the affected behavior.
- Open a pull request with the alert link and tests for normal input and the unsafe input path
- Get human review through the normal controls, then merge. Check that the default-branch rescan marks the alert fixed
- Explain the safe query pattern in the PR. Checking similar paths is fine, but a second fix is optional

> [!TIP]
> Working with a real application? Pick its own SQL, NoSQL, command, or template injection alerts.

## Copilot tips

- Highlight the vulnerable query and ask: *"This query is vulnerable to SQL injection. Rewrite it using parameterized queries compatible with the Sequelize ORM already in use here."*
- Ask: *"What's the difference between input sanitization and parameterization, and why is parameterization the right fix here?"*
- Check any fix from Copilot Autofix or other Copilot help against the approved safe pattern, and submit it through the normal PR and GHAS checks.

If the team needs it, add repository instructions for this safe query pattern.

## Learning resources

- [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [Responsible use of AI features for security and code quality](https://docs.github.com/en/code-security/responsible-use/security-and-quality-ai-features)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
