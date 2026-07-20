# Secure Secrets & Dependencies — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team member `README.md`.

## Required coach check-in

**Required coach check-in:** before completion, ask the customer practitioner to connect the exercise to work they actually own.

**Their question:** Coach conversation — if you searched your team's repos right now, what is the most likely hardcoded credential or critically vulnerable dependency you'd find, and how long do you think it has been sitting there unnoticed? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name a real repo your team owns — does it have push protection and Dependabot alerts enabled today, and who is actually reviewing and acting on those alerts?
- If a hardcoded credential or a critically vulnerable package in that repo were exploited today, what system, customer data, or compliance boundary would be at risk — and what is the realistic recovery path?
- What one automation or workflow change could you put in place this week to ensure secrets and vulnerable packages are caught before they merge, not discovered months later?

## Facilitation objectives
- Reinforce that secrets belong in runtime configuration, not source control.
- Help customer delivery team members connect secret scanning and Dependabot as two complementary processes for securing dependencies and credentials.
- Keep validation grounded in branch checks, push protection behavior, and application startup testing.
- Require an exposure response decision, accountable owner, and expiry for every exception recorded in the shared governance practice.
- Reinforce that agent-authored changes do not receive a weaker path around push protection, review, or human accountability.

## Common delivery team member blockers
- Customer delivery team members may remove a hardcoded value without wiring a replacement environment variable; remind them to preserve app functionality.
- Some treat Dependabot alerts as just version bumps; ask them to read the advisory and explain the actual risk.
- Push protection behavior can surprise customer delivery team members; frame a block as useful feedback, not a failure.
- Customer delivery team members can mistake deleting a value for resolving an exposure; ask whether the credential must be revoked or rotated and who owns that action.

## Facilitation hints
- Ask customer delivery team members to inventory where the secret is consumed before changing the code.
- Encourage documenting required environment variables in the PR or activity notes.
- Have them review at least two high/critical advisories deeply enough to explain exploit impact.
- After the changes, make sure they can still start the app and exercise an auth-related path.
- Have them complete the **Secret and Dependency Response** section of `modules/ghas/resources/ghas-governance-practice.template.md` without copying secrets, alert payloads, or sensitive customer data into it.
- Ask who can approve an exception, when it expires, and how that decision appears in the team's next triage review.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] Exposed secret removed from the affected path; revocation or rotation assessed and recorded
- [ ] Replacement configuration uses environment variable references (process.env.VARIABLE_NAME)
- [ ] At least 2 high or critical Dependabot alerts reviewed and understood
- [ ] Pull request checks and security annotations reviewed for branch changes
- [ ] Secret scanning alerts relevant to changes addressed or explained
- [ ] Application still starts and authenticates correctly after secrets migration
- [ ] Shared governance practice records an accountable owner, remediation route, and time-bound exception where applicable
- [ ] Agent-authored changes follow the same push-protection, PR, and accountable-owner expectations

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Alert triage | 25 | Separates secrets, dependency alerts, severity, exploitability, and ownership without conflating the workflows. |
| Secret remediation | 25 | Removes the affected value, assesses revocation or rotation, documents exposure handling, and avoids committing replacement secrets. |
| Dependency remediation | 20 | Updates vulnerable packages safely and confirms the application still works. |
| Governance evidence | 15 | Records ownership, remediation route, exception expiry, and the same guardrails for human- and agent-authored changes. |
| Verification evidence | 10 | Confirms secret scanning, Dependabot, and PR checks reflect the remediation. |
| Coach check-in | 10 | Connects a high volume of alerts, ownership, and a response time target to a real repo. |
