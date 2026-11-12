# Activity S03: Fix XSS and unsafe output

**Session outcome:** You've merged a reviewed fix that handles output safely. Rendering tests and a default-branch rescan confirm it.

Start with the [remediation checklist](../../resources/start-remediation.md), then use this case for an XSS finding. The injection and authorization cases are alternatives.

## Description

Cross-site scripting (XSS) happens when an application puts user-controlled data in an HTML response without the right encoding. The browser runs the attacker's script as if it were part of the app. An attacker can hijack sessions, steal credentials, or redirect users.

Juice Shop has XSS vulnerabilities in its frontend and backend. Reflected XSS
returns input in the immediate response; stored XSS saves input and later renders
it to other users. CodeQL flags paths where user data reaches HTML output
without safe handling. Pick one path to fix, and record the verified change and
a prevention pattern.

Encode output before rendering it, or use framework APIs that do it safely. **First identify the output context:** HTML body, attribute, JavaScript string, or URL. Each needs different encoding.

## Objectives

- Filter Security → Code scanning alerts for XSS-related alerts
- Pick one alert and trace user input to its output context
- Apply output encoding for the context or use safe framework APIs. Test the affected rendering behavior.
- Decide whether each vulnerability is reflected or stored, and explain the difference in your PR description
- Open a pull request with the alert link and rendering tests for ordinary and unsafe input
- Get human review through the normal controls, then merge. Check that the default-branch rescan marks the alert fixed
- Explain the safe output pattern in the PR. Checking similar paths is fine, but a second fix is optional

> [!TIP]
> Working with a real application? Pick its own reflected or stored XSS and output-encoding alerts.

## Copilot tips

- Highlight the vulnerable code and ask: *"This renders user input into HTML without encoding. What's the correct Angular/Node.js safe output API to use here?"*
- Ask: *"What's the difference between reflected and stored XSS, and which does this code path represent?"*
- Ask: *"What encoding is needed for data going into an HTML attribute versus HTML body versus a JavaScript string?"*
- Check any fix from Copilot Autofix or other Copilot help against the required output context, and submit it through the normal PR and GHAS checks.

In the approved test environment, try `<script>alert(1)</script>` in the affected field. Fix the code, then check that it renders safely for that output context.

## Learning resources

- [OWASP: Cross-Site Scripting (XSS)](https://owasp.org/www-community/attacks/xss/)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [Responsible use of AI features for security and code quality](https://docs.github.com/en/code-security/responsible-use/security-and-quality-ai-features)
- [Angular Security: Preventing XSS](https://angular.io/guide/security#preventing-cross-site-scripting-xss)
