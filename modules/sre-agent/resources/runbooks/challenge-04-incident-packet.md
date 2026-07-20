# Activity 04 Incident Packet: Grubify Ordering Failure

## Situation

At `<timestamp>`, Azure Monitor detected elevated failures for the Grubify ordering flow. Customers can browse the frontend, but Add to Cart or the backing API call is failing.

## Starting Evidence

| Signal | Value |
| --- | --- |
| Service | `grubify` |
| Frontend | `<frontend URL>` |
| API | `<API URL>` |
| Affected action | Add to Cart / ordering flow |
| First detected | `<timestamp>` |
| Customer impact | Ordering attempts fail; browsing remains available |

## Azure Evidence

| Evidence | Value |
| --- | --- |
| Azure Monitor alert | `<alert name>` |
| Log Analytics query | `<query or excerpt>` |
| Application Insights exception | `<exception or trace excerpt>` |
| Container App state | `<revision/resource state>` |
| Runbook reference | `<knowledge file or runbook section>` |

## Azure SRE Agent Transcript

Provide a sanitized transcript or summary showing:

- evidence gathered;
- likely cause;
- alternative hypothesis;
- mitigation recommendation;
- validation plan.

## Source-Code Context

If source context is included:

| Candidate area | Evidence | Confidence |
| --- | --- | --- |
| `<file:line>` | `<why this source area is relevant>` | `<Low/Medium/High>` |

## Expected Participant Outcome

Teams should finish with:

- incident timeline;
- evidence-backed likely cause;
- alternative hypothesis;
- GitHub issue or reviewed PR packet;
- recovery proof;
- one monitoring, runbook, response-plan, source-context, hook, or approval-policy improvement.
