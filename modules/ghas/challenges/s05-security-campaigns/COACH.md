# Security Campaigns (Advanced) — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

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
