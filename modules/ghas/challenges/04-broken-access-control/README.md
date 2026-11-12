# Activity S04: Fix broken access control

**Session outcome:** You've merged a reviewed fix that enforces server-side authorization. Positive and negative tests confirm the permission rule. A rescan covers the findings the scanner supports.

Start with the [remediation checklist](../../resources/start-remediation.md), then use this case for an authorization finding. You don't need to do the injection and XSS cases too.

## Description

Broken access control means the application fails to enforce user permissions.
A user can read another user's data, change records they don't own, reach admin
functions, or raise their own privileges. It ranks first in the OWASP web
application vulnerability list.

Juice Shop has several access-control flaws. Some are insecure direct object references (IDOR), where the app trusts a user-supplied ID without checking ownership. Other routes omit required authorization middleware. CodeQL flags some cases. For your endpoint, read the code and decide who may call it. Record the verified fix and a prevention pattern for future changes.

For every operation on user-owned or role-restricted data, verify the requesting user's identity and permissions *in the route handler*. **Don't rely on the frontend to hide links.**

## Objectives

- Review code scanning alerts related to authorization and access control
- Pick one endpoint with a missing or inadequate authorization check
- Trace the auth middleware: which routes use it, which ones don't, and which ones use it but still allow unintended access?
- Add server-side ownership checks, enforce roles, or apply the correct middleware. Test authorized and unauthorized request paths.
- Open a pull request with the finding and positive tests for allowed users. Add negative tests for unauthorized users, including other owners and restricted roles relevant to the endpoint
- Get human review through the normal controls, then merge. Rerun CodeQL on the default branch and check any linked alert
- Explain the scanner's limits in the PR. A clean scan doesn't prove business authorization rules work. The positive and negative tests must pass even when CodeQL has no matching rule
- Explain the permission rule in the PR. Checking similar endpoints is fine, but a second fix is optional

> [!TIP]
> Working with a real application? Pick its own authorization, IDOR, missing-middleware, or role-enforcement findings.

## Copilot tips

- Open a route file and ask: *"Which of these endpoints are missing authorization middleware? What should each one require?"*
- Ask: *"This endpoint uses a user ID from the request body to look up data. How can I verify the requesting user actually owns this resource?"*
- Ask: *"What's the difference between authentication and authorization, and where does this code handle each?"*
- Check any fix from Copilot Autofix or other Copilot help against the required ownership or role rule, and submit it through the normal PR and GHAS checks.

## Learning resources

- [OWASP: Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP IDOR Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
