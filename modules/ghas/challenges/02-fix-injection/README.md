# Activity S02: Fix injection vulnerabilities

**Session outcome:** Your pull requests fix injection with safe APIs at the execution sink and include behavior tests and GHAS results. Two independently reviewed fixes establish a prevention pattern you can apply to comparable code paths.

## Description

Injection occurs when an application interprets user-controlled data as part of a
database query, command, or template expression. Attackers can change the logic to
steal data, bypass authentication, or destroy records. Input validation can enforce
an input policy, but it cannot reliably prevent injection. Stop it at the execution
sink: use parameter binding or ORM-safe APIs for database operations, and keep data
separate from interpretation at command or template sinks.

CodeQL flags SQL and NoSQL injection vulnerabilities in Juice Shop's backend routes. Open those alerts, inspect the code, explain how an attacker can exploit it, and fix it. Record the verified fix and a prevention pattern your team can reuse.

## Objectives

- Filter Security → Code scanning alerts to show injection-related alerts (search for `sql` or `injection`)
- Open each affected file in your editor and read the vulnerable code path with Copilot's help
- Replace unsafe query construction with parameterized queries or ORM-safe alternatives. For command or template injection, use the sink-specific safe API or design rather than input sanitization alone. Test the affected behavior.
- Open pull requests to `main` with the finding, impact, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes to confirm the pattern, then check for the same unsafe pattern in comparable query paths

> [!TIP]
> Working with a real application? Select its own SQL, NoSQL, command, or template injection alerts.

## Copilot tips

- Highlight the vulnerable query and ask: *"This query is vulnerable to SQL injection. Rewrite it using parameterized queries compatible with the Sequelize ORM already in use here."*
- Ask: *"What's the difference between input sanitization and parameterization, and why is parameterization the right fix here?"*
- Review any fix from Copilot Autofix or other Copilot assistance against the approved safe pattern. Submit it through the normal PR and GHAS checks.

Try creating a custom Copilot agent, or repository custom instructions, that suggests parameterized queries when it finds raw string concatenation in a SQL context.

## Learning resources

- [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [Responsible use of AI features for security and code quality](https://docs.github.com/en/code-security/responsible-use/security-and-quality-ai-features)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
