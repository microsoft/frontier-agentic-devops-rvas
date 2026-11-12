# Ch09: Organization audit investigation and export

This optional session doesn't set up enterprise streaming.

**Session outcome:** You export organization audit events for a time period as valid JSON and find the known test events.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud. The org audit log is a GHEC feature.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch09 --org <org>` (least privilege; here: `admin:org` + `read:audit_log` + `repo`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS or Codespaces needed.

## What you will deliver
- Read organization audit events: actor, action, timestamp, and repository.
- Answer real investigative questions with the audit-log search syntax (`action:`, `actor:`, `created:`, `repo:`).
- Query the audit log through the REST API (`gh api /orgs/<org>/audit-log`) with phrase filters and pagination.
- Generate and find documented permission and ruleset events.
- Write a small export script that saves a time slice of the audit log as JSON for offline analysis.
- Keep this organization's API export separate from enterprise streaming evidence.

## Scenario
A GHEC customer's security team needs to identify who changed a setting and when. Generate a few known administrative actions, then find them in the organization audit log with search filters and the API. Write an export script you can rerun for later investigations.

> [!IMPORTANT]
> Use a customer audit question or repository where you can safely generate known events, if you have one: use it wherever this guide says `ghec-ch09-audit-target` and skip Setup. Otherwise test with the seeded repo and auditors team below, then apply the export to the customer organisation.
>
> Record the target, the operations owner, and the next action.

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
- A starter team `ghec-ch09-auditors` for team-membership and permission-change test events.
- A sample of recent org audit events from the API.

## Tasks

### Part A: Read the log and learn the event model
1. Open the org audit log at Org Settings → Archive → Logs → Audit log. "Logs" is under Archive in the settings sidebar. Skim recent events and note each row's actor, action (e.g., `repo.create`, `org.update_member`), time, and affected object.
2. Pull the same data from the API: `gh api /orgs/<org>/audit-log --jq '.[] | {action, actor, created_at, repo}'` (most-recent first). Compare it to the UI.
3. Pick one real question, such as who changed repository access. Find its documented audit action and the actor, time, and resource fields that answer it.

### Part B: Generate a known event set
4. Reuse an approved change that already produced the event you need. Otherwise do **one** approved test action on the disposable `ghec-ch09-audit-target`, then restore the original setting:
   - Add the team to the repo: `gh api -X PUT /orgs/<org>/teams/ghec-ch09-auditors/repos/<org>/ghec-ch09-audit-target -f permission=push`.
   - Change repo visibility once and back, or toggle a setting.
   - Create (and delete) a simple repository ruleset on the target.
5. Record the action and roughly when you did it, so you can find it in the log.

### Part C: Use search filters
6. Filter by the action you chose. For a team grant, use `action:team.add_repository`. Confirm the known event appears.
7. Set the run date once with `RUN_DATE=$(date -u +%F)`. Use the resulting `YYYY-MM-DD` value in the UI filters below.
8. Filter by actor + time: `actor:<your-login> created:<RUN_DATE>`, replacing `<RUN_DATE>` with the value from the previous step.
9. Filter by repo: `repo:<org>/ghec-ch09-audit-target` to limit results to the target.
10. Combine filters to answer a specific question, e.g., "every ruleset change on the target today": `repo:<org>/ghec-ch09-audit-target action:repository_ruleset created:>=<RUN_DATE>`, replacing `<RUN_DATE>` with the value you set above.

### Part D: Audit log via the REST API
11. Query the API with the same phrase filters: `gh api -X GET /orgs/<org>/audit-log -f phrase='action:team.add_repository' --jq '.[] | {actor, created_at, repo}'`.
12. Time-bound a query: `gh api -X GET /orgs/<org>/audit-log -f phrase="created:>=$RUN_DATE" --jq 'length'` to count the current run's events.
13. Paginate: add `--paginate` and confirm you get more than one page when the slice is large.
14. Find each Part B event through the API and record its query. Before you treat a missing event as an export failure, check that the event is in the documented list.

### Part E: Build an export pipeline
15. Export an approved time slice as one valid JSON array:
    ```bash
    gh api --method GET --paginate --slurp /orgs/<org>/audit-log \
      -f phrase="created:>=$RUN_DATE" --jq 'add' > audit-export.json
    jq 'length' audit-export.json
    ```
    Keep raw events in the approved restricted evidence store, never in a public repository.
16. Run it and confirm the output has your generated events. You can schedule this org-scoped export. Record it separately from enterprise-level streaming.
17. Answer your question in the existing investigation issue, with the exact filter and the relevant event. Save the export command in the team's runbook, with its approved storage location and retention owner.

### Part F: Check the audit settings (enterprise vs. organization)

18. Check the organization audit-log access and retention that the export uses. Record this org-level setup separately from the enterprise-level decision.
19. Link any existing enterprise streaming evidence separately. If you have none, record that gap and finish the organization export.

## Reference links
- [Reviewing the audit log for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)
- [Audit log events for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/audit-log-events-for-your-organization)
- [Searching the audit log (search syntax)](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#searching-the-audit-log)
- [Using the audit log API for your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization#using-the-audit-log-api)
- [Organization audit log REST API](https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/orgs#get-the-audit-log-for-an-organization)
- [Streaming the audit log for your enterprise (awareness)](https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise/reviewing-audit-logs-for-your-enterprise/streaming-the-audit-log-for-your-enterprise)
