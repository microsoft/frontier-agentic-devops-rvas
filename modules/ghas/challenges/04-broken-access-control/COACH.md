# Fix Broken Access Control — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team's `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the delivery team member to connect the work to a service and review practice they own.

**Their question:** Coach conversation — in your own backend services, are there routes that rely on the frontend to hide restricted actions instead of enforcing ownership server-side, and how would you even know if an authenticated user were calling them directly with a crafted request? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific backend route or endpoint in your system — what ownership or role check happens in the handler itself, not in the UI, a frontend guard, or a client-side permission flag?
- If an authenticated but unauthorized user called that endpoint directly with a crafted request today, what resource or operation could they access, modify, or delete?
- What single server-side check would you add next week to close the most obvious authorization gap in that service — and how would you test that it actually blocks the unauthorized path?

## Facilitation objectives
- Reinforce that authorization must be enforced server-side on every sensitive route.
- Help delivery team members recognize both missing middleware and flawed ownership checks as access control bugs.
- Keep focus on preserving legitimate user flows while closing unauthorized ones.
- Facilitate a reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md`, including its named owner and the expectation for human- and agent-authored changes.
- Identify the reviewers and recurrence control that will catch missing ownership or role enforcement in comparable routes.

## Common delivery team member blockers
- Delivery team members may assume a hidden button or frontend route guard is enough; redirect them to backend enforcement.
- They may add authentication without authorization; ask who is allowed to access the specific record or action.
- When multiple middleware layers exist, delivery team members can lose track of where checks happen; have them trace request flow end to end.
- Copilot Autofix or assistance may be helpful but incomplete; coach the team to treat it as proposed work and review it through existing PR and GHAS controls.

## Facilitation hints
- Ask delivery team members which user identity the route trusts and where that identity is validated.
- Encourage explicit ownership or role checks close to the data access path.
- Have them test one authorized and one unauthorized request path after the fix.
- If CodeQL flags remain, review whether a helper route or alternate endpoint still bypasses checks.
- Ask who reviews future route changes, where the prevention record applies, and how the owner will keep that expectation visible for human- and agent-authored changes.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] A technically validated access-control fix enforces server-side ownership or role authorization — not UI restrictions alone — confirms authorized access works and unauthorized access is blocked, and retains PR/review evidence plus relevant GHAS validation.
- [ ] A reusable prevention pattern record in `modules/ghas/resources/ghas-governance-practice.template.md` states the unsafe pattern/finding class, approved safe pattern, where it applies, PR/review evidence, relevant GHAS validation, named owner, and how the expectation applies to human- and agent-authored changes.
- [ ] Two independently reviewed fixes are used as a practical evidence threshold; completion depends on both the technically validated fix and the reusable prevention pattern record, not the count alone.
- [ ] Any Copilot Autofix or other Copilot assistance is treated as proposed work, reviewed by a human, and handled through existing PR and GHAS controls.

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Authorization boundary | 25 | Identifies the protected object or action and who should be allowed to access it. |
| Server-side enforcement | 30 | Implements backend authorization checks rather than relying on hidden UI or client routing. |
| Recurrence controls | 20 | Uses two fixes as practical evidence, checks comparable endpoints, and identifies the reviewers who will catch the pattern in future changes. |
| Evidence and governance record | 10 | Retains PR/review and relevant GHAS validation, and completes the shared prevention pattern record with an owner and human-/agent-authored expectation. |
| Grounding conversation | 15 | Connects the pattern and its prevention ownership to a real service, role model, or data boundary. |
