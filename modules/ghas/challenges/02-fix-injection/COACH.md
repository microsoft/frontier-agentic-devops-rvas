# Fix Injection Vulnerabilities — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — where in your own codebase is user-controlled input most likely reaching a database query without parameterization, and what data could an attacker extract or modify if they found that path before your team did? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a specific API endpoint or query in your own codebase where dynamic data flows into a database call — how confident are you that it uses parameterization, and when did you last verify it?
- If a SQL or NoSQL injection were exploited in that endpoint today, what data would be exposed, which users would be affected, and what is the realistic blast radius?
- What would you do this week to verify that every dynamic query in that service uses a safe pattern — a code search, a CodeQL scan, a PR checklist item?

## Facilitation objectives
- Reinforce why parameterized queries and ORM-safe patterns are the real fix for injection flaws.
- Help students distinguish between attacker-controlled input, query construction, and execution sinks.
- Keep attention on verifying branch-level CodeQL results after the code change, not just editing until the app runs.

## Common student blockers
- Students may try input sanitization or regex filtering first; redirect them toward prepared statements or framework-supported parameter binding.
- Some students fix one file but miss a parallel vulnerable path; ask them to search for the same unsafe query pattern elsewhere.
- Autofix suggestions may be helpful but incomplete; coach them to review the patch, not accept it blindly.

## Facilitation hints
- Ask students to point to the exact line where user input crosses into query construction.
- Encourage a small PR per fix if they are getting lost in multiple vulnerability paths.
- Have them explain how the chosen API keeps data separate from code at execution time.
- Remind them to inspect PR annotations after the scan completes, even if the local change looks correct.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] At least 2 injection vulnerabilities fixed in the code
- [ ] Fixes use parameterized queries or equivalent safe patterns — not input sanitization alone
- [ ] Pull requests to main opened with clear descriptions of the vulnerability and remediation
- [ ] Copilot Autofix tried on at least one alert (click "Generate fix" in the Security tab)
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Vulnerable flow identified | 20 | Points to the attacker-controlled input, query construction, and unsafe sink for each fixed alert. |
| Correct remediation | 30 | Uses parameterized queries or equivalent safe APIs; does not rely on regex filtering or superficial sanitization. |
| Coverage | 20 | Fixes the required injection paths and checks for sibling instances of the same pattern. |
| Verification evidence | 15 | Reviews CodeQL/code scanning results on the PR and confirms the fixed patterns are no longer annotated. |
| Grounding conversation | 15 | Connects injection risk to a real service, data type, and verification action. |
