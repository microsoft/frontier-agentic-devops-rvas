# Security Campaigns (Advanced) — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team member `README.md`.

## Required coach check-in

Required coach check-in: before completion, ask the customer practitioner to connect the exercise to work they actually own.

Their question: Coach conversation — if you had to pitch a security campaign for your own team's codebase today, which vulnerability class would you tackle first, how would you make the case to your engineering lead, and what would your definition of done actually be? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name the production codebase or repository you'd target — roughly how many open security alerts does it have today, and are they triaged by severity or just accumulating in a backlog?
- What is the realistic cost of leaving those alerts unaddressed — breach risk, compliance exposure, developer incident time — and who in your organization feels that cost most directly right now?
- Define a campaign scope narrow enough to complete in two weeks: which alert class, which repos, which team members, and what is the first concrete signal that it is actually done?

## Facilitation objectives
- Reinforce the shift from fixing one alert to planning remediation at vulnerability-class scale.
- Help customer delivery team members choose scope using risk, alert volume, and delivery capacity rather than intuition alone.
- Support both the real campaign path and the written-plan fallback when org permissions are limited.
- Establish an operating cadence that the customer can run after the session: triage, campaign review, escalation, risk acceptance, and leadership or risk reporting.
- Reinforce that a GitHub Security Campaign is useful implementation support, not a substitute for accountable decisions and follow-through.

## Common delivery team member blockers
- Customer delivery team members may choose a scope that is too broad to execute; prompt them to narrow by class, repo area, or severity.
- If org-level permissions are unavailable, customer delivery team members can feel blocked; remind them the written campaign plan is a valid advanced outcome.
- Some focus only on creating the campaign object and skip remediation strategy; ask who will do the work, by when, and how progress is tracked.
- Teams may leave accepted-risk items without a review path; require an accountable owner, rationale, and review or expiry date.

## Facilitation hints
- Ask customer delivery team members to justify why they would prioritize one alert class before another in production.
- Encourage realistic deadlines and ownership instead of aspirational, vague timelines.
- Have them define what counts as done: fixed, dismissed with reason, or deferred with risk acceptance.
- Use prior activity experience to estimate effort and identify which fixes are easy wins versus deep refactors.
- Complete the Operating Cadence section of `modules/ghas/resources/ghas-governance-practice.template.md`; do not allow real alerts, credentials, or customer-sensitive details in the template.
- Ask which measures are reviewed, who receives overdue-risk escalation, and how agent-authored changes are held to the same PR and GHAS evidence.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] Operating cadence documents participants, frequency, measures, escalation, and reporting path
- [ ] Campaign scope defined and justified with risk, business impact, volume, effort, and accountable ownership
- [ ] Option A: Security campaign created with name, due date, and at least 5 alerts scoped — progress tracked in the campaign view
- [ ] Option B (no org access): Shared governance practice covers scope, assignees, timeline, definition of done, and tracking approach
- [ ] Accepted-risk and overdue findings have an accountable owner, rationale, and review or expiry date
- [ ] Human- and agent-authored changes have the same accountable-owner, PR, and GHAS validation expectations

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Operating cadence | 25 | Defines participants, frequency, measures, escalation, reporting, and exception review that can continue after the session. |
| Campaign scope | 20 | Defines a focused alert class, affected repositories or owners, and the reason this set is worth campaigning. |
| Prioritization model | 20 | Uses severity, reachability, business impact, remediation effort, and accountable ownership to order work. |
| Execution and evidence | 20 | Produces owner-ready campaign or equivalent tracking, with measurable progress and remaining risk. |
| Coach check-in | 15 | Connects campaign design to a real organizational rollout path. |
