# Ch09 — Audit Log & Streaming

> By the end of this challenge you can investigate what happened in an organization using the **org audit log** UI, the **audit-log search syntax**, and the **audit-log REST API** — generating real events, querying them precisely, and building a lightweight "export" pipeline — all from an org and an org-owner token.

| | |
|---|---|
| **Track** | Admin/Governance |
| **Difficulty** | Advanced *(per-track ramp)* |
| **Duration** | ~4–5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | none |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud. The **org audit log** is a GHEC organization feature.
- A token with the scopes listed by `wth doctor ch09 --org <org>` (least-privilege; for this challenge: `admin:org` + `read:audit_log` + `repo`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `wth doctor` to verify).
- No GHAS or Codespaces required. **Enterprise audit-log streaming** is awareness-only here (see callout) — the real, gradable work uses the **org** audit log + API.

## Learning objectives
By completing this challenge you will:
- Read the **organization audit log** and understand its event model (actor, action, timestamp, repo).
- Use the **audit-log search syntax** (`action:`, `actor:`, `created:`, `repo:`) to answer real investigative questions.
- Query the audit log via the **REST API** (`gh api /orgs/<org>/audit-log`) with phrase filters and pagination.
- Generate a **known set of events** (repo create, permission change, label create, ruleset change) and then **find them** — proving the log captures admin actions.
- Build a small **export script** that pulls a time-bounded slice of the audit log to JSON for offline analysis.
- Understand where **enterprise-level audit-log streaming** fits (awareness) and why an org-scoped API pull is the org-owner equivalent.

