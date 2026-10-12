# Activity 04 incident packet: Grubify ordering failure

## Situation

At `<timestamp>`, Azure Monitor detected increased failures in the Grubify ordering flow.
Customers can browse the frontend, but Add to Cart or its API call fails.

## Starting evidence

| Signal | Value |
| --- | --- |
| Service | `grubify` |
| Frontend | `<frontend URL>` |
| API | `<API URL>` |
| Affected action | Add to Cart / ordering flow |
| First detected | `<timestamp>` |
| Customer impact | Ordering attempts fail; browsing remains available |

## Azure evidence

| Evidence | Value |
| --- | --- |
| Azure Monitor alert | `<alert name>` |
| Log Analytics query | `<query or excerpt>` |
| Application Insights exception | `<exception or trace excerpt>` |
| Container App state | `<revision/resource state>` |
| Runbook reference | `<knowledge file or runbook section>` |

## Azure SRE Agent transcript

Provide a sanitized transcript or summary with:

- evidence gathered;
- likely cause;
- alternative hypothesis;
- mitigation recommendation;
- validation plan.

## Source-code context

If source context is included:

| Candidate area | Evidence | Confidence |
| --- | --- | --- |
| `<file:line>` | `<why this source area is relevant>` | `<Low/Medium/High>` |

## Expected participant outcome

Teams produce:

- incident timeline;
- evidence-backed likely cause;
- alternative hypothesis;
- GitHub issue or reviewed PR packet;
- recovery proof;
- one monitoring, runbook, response-plan, source-context, hook, or approval-policy improvement.
