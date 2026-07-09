# Secure Secrets & Dependencies — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — if you searched your team's repos right now, what is the most likely hardcoded credential or critically vulnerable dependency you'd find, and how long do you think it has been sitting there unnoticed? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a real repo your team owns — does it have push protection and Dependabot alerts enabled today, and who is actually reviewing and acting on those alerts?
- If a hardcoded credential or a critically vulnerable package in that repo were exploited today, what system, customer data, or compliance boundary would be at risk — and what is the realistic recovery path?
- What one automation or workflow change could you put in place this week to ensure secrets and vulnerable packages are caught before they merge, not discovered months later?

## Facilitation objectives
- Reinforce that secrets belong in runtime configuration, not source control.
- Help students connect secret scanning and Dependabot as two complementary supply-chain/security hygiene workflows.
- Keep validation grounded in branch checks, push protection behavior, and application startup testing.

## Common student blockers
- Students may remove a hardcoded value without wiring a replacement environment variable; remind them to preserve app functionality.
- Some treat Dependabot alerts as just version bumps; ask them to read the advisory and explain the actual risk.
- Push protection behavior can surprise students; frame a block as useful feedback, not a failure.

## Facilitation hints
- Ask students to inventory where the secret is consumed before changing the code.
- Encourage documenting required environment variables in the PR or challenge notes.
- Have them review at least two high/critical advisories deeply enough to explain exploit impact.
- After the changes, make sure they can still start the app and exercise an auth-related path.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] No hardcoded secrets, passwords, or credentials remain in source code files
- [ ] Secrets replaced with environment variable references (process.env.VARIABLE_NAME)
- [ ] At least 2 high or critical Dependabot alerts reviewed and understood
- [ ] Pull request checks and security annotations reviewed for branch changes
- [ ] Secret scanning alerts relevant to changes addressed or explained
- [ ] Application still starts and authenticates correctly after secrets migration

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Alert triage | 25 | Separates secrets, dependency alerts, severity, exploitability, and ownership without conflating the workflows. |
| Secret remediation | 25 | Removes or rotates exposed material, documents exposure handling, and avoids committing replacement secrets. |
| Dependency remediation | 20 | Updates vulnerable packages safely and confirms the application still works. |
| Verification evidence | 15 | Confirms secret scanning, Dependabot, and PR checks reflect the remediation. |
| Grounding conversation | 15 | Connects alert fatigue, ownership, and response SLA to a real repo. |
