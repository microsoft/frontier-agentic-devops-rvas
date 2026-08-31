# Activity S02: Fix Injection Vulnerabilities

## Description

Injection occurs when an application interprets user-controlled data as part of a
database query, command, or template expression. Attackers can change the logic to
steal data, bypass authentication, or destroy records. Input validation can enforce
an input policy, but it cannot reliably prevent injection. Stop it at the execution
sink: use parameter binding or ORM-safe APIs for database operations, and keep data
separate from interpretation at command or template sinks.

Juice Shop contains SQL and NoSQL injection vulnerabilities in its backend routes. CodeQL has flagged them. Find those alerts, inspect the affected code, explain how an attacker can exploit it, and fix it. Record the validated remediation and a prevention pattern your team can reuse, so the unsafe pattern does not return.

## Objectives

- Filter Security → Code scanning alerts to show injection-related alerts (search for `sql` or `injection`)
- Open each affected file in your editor and read the vulnerable code path with Copilot's help
- Replace unsafe query construction with parameterized queries or ORM-safe alternatives; for command or template injection, use the corresponding sink-specific safe API or design rather than input sanitization alone; then technically validate the affected behavior
- Open pull requests to `main` with the finding, impact, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes to confirm the pattern, then check for the same unsafe pattern in comparable query paths

> [!TIP]
> Working with a real application? Select its own SQL, NoSQL, command, or template injection alerts.

## Copilot Tips

- Highlight the vulnerable query and ask: *"This query is vulnerable to SQL injection. Rewrite it using parameterized queries compatible with the Sequelize ORM already in use here."*
- Ask: *"What's the difference between input sanitization and parameterization, and why is parameterization the right fix here?"*
- If you use Copilot Autofix or other Copilot assistance, treat its output as a proposed remediation: review it against the approved safe pattern and submit it through the normal PR and GHAS checks.

Try creating a custom Copilot agent, or repository custom instructions, that suggests parameterized queries when it finds raw string concatenation in a SQL context.

## Learning Resources

- [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [About Copilot Autofix for code scanning](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-autofix-for-codeql-code-scanning)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
