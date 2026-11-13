# Activity S02: Fix a CodeQL finding

**Session outcome:** You've merged a reviewed fix for one code finding. Tests prove the fix, and a default-branch rescan confirms it.

Start with the [remediation checklist](../../resources/start-remediation.md). Then pick **one** case below that matches your finding. You don't need the others.

## Pick your case

| Finding | Fix at | Prove it with |
|---|---|---|
| **Injection** (SQL, NoSQL, command, template) | The execution sink: parameter binding, ORM-safe APIs, or sink-specific safe APIs | Tests for normal input and the unsafe input path |
| **XSS** (reflected or stored) | The output context: HTML body, attribute, JavaScript string, or URL. Each needs different encoding. | Rendering tests for ordinary and unsafe input. Try `<script>alert(1)</script>` in the affected field. |
| **Broken access control** (IDOR, missing middleware, wrong roles) | The route handler: verify identity, ownership, and role on the server. **Don't rely on the frontend to hide links.** | Positive tests for allowed users and negative tests for other owners and restricted roles |

**Input validation can't reliably prevent these.** Fix the sink, the output, or the permission check.

## Objectives

- Filter Security → Code scanning alerts for your case (search `sql`, `xss`, or `authorization`)
- Pick one alert. Trace user input to the sink or output, or find the route that lacks a check
- Apply the fix from the table and test the affected behavior
- Open a pull request with the alert link and the tests above
- Get human review through the normal controls, then merge. Check that the default-branch rescan marks the alert fixed
- Explain the safe pattern in the PR. Checking similar paths is fine, but a second fix is optional

For access control, add this to the PR: **a clean scan doesn't prove business authorization rules work.** CodeQL covers only some cases, so the positive and negative tests must pass even when it has no matching rule.

> [!TIP]
> Working with a real application? Pick its own alert for your case.

## Copilot tips

- Highlight the vulnerable code and ask for a fix that uses the libraries already in the project. Example: *"Rewrite this query with parameterized queries compatible with the Sequelize ORM already in use here."*
- For XSS, ask: *"Which output context is this, and what encoding does it need?"*
- For access control, ask: *"Which of these endpoints lack authorization middleware, and how do I verify the requester owns this resource?"*
- Check any fix from Copilot Autofix or other Copilot help against the approved safe pattern. Submit it through the normal PR and GHAS checks.

If the team needs it, add repository instructions for the safe pattern.

## Learning resources

- [OWASP SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [Responsible use of AI features for security and code quality](https://docs.github.com/en/code-security/responsible-use/security-and-quality-ai-features)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
