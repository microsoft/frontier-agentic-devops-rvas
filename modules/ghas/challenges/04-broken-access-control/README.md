# Activity S04: Fix Broken Access Control

## Description

Broken access control occurs when an application fails to enforce user permissions.
A user may read another user's data, modify records they do not own, access admin
functions, or raise their own privileges. It ranks first in the OWASP web
application vulnerability list.

Juice Shop has several access-control flaws. Some are insecure direct object references (IDOR), where the app trusts a user-supplied ID without checking ownership. Other routes omit required authorization middleware. CodeQL flags some cases. Find the rest by reading each route and deciding who may call it. Record the validated remediation and a prevention pattern for future changes.

For every operation on user-owned or role-restricted data, verify the requesting user's identity and permissions *in the route handler*. Do not rely on the frontend to hide links.

## Objectives

- Review code scanning alerts related to authorization and access control
- Open the backend `routes/` directory and identify at least 2 endpoints with missing or inadequate authorization checks
- Trace the auth middleware: which routes use it, which ones don't, and which ones use it but still allow unintended access?
- Add server-side ownership checks, role enforcement, or correct middleware application, and technically validate authorized and unauthorized request paths
- Open pull requests to `main` with the access-control gap, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes to confirm the pattern, then check comparable endpoints for repeat issues

> [!IMPORTANT]
> Use a real application if you have one; select real authorization, IDOR,
> missing-middleware, or role-enforcement findings instead of Juice Shop's. Otherwise
> use the S00 Juice Shop fallback.

## Copilot Tips

- Open a route file and ask: *"Which of these endpoints are missing authorization middleware? What should each one require?"*
- Ask: *"This endpoint uses a user ID from the request body to look up data. How can I verify the requesting user actually owns this resource?"*
- Ask: *"What's the difference between authentication and authorization, and where does this code handle each?"*
- If you use Copilot Autofix or other Copilot assistance, treat its output as a proposed remediation: review it against the required ownership or role rule and submit it through the normal PR and GHAS checks.

## Learning Resources

- [OWASP: Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP IDOR Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
