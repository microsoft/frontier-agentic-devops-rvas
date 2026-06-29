<!--
  CANONICAL COACH-GUIDE TEMPLATE — DO NOT EDIT IN PLACE.
  Copy into challenges/ch##-<slug>/COACH.md and fill every section.
  Keep these headings, in this order. This is the facilitator + grading view;
  it is NOT shown to students on the Pages site (Basher filters COACH.md out).
-->

# Ch## — <Challenge Title> — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Facilitation notes
- **Goal in one line:** <what mastery looks like.>
- **Where students get stuck:** <the 1–2 conceptual humps to watch for.>
- **How to unblock without giving the answer:** <nudge prompts.>
- **Org-scoped note:** this challenge runs with just an org + org-owner token; no enterprise owner needed.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| <Core outcome 1> | 40 | <evidence of mastery> |
| <Core outcome 2> | 30 | <…> |
| <Quality / correctness> | 20 | <…> |
| <Stretch / polish> | 10 | <optional goals attempted> |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / Actions over manual clicks):
```bash
# Example: confirm the seeded repo exists and is configured
gh repo view <org>/wth-ch##-<slug> --json name,visibility
# Example: confirm a security feature / alert / workflow run
gh api repos/<org>/wth-ch##-<slug>/<endpoint>
```
- <Hint 1 — exact command + expected result.>
- <Hint 2.>

## Common pitfalls
- <Pitfall 1 + the fix.>
- <Pitfall 2.>
- <Token-scope / policy gotcha if any.>

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch## --org <org> --yes      # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch## --org <org> --yes     # PowerShell
```
- Removes only `wth-ch##-*` artifacts (prefix-guarded).
- **Manual cleanup (if any):** <org/enterprise settings that scripts can't cleanly revert, e.g., audit stream config.>

## Time budget
- Setup + read: <~30 min>
- Core tasks: <~X hrs>
- Stretch: <~Y hrs>
- **Total facilitated:** <3–8 hrs across sessions.>
