# Fix Injection Vulnerabilities — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team's `README.md`.

## Required coach check-in

Required coach check-in: before completion, ask the delivery team member to connect the work to a service and review practice they own.

Their question: Coach conversation — where in your own codebase is user-controlled input most likely reaching a database query without parameterization, and what data could an attacker extract or modify if they found that path before your team did? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific API endpoint or query in your own codebase where dynamic data flows into a database call — how confident are you that it uses parameterization, and when did you last verify it?
- If a SQL or NoSQL injection were exploited in that endpoint today, what data would be exposed, which users would be affected, and how broadly would the incident affect the service?
- What would you do this week to verify that every dynamic query in that service uses a safe pattern — a code search, a CodeQL scan, a PR checklist item?

## Facilitation objectives
- Reinforce that the remediation must match the execution sink: parameterized queries and ORM-safe patterns for database operations, and APIs or designs that keep data separate from command or template interpretation for other sinks.
- Help delivery team members distinguish between attacker-controlled input, query construction, and execution sinks.
- Keep attention on technically validating the branch-level CodeQL results after the code change, not just editing until the app runs.
- Facilitate a reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md`, including its named owner and the expectation for human- and agent-authored changes.
- Identify the reviewers and review practice that will catch the unsafe query pattern in comparable changes.

## Common delivery team member blockers
- Delivery team members may try input sanitization or regex filtering first; explain that validation can enforce an input policy but does not reliably prevent injection, then redirect them to the safe pattern for the relevant execution sink.
- A team may fix one file but miss a parallel vulnerable path; ask them to search for the same unsafe query pattern elsewhere.
- Copilot Autofix or assistance may be helpful but incomplete; coach the team to treat it as proposed work and review it through existing PR and GHAS controls.

## Facilitation hints
- Ask delivery team members to point to the exact line where user input crosses into query construction.
- Encourage a small PR per fix if they are getting lost in multiple vulnerability paths.
- Have them explain how the chosen API keeps data separate from code at execution time.
- Remind them to inspect PR annotations after the scan completes, even if the local change looks correct.
- Ask who reviews future query changes, where the prevention record applies, and how the owner will keep that expectation visible for human- and agent-authored changes.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] A technically validated injection fix uses a safe pattern for its execution sink — parameterized queries or an ORM-safe alternative for database operations, or APIs/designs that keep data separate from command or template interpretation for other sinks — not input sanitization alone; confirms expected behavior, and retains PR/review evidence plus relevant GHAS validation.
- [ ] A reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md` states the unsafe pattern/finding class, approved safe pattern, where it applies, PR/review evidence, relevant GHAS validation, named owner, and how the expectation applies to human- and agent-authored changes.
- [ ] Completion requires two independently reviewed fixes, a technically validated fix, and a reusable prevention pattern record; two fixes alone are not sufficient.
- [ ] Any Copilot Autofix or other Copilot assistance is treated as proposed work, reviewed by a human, and handled through existing PR and GHAS controls.

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Vulnerable flow identified | 20 | Points to the attacker-controlled input, query construction, and unsafe sink for each fixed alert. |
| Correct remediation | 30 | Uses a safe pattern for the execution sink, such as parameterized queries or ORM-safe APIs for database operations; does not rely on regex filtering or superficial sanitization. |
| Preventing repeat issues | 20 | Uses two fixes to confirm the pattern, checks other occurrences, and identifies the reviewers who will catch the pattern in future changes. |
| Evidence and governance record | 15 | Retains PR/review and relevant GHAS validation, and completes the shared prevention pattern record with an owner and human-/agent-authored expectation. |
| Coach check-in | 15 | Connects injection risk and its prevention ownership to a real service, data type, and verification action. |
