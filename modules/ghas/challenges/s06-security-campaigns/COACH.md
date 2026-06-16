# Security Campaigns (Advanced) — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — if you had to pitch a security campaign for your own team's codebase today, which vulnerability class would you tackle first, how would you make the case to your engineering lead, and what would your definition of done actually be? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Name the production codebase or repository you'd target — roughly how many open security alerts does it have today, and are they triaged by severity or just accumulating in a backlog?
- What is the realistic cost of leaving those alerts unaddressed — breach risk, compliance exposure, developer incident time — and who in your organization feels that cost most directly right now?
- Define a campaign scope narrow enough to complete in two weeks: which alert class, which repos, which team members, and what is the first concrete signal that it is actually done?

## Facilitation objectives
- Reinforce the shift from fixing one alert to planning remediation at vulnerability-class scale.
- Help students choose scope using risk, alert volume, and delivery capacity rather than intuition alone.
- Support both the real campaign path and the written-plan fallback when org permissions are limited.

## Common student blockers
- Students may choose a scope that is too broad to execute; prompt them to narrow by class, repo area, or severity.
- If org-level permissions are unavailable, students can feel blocked; remind them the written campaign plan is a valid advanced outcome.
- Some focus only on creating the campaign object and skip remediation strategy; ask who will do the work, by when, and how progress is tracked.

## Facilitation hints
- Ask students to justify why they would prioritize one alert class before another in production.
- Encourage realistic deadlines and ownership instead of aspirational, vague timelines.
- Have them define what counts as done: fixed, dismissed with reason, or deferred with risk acceptance.
- Use prior challenge experience to estimate effort and identify which fixes are easy wins versus deep refactors.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] Campaign scope defined and justified with rationale (risk, volume, effort)
- [ ] Option A: Security campaign created with name, due date, and at least 5 alerts scoped — progress tracked in the campaign view
- [ ] Option B (no org access): Written campaign plan covering scope, assignees, timeline, and definition of done
- [ ] Reflection written: what would you prioritize in a real production codebase, and why?

## Source
Derived from [microsoft/frontier-ghas-hackathon](https://github.com/microsoft/frontier-ghas-hackathon), MIT license.
