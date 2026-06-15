# Fix XSS & Unsafe Output — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

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

## Source
Derived from [microsoft/frontier-ghas-hackathon](https://github.com/microsoft/frontier-ghas-hackathon), MIT license.
