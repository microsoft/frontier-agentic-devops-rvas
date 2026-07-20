# Activity S02 — Fix Injection Vulnerabilities

## Description

Injection is consistently the most exploited class of vulnerability in web applications. When user-controlled input reaches a database query, command interpreter, or template engine without proper sanitization, attackers can rewrite the logic — stealing data, bypassing authentication, or destroying records.

Juice Shop contains real SQL injection and NoSQL injection vulnerabilities in its backend routes. CodeQL has already flagged them. In this activity you'll locate those alerts, open the affected code, understand exactly why it's exploitable, and write the fix. The work produces delivery evidence: a technically validated remediation and a reusable prevention pattern your team can apply to future changes.

You're working as a delivery team fixing real application code and establishing the review expectation that keeps the unsafe pattern from returning. Copilot Autofix or other Copilot assistance can propose work; it remains subject to human review and your existing PR and GHAS controls.

## Objectives

- Filter **Security → Code scanning alerts** to show injection-related alerts (search for `sql` or `injection`)
- Open each affected file in your editor and read the vulnerable code path with Copilot's help
- Replace unsafe string construction with parameterized queries or ORM-safe alternatives, and technically validate the affected behavior
- Open pull requests to `main` with the finding, impact, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes as a practical evidence threshold, then check for the same unsafe pattern in comparable query paths

> [!IMPORTANT]
> **Bring your own application (do this first)**
>
> This activity is most valuable when the injection fixes *outlive the delivery session*. Use the real application repository you want to secure so the CodeQL findings, pull requests, and safer query patterns land in code your team keeps.
>
> - **Have a candidate?** If you have an application repo in an organization you control with GHAS enabled, use it everywhere this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice-Shop-specific setup and pick real SQL, NoSQL, command, or template-injection alerts from your own repo instead of the Juice Shop examples.
> - **No suitable one?** Use the fallback from S00: OWASP Juice Shop as a safe practice target for fixing known injection flaws.
>
> Tell your coach which path you took — bringing your own is the goal; Juice Shop is the fallback.
>

## Success Criteria

- [ ] A technically validated injection fix uses parameterized queries or an ORM-safe alternative — not input sanitization alone — confirms expected query behavior, and retains PR/review evidence plus relevant GHAS validation.
- [ ] A reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md` states the unsafe pattern/finding class, approved safe pattern, where it applies, PR/review evidence, relevant GHAS validation, named owner, and how the expectation applies to human- and agent-authored changes.
- [ ] Two independently reviewed fixes are used as a practical evidence threshold; completion depends on both the technically validated fix and the reusable prevention pattern record, not the count alone.
- [ ] Any Copilot Autofix or other Copilot assistance is treated as proposed work, reviewed by a human, and handled through existing PR and GHAS controls.
- [ ] Coach conversation — where in your own codebase is user-controlled input most likely reaching a database query without parameterization, and what data could an attacker extract or modify if they found that path before your team did? Talk it through with your coach and connect it to a real project, task, or workflow you own.
- [ ] Coach conversation — where in your own codebase is user-controlled input most likely reaching a database query without parameterization, and what data could an attacker extract or modify if they found that path before your team did? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Highlight the vulnerable query and ask: *"This query is vulnerable to SQL injection. Rewrite it using parameterized queries compatible with the Sequelize ORM already in use here."*
- Ask: *"What's the difference between input sanitization and parameterization, and why is parameterization the right fix here?"*
- If you use Copilot Autofix or other Copilot assistance, treat its output as a proposed remediation: review it against the approved safe pattern and submit it through the normal PR and GHAS checks.

**Power move:** Create a custom Copilot agent (or repository custom instructions) that always suggests parameterized queries when it sees raw string concatenation in a SQL context.

## Learning Resources

- [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [About Copilot Autofix for code scanning](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-autofix-for-codeql-code-scanning)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
