# Activity S04: Fix Broken Access Control

## Description

Broken access control occurs when an application fails to enforce user permissions.
A user may read another user's data, modify records they do not own, access admin
functions, or raise their own privileges. It ranks first in the OWASP web
application vulnerability list.

Juice Shop has several access-control flaws. Some are insecure direct object references (IDOR), where the app trusts a user-supplied ID without checking ownership. Other routes omit required authorization middleware. CodeQL flags some cases. Find the rest by reading each route and deciding who may call it. Record the validated remediation and a prevention pattern for future changes.

For every operation on user-owned or role-restricted data, verify the requesting user's identity and permissions *in the route handler*. Do not rely on the frontend to hide links. Copilot Autofix or other Copilot assistance can propose a change. A human must review it through the existing PR and GHAS controls.

## Objectives

- Review code scanning alerts related to authorization and access control
- Open the backend `routes/` directory and identify at least 2 endpoints with missing or inadequate authorization checks
- Trace the auth middleware: which routes use it, which ones don't, and which ones use it but still allow unintended access?
- Add server-side ownership checks, role enforcement, or correct middleware application, and technically validate authorized and unauthorized request paths
- Open pull requests to `main` with the access-control gap, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes to confirm the pattern, then check comparable endpoints for repeat issues

> [!IMPORTANT]
> Use your own application first
>
> - **Real application available:** Use it wherever this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice Shop setup and select real authorization, IDOR, missing-middleware, or role-enforcement findings so the fixes land in code your team maintains.
> - **No suitable application:** Use the S00 OWASP Juice Shop fallback to practice finding and fixing broken access control.
>
> Tell your coach which path you chose.
>

## Success Criteria

- [ ] A technically validated access-control fix enforces server-side ownership or role authorization. UI restrictions alone do not meet this requirement. The fix confirms that authorized access works, blocks unauthorized access, and retains PR/review evidence plus relevant GHAS validation.
- [ ] A reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md` states the unsafe pattern/finding class, approved safe pattern, where it applies, PR/review evidence, relevant GHAS validation, named owner, and how the expectation applies to human- and agent-authored changes.
- [ ] Completion requires two independently reviewed fixes, a technically validated fix, and a reusable prevention pattern record; two fixes alone are not sufficient.
- [ ] Any Copilot Autofix or other Copilot assistance is treated as proposed work, reviewed by a human, and handled through existing PR and GHAS controls.
- [ ] Coach conversation: Find any backend routes that rely on the frontend to hide restricted actions instead of enforcing ownership on the server. Explain how you would detect an authenticated user calling them directly with a crafted request. Discuss a real project, task, or workflow with your coach.

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
