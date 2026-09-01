# Ch09 — Audit Log & Streaming

> Deliver an organisation audit-evidence path using the audit-log UI, search syntax, REST API, and a repeatable export pipeline.

## Prerequisites
- Recommended: Ch52 (Enterprise Landing Zone & Organization Strategy) completed first — its settings register is the preferred source for the enterprise-level streaming/retention item in Part F; otherwise this activity's org-level export stands on its own.
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud. The org audit log is a GHEC organization feature.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch09 --org <org>` (least-privilege; for this activity: `admin:org` + `read:audit_log` + `repo`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS or Codespaces required. Enterprise audit-log streaming is inspected as evidence, not configured, in this activity — it can't be cleanly torn down by automation, so it stays out of hands-on scope; the hands-on, gradable work uses the org audit log + API.

## What you will deliver
- Read the organization audit log and understand its event model (actor, action, timestamp, repo).
- Use the audit-log search syntax (`action:`, `actor:`, `created:`, `repo:`) to answer real investigative questions.
- Query the audit log via the REST API (`gh api /orgs/<org>/audit-log`) with phrase filters and pagination.
- Generate a known set of events (repo create, permission change, label create, ruleset change) and then find them — proving the log captures admin actions.
- Build a small export script that pulls a time-bounded slice of the audit log to JSON for offline analysis.
- Distinguish enterprise-level audit-log streaming from this organization's API-pull export, and source the enterprise decision from Ch52's landing-zone register or an authorized enterprise export.

## Scenario
A GHEC customer's security team asks the question every audit eventually asks: *"Who changed that setting, and when?"* Right now nobody can answer it without guessing. Establish the organization audit log as the authoritative record: generate a controlled set of administrative actions, reconstruct what happened using search filters and the API, and retain a repeatable export script as the start of a real evidence-collection pipeline.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate audit question or repository where known events can be generated safely, use it everywhere this guide says `ghec-ch09-audit-target` and skip Setup. Otherwise use the fallback seeded repo and auditors team below, then move the validated export path to an approved customer organisation.
>
> Record the selected target, operations owner, and next action.

## Sample test repository or environment
Skip if you brought your own audit target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch09 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch09 --org <org>
```

Setup creates these resources (all names use the `ghec-ch09-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch09-audit-target` with a populated `main` — a safe object to perform auditable actions against.
- A starter team `ghec-ch09-auditors` so team-membership and permission-change events have somewhere to land.
- A printed "recent activity" sample (the last few org audit events pulled from the API) so you can see the shape of an event immediately.
- A printed Next steps block telling you where to start.

## Tasks

### Part A — Read the log and establish the event model
1. Open the org audit log (Org Settings → Archive → Logs → Audit log — the "Logs" item is under the Archive section of the settings sidebar). Skim recent events; note each row's actor, action (e.g., `repo.create`, `org.update_member`), time, and affected object.
2. Pull the same data from the API: `gh api /orgs/<org>/audit-log --jq '.[] | {action, actor, created_at, repo}'` (most-recent first). Compare it to the UI.
3. Identify the action namespaces you see (`org.*`, `repo.*`, `team.*`, `protected_branch.*`, `repository_ruleset.*`) and write a one-line description of three of them.

### Part B — Generate a known event set
4. Create an auditable trail on purpose. Perform each of these against `ghec-ch09-audit-target` (or the org), pausing a moment between them:
   - Create a label: `gh label create "audit-marker" --repo <org>/ghec-ch09-audit-target --color FFAA00`.
   - Add the team to the repo: `gh api -X PUT /orgs/<org>/teams/ghec-ch09-auditors/repos/<org>/ghec-ch09-audit-target -f permission=push`.
   - Change repo visibility once and back, or toggle a setting.
   - Create (and delete) a simple repository ruleset on the target.
5. Record what you did (action + rough timestamp) so you can later confirm each one surfaced in the log.

### Part C — Search syntax mastery
6. Filter by action: in the audit-log UI search box, run `action:team.add_repository` and confirm your Part B grant appears.
7. Set the run date once: run `RUN_DATE=$(date -u +%F)` and use the resulting ISO `YYYY-MM-DD` value in the UI filters below.
8. Filter by actor + time: `actor:<your-login> created:<RUN_DATE>`, replacing `<RUN_DATE>` with the value you set in the previous step.
9. Filter by repo: `repo:<org>/ghec-ch09-audit-target` to scope everything to the target.
10. Combine filters to answer a specific question, e.g., "every ruleset change on the target today": `repo:<org>/ghec-ch09-audit-target action:repository_ruleset created:>=<RUN_DATE>`, replacing `<RUN_DATE>` with the value you set above.

### Part D — Audit log via the REST API
11. Phrase-query the API with the same filters: `gh api -X GET /orgs/<org>/audit-log -f phrase='action:team.add_repository' --jq '.[] | {actor, created_at, repo}'`.
12. Time-bound a query: `gh api -X GET /orgs/<org>/audit-log -f phrase="created:>=$RUN_DATE" --jq 'length'` to count the current run's events.
13. Handle pagination: add `--paginate` and confirm you can pull more than one page when the slice is large.
14. Confirm every Part B action is findable through the API — tie each generated event back to a query.

### Part E — Build an export pipeline
15. Write an export script (`export-audit.sh` or `.ps1`, committed to `ghec-ch09-audit-target`) that pulls a time-bounded slice (`-f phrase='created:>=<date>'`, `--paginate`) and writes pretty JSON to a file.
16. Run it and confirm the output contains your generated events. This is a repeatable, org-scoped pull you could schedule — it is not enterprise-level streaming.
17. Write `FINDINGS.md`: for three investigative questions (who added the team? who changed the ruleset? what happened today?), record the exact filter used and the answer.

### Part F — Inspect the effective audit settings (enterprise vs. organization)

18. Verify the organization audit-log access and retention used by the export.
    This is the org-level implementation, not the enterprise-level decision —
    keep the two distinct in your notes.
19. Record the enterprise-level streaming destination, retention, and
    IP-address-display decision in `FINDINGS.md`: cite Ch52's landing-zone
    settings register entry, or an authorized enterprise export/inspection;
    if neither exists, record `enterprise policy not available / not
    applicable`. Don't infer enterprise-wide streaming or retention policy
    from this one organization's audit log, and complete the organization
    export work normally regardless.

## Reference links
- Reviewing the audit log for your organization — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization
- Audit log events for your organization — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/audit-log-events-for-your-organization
- Searching the audit log (search syntax) — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#searching-the-audit-log
- Using the audit log API for your organization — https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#using-the-audit-log-api
- Organization audit log REST API — https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/orgs#get-the-audit-log-for-an-organization
- Streaming the audit log for your enterprise (awareness) — https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/streaming-the-audit-log-for-your-enterprise
