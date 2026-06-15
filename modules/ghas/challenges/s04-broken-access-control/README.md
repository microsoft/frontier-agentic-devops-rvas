# Challenge S-03: Fix Broken Access Control

## Description

Broken access control is OWASP's number one web application vulnerability. It occurs when the application fails to enforce that users can only act within their intended permissions. The result: users can read other users' data, modify records they shouldn't own, access admin functionality without authorization, or escalate their own privileges.

Juice Shop has multiple access control flaws. Some are insecure direct object references (IDOR) — where the app trusts a user-supplied ID to look up data without checking if that user actually owns it. Others are missing authorization middleware — routes that should require authentication or admin role but don't check. CodeQL flags some of these; others you'll find by reading the routes and thinking about who should and shouldn't be able to call each endpoint.

The fix pattern: for every operation that touches user-owned or role-restricted data, verify the requesting user's identity and permissions *in the route handler*. Don't rely on the frontend to hide links.

## Objectives

- Review code scanning alerts related to authorization and access control
- Open the backend `routes/` directory and identify at least 2 endpoints with missing or inadequate authorization checks
- Trace the auth middleware: which routes use it, which ones don't, and which ones use it but still allow unintended access?
- Fix at least 2 access control vulnerabilities — add ownership checks, role enforcement, or correct middleware application
- Open a pull request to `main` with a description that explains who could have exploited the flaw and what they could have accessed
- Review the PR CodeQL/code scanning check and annotations for any remaining access control findings

## Success Criteria

- [ ] At least 2 access control vulnerabilities identified and fixed in route handlers
- [ ] Fixes enforce authorization server-side, not just through UI restrictions
- [ ] PR descriptions explain the access control gap and the enforcement logic added
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns where applicable
- [ ] Application still handles legitimate requests correctly after fixes

## Copilot Tips

- Open a route file and ask: *"Which of these endpoints are missing authorization middleware? What should each one require?"*
- Ask: *"This endpoint uses a user ID from the request body to look up data. How can I verify the requesting user actually owns this resource?"*
- Ask: *"What's the difference between authentication and authorization, and where does this code handle each?"*

## Learning Resources

- [OWASP: Broken Access Control](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)
- [OWASP IDOR Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html)
- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
