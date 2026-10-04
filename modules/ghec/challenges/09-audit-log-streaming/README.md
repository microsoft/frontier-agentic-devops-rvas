# Ch09: Organization audit investigation and export

This optional session exports organization audit events for a selected period. It does not configure enterprise streaming.

**Session outcome:** You export organization audit events for a selected period as valid JSON and find the known test events.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud. The org audit log is a GHEC organization feature.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch09 --org <org>` (least-privilege; for this activity: `admin:org` + `read:audit_log` + `repo`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- You do not need GHAS or Codespaces.

## What you will deliver
- Read the organization audit log and understand its event model (actor, action, timestamp, repo).
- Use the audit-log search syntax (`action:`, `actor:`, `created:`, `repo:`) to answer real investigative questions.
- Query the audit log via the REST API (`gh api /orgs/<org>/audit-log`) with phrase filters and pagination.
- Generate and find documented permission and ruleset events.
- Build a small export script that pulls a time-bounded slice of the audit log to JSON for offline analysis.
- Keep this organization's API export separate from enterprise streaming evidence.

## Scenario
A GHEC customer's security team needs to identify who changed a setting and when. Generate a controlled set of administrative actions, then find them in the organization audit log using search filters and the API. Write a repeatable export script for later investigations.

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
- A seeded repo `ghec-ch09-audit-target` with a populated `main` for auditable test actions.
- A starter team `ghec-ch09-auditors` so team-membership and permission-change events have somewhere to land.
- A printed "recent activity" sample (the last few org audit events pulled from the API) so you can see the shape of an event immediately.
- A printed Next steps block telling you where to start.

## Tasks

### Part A: Read the log and establish the event model
1. Open the org audit log at Org Settings → Archive → Logs → Audit log. The "Logs" item is under Archive in the settings sidebar. Skim recent events; note each row's actor, action (e.g., `repo.create`, `org.update_member`), time, and affected object.
2. Pull the same data from the API: `gh api /orgs/<org>/audit-log --jq '.[] | {action, actor, created_at, repo}'` (most-recent first). Compare it to the UI.
3. Choose one real question, such as who changed repository access. Identify its documented audit action and the actor, time, and resource fields needed to answer it.

### Part B: Generate a known event set
4. Reuse a known approved change when it supplies the needed event. Otherwise perform **one** approved test action against the disposable `ghec-ch09-audit-target`, then restore the original setting:
   - Add the team to the repo: `gh api -X PUT /orgs/<org>/teams/ghec-ch09-auditors/repos/<org>/ghec-ch09-audit-target -f permission=push`.
   - Change repo visibility once and back, or toggle a setting.
   - Create (and delete) a simple repository ruleset on the target.
5. Record what you did (action + rough timestamp) so you can later confirm each one surfaced in the log.

### Part C: Use search filters
6. Filter by the action you chose. For a team grant, use `action:team.add_repository`. Confirm the known event appears.
7. Set the run date once: run `RUN_DATE=$(date -u +%F)` and use the resulting ISO `YYYY-MM-DD` value in the UI filters below.
8. Filter by actor + time: `actor:<your-login> created:<RUN_DATE>`, replacing `<RUN_DATE>` with the value you set in the previous step.
9. Filter by repo: `repo:<org>/ghec-ch09-audit-target` to scope everything to the target.
10. Combine filters to answer a specific question, e.g., "every ruleset change on the target today": `repo:<org>/ghec-ch09-audit-target action:repository_ruleset created:>=<RUN_DATE>`, replacing `<RUN_DATE>` with the value you set above.

### Part D: Audit log via the REST API
11. Phrase-query the API with the same filters: `gh api -X GET /orgs/<org>/audit-log -f phrase='action:team.add_repository' --jq '.[] | {actor, created_at, repo}'`.
12. Time-bound a query: `gh api -X GET /orgs/<org>/audit-log -f phrase="created:>=$RUN_DATE" --jq 'length'` to count the current run's events.
13. Handle pagination: add `--paginate` and confirm you can pull more than one page when the slice is large.
14. Find each supported Part B audit event through the API and record its query. Check the documented event list before treating an absent event as an export failure.

### Part E: Build an export pipeline
15. Export an approved time slice as one valid JSON array:
    ```bash
    gh api --method GET --paginate --slurp /orgs/<org>/audit-log \
      -f phrase="created:>=$RUN_DATE" --jq 'add' > audit-export.json
    jq 'length' audit-export.json
    ```
    Keep raw events in the approved restricted evidence store, not a public repository.
16. Run it and confirm the output contains your generated events. You can schedule this org-scoped API export. Record it separately from enterprise-level streaming.
17. Answer the selected question in the existing investigation issue. Include the exact filter and relevant event. Save the repeatable export command in the team's runbook with its approved storage location and retention owner.

### Part F: Inspect the effective audit settings (enterprise vs. organization)

18. Verify the organization audit-log access and retention used by the export.
    Record this org-level implementation separately from the enterprise-level
    decision.
19. Link any existing enterprise streaming evidence separately. If none is available, record that limitation and finish the organization export.

## Reference links
- [Reviewing the audit log for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)
- [Audit log events for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/audit-log-events-for-your-organization)
- [Searching the audit log (search syntax)](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#searching-the-audit-log)
- [Using the audit log API for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#using-the-audit-log-api)
- [Organization audit log REST API](https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/orgs#get-the-audit-log-for-an-organization)
- [Streaming the audit log for your enterprise (awareness)](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/streaming-the-audit-log-for-your-enterprise)
