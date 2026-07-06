# Fix Broken Access Control — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — in your own backend services, are there routes that rely on the frontend to hide restricted actions instead of enforcing ownership server-side, and how would you even know if an authenticated user were calling them directly with a crafted request? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific backend route or endpoint in your system — what ownership or role check happens in the handler itself, not in the UI, a frontend guard, or a client-side permission flag?
- If an authenticated but unauthorized user called that endpoint directly with a crafted request today, what resource or operation could they access, modify, or delete?
- What single server-side check would you add next week to close the most obvious authorization gap in that service — and how would you test that it actually blocks the unauthorized path?

## Facilitation objectives
- Reinforce that authorization must be enforced server-side on every sensitive route.
- Help students recognize both missing middleware and flawed ownership checks as access control bugs.
- Keep focus on preserving legitimate user flows while closing unauthorized ones.

## Common student blockers
- Students may assume a hidden button or frontend route guard is enough; redirect them to backend enforcement.
- They may add authentication without authorization; ask who is allowed to access the specific record or action.
- When multiple middleware layers exist, students can lose track of where checks happen; have them trace request flow end to end.

## Facilitation hints
- Ask students which user identity the route trusts and where that identity is validated.
- Encourage explicit ownership or role checks close to the data access path.
- Have them test one authorized and one unauthorized request path after the fix.
- If CodeQL flags remain, review whether a helper route or alternate endpoint still bypasses checks.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] At least 2 access control vulnerabilities identified and fixed in route handlers
- [ ] Fixes enforce authorization server-side, not just through UI restrictions
- [ ] PR descriptions explain the access control gap and the enforcement logic added
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns where applicable
- [ ] Application still handles legitimate requests correctly after fixes

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Authorization boundary | 25 | Identifies the protected object or action and who should be allowed to access it. |
| Server-side enforcement | 30 | Implements backend authorization checks rather than relying on hidden UI or client routing. |
| Negative testing | 20 | Demonstrates unauthorized access is blocked while authorized access still works. |
| Verification evidence | 10 | Reviews PR checks, traces, or tests that prove the access-control rule is enforced. |
| Grounding conversation | 15 | Connects the pattern to a real service, role model, or data boundary. |

## Source
Derived from legacy GHAS delivery session source material, MIT license.
