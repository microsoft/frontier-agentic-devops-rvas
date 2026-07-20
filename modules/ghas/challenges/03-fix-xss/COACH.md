# Fix XSS & Unsafe Output — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team's `README.md`.

## Required coach check-in

Required coach check-in: before completion, ask the delivery team member to connect the work to a service and review practice they own.

Their question: Coach conversation — which pages or components in your own application render user-supplied content back into the browser, and do you know for certain what encoding is applied before each one hits the DOM? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific page or component in your application that displays user-generated content — comments, names, messages, search terms — and describe what you actually know about the encoding applied before rendering.
- If a stored XSS payload were planted in that component today, what could an attacker harvest from your users — session tokens, credentials, actions performed on their behalf?
- What one change could you make next week to audit or harden the highest-risk rendering path in your codebase — a code review, a CSP header, switching to a safe framework API?

## Facilitation objectives
- Reinforce that XSS fixes depend on output context, not generic sanitization slogans.
- Help delivery team members trace full source-to-sink data flows across frontend and backend code.
- Keep delivery team members validating that the UI still behaves normally after secure rendering changes.
- Facilitate a reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md`, including its named owner and the expectation for human- and agent-authored changes.
- Identify the reviewers and review practice that will catch unsafe output handling in comparable rendering changes.

## Common delivery team member blockers
- Delivery team members often stop at the alert location without understanding where the data originates; ask them to trace both ends of the flow.
- Some try input filtering alone; remind them the preferred fix is safe rendering or context-appropriate encoding.
- Security fixes can accidentally break page rendering; have them test the affected UI path after each change.
- Copilot Autofix or assistance may be helpful but incomplete; coach the team to treat it as proposed work and review it through existing PR and GHAS controls.

## Facilitation hints
- Ask whether the unsafe sink is HTML body, attribute, URL, or script context before suggesting a fix.
- Encourage delivery team members to use framework defaults where possible instead of hand-rolling escaping logic.
- Have them describe reflected versus stored XSS in their own words before they open the PR.
- If the CodeQL annotation persists, check whether another nearby sink is still unencoded.
- Ask who reviews future rendering changes, where the prevention record applies, and how the owner will keep that expectation visible for human- and agent-authored changes.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] A technically validated XSS fix uses context-appropriate output encoding or a safe framework API — not input filtering alone — confirms the application renders expected content, and retains PR/review evidence plus relevant GHAS validation.
- [ ] A reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md` states the unsafe pattern/finding class, approved safe pattern, where it applies, PR/review evidence, relevant GHAS validation, named owner, and how the expectation applies to human- and agent-authored changes.
- [ ] Completion requires two independently reviewed fixes, a technically validated fix, and a reusable prevention pattern record; two fixes alone are not sufficient.
- [ ] Any Copilot Autofix or other Copilot assistance is treated as proposed work, reviewed by a human, and handled through existing PR and GHAS controls.

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Vulnerable flow identified | 20 | Explains where untrusted data reaches HTML, Markdown, or client-side rendering. |
| Correct remediation | 30 | Uses context-appropriate escaping, sanitization, or safe rendering primitives without breaking legitimate output. |
| Preventing repeat issues | 20 | Uses two fixes to confirm the pattern, checks adjacent rendering paths, and identifies the reviewers who will catch the pattern in future changes. |
| Evidence and governance record | 15 | Retains PR/review and relevant GHAS validation, and completes the shared prevention pattern record with an owner and human-/agent-authored expectation. |
| Coach check-in | 15 | Connects XSS risk and its prevention ownership to a real user-facing surface and review path. |