## Scenario
A GHEC customer's security team asks the question every audit eventually asks: *"Who changed that setting, and when?"* Right now nobody can answer it without guessing. You'll learn to treat the **organization audit log** as the source of truth — generate a controlled set of administrative actions, then reconstruct exactly what happened using search filters and the API. You'll finish with a repeatable script that exports a slice of the log, the seed of a real evidence-collection pipeline.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch09 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh setup ch09 --org <org>
```
```powershell
# PowerShell
wth setup ch09 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 setup ch09 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch09-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`wth-ch09-audit-target`** with a populated `main` — a safe object to perform auditable actions against.
- A starter team **`wth-ch09-auditors`** so team-membership and permission-change events have somewhere to land.
- A printed **"recent activity" sample** (the last few org audit events pulled from the API) so you can see the shape of an event immediately.
- A printed **Next steps** block telling you where to start.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch09 --org <org> --yes` removes only `wth-ch09-*` artifacts. **The audit log itself is append-only and is never deleted** — see the Coach teardown note.

## Tasks

### Part A — Read the log & learn the event model
1. **Open the org audit log** (**Org Settings → Archive → Logs → Audit log** — the "Logs" item is under the **Archive** section of the settings sidebar). Skim recent events; note each row's **actor**, **action** (e.g., `repo.create`, `org.update_member`), **time**, and affected object.
2. **Pull the same data from the API:** `gh api /orgs/<org>/audit-log --jq '.[] | {action, actor, created_at, repo}'` (most-recent first). Compare it to the UI.
3. **Identify the action namespaces** you see (`org.*`, `repo.*`, `team.*`, `protected_branch.*`, `repository_ruleset.*`) and write a one-line description of three of them.

### Part B — Generate a known event set
4. **Create an auditable trail on purpose.** Perform each of these against `wth-ch09-audit-target` (or the org), pausing a moment between them:
   - Create a label: `gh label create "audit-marker" --repo <org>/wth-ch09-audit-target --color FFAA00`.
   - Add the team to the repo: `gh api -X PUT /orgs/<org>/teams/wth-ch09-auditors/repos/<org>/wth-ch09-audit-target -f permission=push`.
   - Change repo visibility once and back, or toggle a setting.
   - Create (and delete) a simple repository ruleset on the target.
5. **Record what you did** (action + rough timestamp) so you can later confirm each one surfaced in the log.

### Part C — Search syntax mastery
6. **Filter by action:** in the audit-log UI search box, run `action:team.add_repository` and confirm your Part B grant appears.
7. **Filter by actor + time:** `actor:<your-login> created:2026-06-01`. Adjust the date to today's run if different (ISO `YYYY-MM-DD`).
8. **Filter by repo:** `repo:<org>/wth-ch09-audit-target` to scope everything to the target.
9. **Combine filters** to answer a specific question, e.g., "every ruleset change on the target today": `repo:<org>/wth-ch09-audit-target action:repository_ruleset created:>=2026-06-01`.

### Part D — Audit log via the REST API
10. **Phrase-query the API** with the same filters: `gh api -X GET /orgs/<org>/audit-log -f phrase='action:team.add_repository' --jq '.[] | {actor, created_at, repo}'`.
11. **Time-bound a query:** `gh api -X GET /orgs/<org>/audit-log -f phrase='created:>=2026-06-01' --jq 'length'` to count today's events.
12. **Handle pagination:** add `--paginate` and confirm you can pull more than one page when the slice is large.
13. **Confirm every Part B action is findable** through the API — tie each generated event back to a query.

### Part E — Build an export pipeline
14. **Write an export script** (`export-audit.sh` or `.ps1`, committed to `wth-ch09-audit-target`) that pulls a time-bounded slice (`-f phrase='created:>=<date>'`, `--paginate`) and writes pretty JSON to a file.
15. **Run it** and confirm the output contains your generated events. This is the org-owner equivalent of "streaming" — a repeatable pull you could schedule.
16. **Write `FINDINGS.md`**: for three investigative questions (who added the team? who changed the ruleset? what happened today?), record the exact filter used and the answer.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] You can pull recent org audit events from the **API** (`gh api /orgs/<org>/audit-log` returns events with `action`/`actor`/`created_at`).
- [ ] A **known event set** was generated in Part B and **every** action is findable via search or API.
- [ ] At least **three distinct search filters** (`action:`, `actor:`, `repo:`, or `created:`) were used and produced correct results.
- [ ] A **combined, time-bounded API query** returns a sensible count for today's events.
- [ ] An **export script** committed to the repo pulls a time-bounded slice to JSON and the output contains your events.
- [ ] A **`FINDINGS.md`** answers three investigative questions with the exact filter used.
- [ ] Coach conversation — if your org's GitHub audit log were streaming to your SIEM right now, what is the first alert or anomaly query you would write, and what event from the past six months do you wish you had been alerted to? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Extend the export script to emit **CSV** (actor, action, created_at, repo) suitable for a spreadsheet or SIEM import.
- Query the **Git events** stream (`include=git` / `phrase='action:git.push'`) and discuss why Git events are higher-volume and time-limited.
- Diagram how you'd turn the export script into a **scheduled GitHub Actions workflow** that pulls yesterday's audit slice nightly and uploads it as an artifact.

> **At enterprise scale (awareness only):** An **enterprise account** can configure **audit log streaming** to push events continuously to an external sink (Amazon S3, Azure Blob Storage, Azure Event Hubs, Datadog, Google Cloud Storage, Splunk) with no polling. That's an **enterprise-owner** feature and is out of scope as a requirement here. The org-scoped equivalent you build in Part E — a repeatable, time-bounded API pull — captures the same data for a single org and is what an org owner uses today. Configuring streaming also can't be cleanly "torn down" by our scripts, which is another reason it stays awareness-only.

## Reference links
- Reviewing the audit log for your organization — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization
- Audit log events for your organization — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/audit-log-events-for-your-organization
- Searching the audit log (search syntax) — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#searching-the-audit-log
- Using the audit log API for your organization — https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#using-the-audit-log-api
- Organization audit log REST API — https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/orgs#get-the-audit-log-for-an-organization
- Streaming the audit log for your enterprise (awareness) — https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/streaming-the-audit-log-for-your-enterprise
