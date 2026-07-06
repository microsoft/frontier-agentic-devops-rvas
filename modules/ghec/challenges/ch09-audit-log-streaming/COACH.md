# Ch09 — Audit Log & Streaming — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — if your org's GitHub audit log were streaming to your SIEM right now, what is the first alert or anomaly query you would write, and what event from the past six months do you wish you had been alerted to? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer students who ran this on a **real artifact they own** over the `ghec-ch09-audit-target` sample. If they used the sample, confirm they can name the actual repo, team, project, or workflow they'll apply this to and any blockers. The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- What SIEM or logging system does your team use today, and is GitHub activity visible in it?
- Walk me through an incident or a policy question in the last year where GitHub audit data would have answered it faster.
- What is the single jq/Splunk/Sentinel query you'd write first once the stream is live?

## Facilitation notes
- **Goal in one line:** the student treats the org audit log as a source of truth — generates a controlled event set, then reconstructs exactly what happened using search syntax and the API, finishing with a repeatable export.
- **Where students get stuck:**
  - **Audit events are eventually-consistent.** A generated action can take a short while to appear. If a search returns nothing immediately, wait and retry rather than assuming failure.
  - **Search syntax precision.** `action:team.add_repository` is exact; `action:team` is a prefix match. `created:` accepts ranges (`>=2026-06-01`). Students often guess action names — point them at the "audit log events" reference for the canonical list.
  - **API `phrase` vs UI search.** The REST API takes the *same* query in a `phrase` parameter. Once they see that, the UI and API click together.
  - **Git events are separate and time-limited.** `git.*` events need `include=git` and aren't retained as long — keep that for the stretch.
- **How to unblock without giving the answer:** ask "what exact `action:` string did the docs say a team-to-repo grant emits?" and "how would you scope a query to only today's events?" (→ `created:>=<today>`).
- **Org-scoped note:** runs with an org + org-owner token. `read:audit_log` (plus `admin:org`) is the scope that lets the API return audit events. **Enterprise streaming is awareness-only** — never required to pass.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Event model understanding (Part A) | 15 | Reads UI + API; describes actor/action/time/repo; names three action namespaces |
| Generated event set (Part B) | 20 | Label, team-grant, visibility/setting, ruleset events created and recorded |
| Search syntax (Part C) | 20 | ≥3 distinct filters used correctly (action/actor/repo/created); a combined query answers a real question |
| API querying (Part D) | 25 | Phrase queries match the UI; time-bounded count works; pagination handled; every Part B action found |
| Export pipeline (Part E) | 20 | Committed export script pulls a time-bounded JSON slice containing the events; `FINDINGS.md` answers three questions |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>

# Recent events exist and have the expected shape
gh api /orgs/$ORG/audit-log --jq '.[0] | {action, actor, created_at, repo}'

# The team-add event the student generated in Part B
gh api -X GET /orgs/$ORG/audit-log -f phrase='action:team.add_repository' \
  --jq '.[] | {actor, created_at, repo}'

# Today's events, counted (adjust date to the run date, ISO YYYY-MM-DD)
gh api -X GET /orgs/$ORG/audit-log -f phrase='created:>=2026-06-01' --jq 'length'

# Scope to the target repo
gh api -X GET /orgs/$ORG/audit-log -f phrase='repo:'"$ORG"'/ghec-ch09-audit-target' \
  --jq '.[] | {action, actor, created_at}'

# Pagination sanity (large slices)
gh api -X GET /orgs/$ORG/audit-log -f phrase='created:>=2026-06-01' --paginate --jq 'length'
```
- The fastest mastery signal is a **phrase query that returns the exact event** the student generated (e.g., `team.add_repository`) with the right actor and repo.
- For the export, open the committed JSON file and confirm it contains the generated actions — not just that the script ran.
- `FINDINGS.md` should show the **literal filter** used per question, so grading is just re-running it.

## Common pitfalls
- **Event lag.** Newly generated events may not appear for a short while — retry before declaring failure.
- **Guessed action names.** `team.add` ≠ `team.add_repository`. Send them to the events reference for exact strings.
- **Token missing `read:audit_log`.** The audit-log API returns 403 or an empty result. Fix: `gh auth refresh -s admin:org,read:audit_log,repo`.
- **Date format.** Use ISO `YYYY-MM-DD` in `created:` filters; relative phrases aren't supported.
- **Expecting Git push events by default.** They require `include=git` and have shorter retention — keep to the stretch goal.

## Useful references for coaching

- [Reviewing the audit log for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization), [Audit log events for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/audit-log-events-for-your-organization).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch09 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch09 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch09-*` artifacts (prefix-guarded): the `ghec-ch09-audit-target` repo and the `ghec-ch09-auditors` team.
- **Manual cleanup / cannot be reverted:** the **audit log is append-only** — the events the student generated in Part B are a permanent part of the org's history and are **not** (and cannot be) deleted by teardown. That's expected and correct; auditability is the point. If the student configured any **enterprise audit-log streaming** during the stretch/awareness discussion, that stream config must be removed by hand at the enterprise level — our scripts never touch it.

## Time budget
- Setup + read the log: ~30 min
- Part B (generate events): ~30 min
- Part C (search syntax): ~45 min
- Part D (API querying): ~1 hr
- Part E (export pipeline): ~1 hr
- Stretch: ~45 min
- **Total facilitated:** ~4–5 hrs across sessions.
