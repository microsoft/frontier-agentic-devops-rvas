# Challenge S03 — Fix XSS & Unsafe Output

## Description

Cross-site scripting (XSS) happens when your application takes user-controlled data and includes it in an HTML response without encoding it. The browser can't tell the difference between your markup and the attacker's injected script — it runs both. The result: session hijacking, credential theft, malicious redirects.

Juice Shop has XSS vulnerabilities in its frontend and backend. Some are reflected (input immediately echoed back in the response), some are stored (input saved to the database and rendered to other users later). CodeQL has flagged locations where user data flows into HTML output unsanitized. Your job is to find those code paths and add the encoding layer that stops the injection.

The fix pattern is usually: encode output before rendering it, or use framework APIs that handle this automatically. The tricky part is understanding *which* context the data ends up in — HTML body, attribute, JavaScript, URL — because each requires a different encoding strategy.

## Objectives

- Filter **Security → Code scanning alerts** for XSS-related alerts
- Open the affected files and trace the data flow: where does user input enter, and where does it reach HTML output?
- Fix at least 2 XSS vulnerabilities by applying appropriate output encoding or switching to safe framework APIs
- Identify whether each vulnerability is reflected or stored, and explain the difference in your PR description
- Open pull requests to `main` with a description of the data flow that was exploitable and how the fix closes it
- Review the PR CodeQL/code scanning check and annotations for the changed files

## Success Criteria

- [ ] At least 2 XSS vulnerabilities fixed
- [ ] Fixes use output encoding or safe framework APIs — not input filtering alone
- [ ] PR descriptions explain the data flow: source (user input), sink (HTML output), and encoding applied
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns
- [ ] Application still renders correctly after the fixes
- [ ] Coach conversation — which pages or components in your own application render user-supplied content back into the browser, and do you know for certain what encoding is applied before each one hits the DOM? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Highlight the vulnerable code and ask: *"This renders user input into HTML without encoding. What's the correct Angular/Node.js safe output API to use here?"*
- Ask: *"What's the difference between reflected and stored XSS, and which does this code path represent?"*
- Ask: *"What encoding is needed for data going into an HTML attribute versus HTML body versus a JavaScript string?"*

**Power move:** Open the running app, trigger the XSS manually (try `<script>alert(1)</script>` in a search or input field), then fix the code and verify the same input is now safely rendered as text.

## Learning Resources

- [OWASP: Cross-Site Scripting (XSS)](https://owasp.org/www-community/attacks/xss/)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [About Copilot Autofix](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-autofix-for-codeql-code-scanning)
- [Angular Security: Preventing XSS](https://angular.io/guide/security#preventing-cross-site-scripting-xss)
