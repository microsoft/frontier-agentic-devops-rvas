# Fix Broken Access Control — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

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

## Source
Derived from [microsoft/frontier-ghas-hackathon](https://github.com/microsoft/frontier-ghas-hackathon), MIT license.
