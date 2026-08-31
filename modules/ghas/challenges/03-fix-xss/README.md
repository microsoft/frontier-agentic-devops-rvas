# Activity S03: Fix XSS & Unsafe Output

## Description

Cross-site scripting (XSS) happens when an application includes user-controlled data in an HTML response without the right encoding. The browser treats the attacker's script as application markup and runs it. An attacker can hijack sessions, steal credentials, or redirect users.

Juice Shop has XSS vulnerabilities in its frontend and backend. Reflected XSS
returns input in the immediate response; stored XSS saves input and later renders
it to other users. CodeQL has flagged paths where user data reaches HTML output
without safe handling. Fix those paths and record the validated remediation and
prevention pattern.

Encode output before rendering it, or use framework APIs that do so safely. First identify the output context, such as an HTML body, attribute, JavaScript string, or URL. Each context needs a different encoding strategy.

## Objectives

- Filter Security → Code scanning alerts for XSS-related alerts
- Open the affected files and trace the data flow: where does user input enter, and where does it reach HTML output?
- Apply context-appropriate output encoding or safe framework APIs, and technically validate the affected rendering behavior
- Identify whether each vulnerability is reflected or stored, and explain the difference in your PR description
- Open pull requests to `main` with the exploitable data flow, remediation, reviewer evidence, and relevant GHAS validation
- Record the approved prevention pattern in `modules/ghas/resources/ghas-governance-practice.template.md`
- Use two independently reviewed fixes to confirm the pattern, then check comparable rendering paths for repeat issues

> [!IMPORTANT]
> Use your own application first
>
> - **Real application available:** Use it wherever this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice Shop setup and select real reflected or stored XSS findings, unsafe HTML rendering, or related output-encoding alerts so the fixes land in code your team maintains.
> - **No suitable application:** Use the S00 OWASP Juice Shop fallback to practice fixing known XSS flaws.
>

## Copilot Tips

- Highlight the vulnerable code and ask: *"This renders user input into HTML without encoding. What's the correct Angular/Node.js safe output API to use here?"*
- Ask: *"What's the difference between reflected and stored XSS, and which does this code path represent?"*
- Ask: *"What encoding is needed for data going into an HTML attribute versus HTML body versus a JavaScript string?"*
- If you use Copilot Autofix or other Copilot assistance, treat its output as a proposed remediation: review it against the required output context and submit it through the normal PR and GHAS checks.

Try triggering the XSS in the running app with `<script>alert(1)</script>` in a search or input field. Fix the code, then verify that the app renders the same input as text.

## Learning Resources

- [OWASP: Cross-Site Scripting (XSS)](https://owasp.org/www-community/attacks/xss/)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [About Copilot Autofix](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/about-autofix-for-codeql-code-scanning)
- [Angular Security: Preventing XSS](https://angular.io/guide/security#preventing-cross-site-scripting-xss)
