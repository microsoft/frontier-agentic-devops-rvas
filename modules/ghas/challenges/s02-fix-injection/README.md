# Challenge S-01: Fix Injection Vulnerabilities

## Description

Injection is consistently the most exploited class of vulnerability in web applications. When user-controlled input reaches a database query, command interpreter, or template engine without proper sanitization, attackers can rewrite the logic — stealing data, bypassing authentication, or destroying records.

Juice Shop contains real SQL injection and NoSQL injection vulnerabilities in its backend routes. CodeQL has already flagged them. In this challenge you'll locate those alerts, open the affected code, understand exactly why it's exploitable, and write the fix. The goal isn't just to make the CodeQL alert disappear — it's to understand the safe coding pattern so you can apply it anywhere.

You're working as a developer fixing real application code. Not configuring tools. Not clicking settings. Writing code.

## Objectives

- Filter **Security → Code scanning alerts** to show injection-related alerts (search for `sql` or `injection`)
- Open each affected file in your editor and read the vulnerable code path with Copilot's help
- Fix at least 2 injection vulnerabilities by replacing string concatenation with parameterized queries or ORM-safe alternatives
- Open a pull request to `main` for each fix with a description of: what was wrong, what an attacker could have done, and how the fix addresses it
- Review the PR CodeQL/code scanning check and annotations to confirm the fixed pattern is no longer flagged on your branch

## Success Criteria

- [ ] At least 2 injection vulnerabilities fixed in the code
- [ ] Fixes use parameterized queries or equivalent safe patterns — not input sanitization alone
- [ ] Pull requests to `main` opened with clear descriptions of the vulnerability and remediation
- [ ] Copilot Autofix tried on at least one alert (click "Generate fix" in the Security tab)
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns
- [ ] Coach conversation — where in your own codebase is user-controlled input most likely reaching a database query without parameterization, and what data could an attacker extract or modify if they found that path before your team did? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Highlight the vulnerable query and ask: *"This query is vulnerable to SQL injection. Rewrite it using parameterized queries compatible with the Sequelize ORM already in use here."*
- Ask: *"What's the difference between input sanitization and parameterization, and why is parameterization the right fix here?"*
- Use Copilot Autofix in the Security tab — click an alert and hit **Generate fix** to see its proposed remediation, then review and refine it.

**Power move:** If you've done C-00, create a custom Copilot agent that's instructed to always suggest parameterized queries when it sees raw string concatenation in SQL context.

## Learning Resources

- [OWASP: SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [About Copilot Autofix for code scanning](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-autofix-for-codeql-code-scanning)
- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
