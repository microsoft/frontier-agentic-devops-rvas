# Fix XSS & Unsafe Output — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — which pages or components in your own application render user-supplied content back into the browser, and do you know for certain what encoding is applied before each one hits the DOM? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific page or component in your application that displays user-generated content — comments, names, messages, search terms — and describe what you actually know about the encoding applied before rendering.
- If a stored XSS payload were planted in that component today, what could an attacker harvest from your users — session tokens, credentials, actions performed on their behalf?
- What one change could you make next week to audit or harden the highest-risk rendering path in your codebase — a code review, a CSP header, switching to a safe framework API?

## Facilitation objectives
- Reinforce that XSS fixes depend on output context, not generic sanitization slogans.
- Help students trace full source-to-sink data flows across frontend and backend code.
- Keep students validating that the UI still behaves normally after secure rendering changes.

## Common student blockers
- Students often stop at the alert location without understanding where the data originates; ask them to trace both ends of the flow.
- Some try input filtering alone; remind them the preferred fix is safe rendering or context-appropriate encoding.
- Security fixes can accidentally break page rendering; have them test the affected UI path after each change.

## Facilitation hints
- Ask whether the unsafe sink is HTML body, attribute, URL, or script context before suggesting a fix.
- Encourage students to use framework defaults where possible instead of hand-rolling escaping logic.
- Have them describe reflected versus stored XSS in their own words before they open the PR.
- If the CodeQL annotation persists, check whether another nearby sink is still unencoded.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] At least 2 XSS vulnerabilities fixed
- [ ] Fixes use output encoding or safe framework APIs — not input filtering alone
- [ ] PR descriptions explain the data flow: source (user input), sink (HTML output), and encoding applied
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns
- [ ] Application still renders correctly after the fixes

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Vulnerable flow identified | 20 | Explains where untrusted data reaches HTML, Markdown, or client-side rendering. |
| Correct remediation | 30 | Uses context-appropriate escaping, sanitization, or safe rendering primitives without breaking legitimate output. |
| Coverage | 20 | Fixes the required XSS paths and checks adjacent rendering paths for the same mistake. |
| Verification evidence | 15 | Demonstrates the malicious payload no longer executes and code scanning/PR checks agree. |
| Grounding conversation | 15 | Connects XSS risk to a real user-facing surface and ownership path. |
