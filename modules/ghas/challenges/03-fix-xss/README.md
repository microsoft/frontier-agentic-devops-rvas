# Activity S03 — Fix XSS & Unsafe Output

## Description

Cross-site scripting (XSS) happens when your application takes user-controlled data and includes it in an HTML response without encoding it. The browser can't tell the difference between your markup and the attacker's injected script — it runs both. The result: session hijacking, credential theft, malicious redirects.

Juice Shop has XSS vulnerabilities in its frontend and backend. Some are reflected (input immediately echoed back in the response), some are stored (input saved to the database and rendered to other users later). CodeQL has flagged locations where user data flows into HTML output unsanitized. Your job is to find those code paths and add the encoding layer that stops the injection, then record the validated remediation and how to prevent it in future changes.

The fix pattern is usually: encode output before rendering it, or use framework APIs that handle this automatically. The tricky part is understanding *which* context the data ends up in — HTML body, attribute, JavaScript, URL — because each requires a different encoding strategy.

## Objectives

- Filter Security → Code scanning alerts for XSS-related alerts
- Open the affected files and trace the data flow: where does user input enter, and where does it reach HTML output?
- Apply context-appropriate output encoding or safe framework APIs, and technically validate the affected rendering behavior
- Identify whether each vulnerability is reflected or stored, and explain the difference in your PR description
- Open pull requests to `main` with the exploitable data flow, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes to confirm the pattern, then check comparable rendering paths for repeat issues

> [!IMPORTANT]
> Bring your own application (do this first)
>
> This activity is most valuable when the XSS fixes *outlive the delivery session*. Use the real application repository you want to secure so the CodeQL data-flow findings, pull requests, and output-encoding changes land where your team can keep them.
>
> - Have a candidate? If you have an application repo in an organization you control with GHAS enabled, use it everywhere this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice-Shop-specific setup and pick real reflected or stored XSS findings, unsafe HTML rendering, or equivalent output-encoding alerts from your own repo instead of the Juice Shop examples.
> - No suitable one? Use the fallback from S00: OWASP Juice Shop as a safe practice target for fixing known XSS flaws.
>
> Tell your coach which path you took — bringing your own is the goal; Juice Shop is the fallback.
>

## Success Criteria

- [ ] A technically validated XSS fix uses context-appropriate output encoding or a safe framework API — not input filtering alone — confirms the application renders expected content, and retains PR/review evidence plus relevant GHAS validation.
- [ ] A reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md` states the unsafe pattern/finding class, approved safe pattern, where it applies, PR/review evidence, relevant GHAS validation, named owner, and how the expectation applies to human- and agent-authored changes.
- [ ] Completion requires two independently reviewed fixes, a technically validated fix, and a reusable prevention pattern record; two fixes alone are not sufficient.
- [ ] Any Copilot Autofix or other Copilot assistance is treated as proposed work, reviewed by a human, and handled through existing PR and GHAS controls.
- [ ] Coach conversation — which pages or components in your own application render user-supplied content back into the browser, and do you know for certain what encoding is applied before each one hits the DOM? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Highlight the vulnerable code and ask: *"This renders user input into HTML without encoding. What's the correct Angular/Node.js safe output API to use here?"*
- Ask: *"What's the difference between reflected and stored XSS, and which does this code path represent?"*
- Ask: *"What encoding is needed for data going into an HTML attribute versus HTML body versus a JavaScript string?"*
- If you use Copilot Autofix or other Copilot assistance, treat its output as a proposed remediation: review it against the required output context and submit it through the normal PR and GHAS checks.

Try this: Open the running app, trigger the XSS manually (try `<script>alert(1)</script>` in a search or input field), then fix the code and verify the same input is now safely rendered as text.

## Learning Resources

- [OWASP: Cross-Site Scripting (XSS)](https://owasp.org/www-community/attacks/xss/)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [About Copilot Autofix](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-autofix-for-codeql-code-scanning)
- [Angular Security: Preventing XSS](https://angular.io/guide/security#preventing-cross-site-scripting-xss)
