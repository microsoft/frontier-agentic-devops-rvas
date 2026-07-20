# Coach Guide: Activity 00 — Prepare the Azure SRE Agent Lab

## Expected Outcome

Teams confirm whether they can run the official Microsoft Azure SRE Agent starter lab live, use a shared coach environment, or switch to fallback evidence. They understand that the track is about Azure SRE Agent, not GitHub workflow setup.

## Coach Prep

Prepare one of these paths before delivery:

| Path | Coach needs |
| --- | --- |
| Live participant lab | Subscription, Owner role, supported region, cost approval |
| Shared coach lab | Pre-deployed Grubify + Azure SRE Agent, portal screenshots, URLs |
| Fallback packet | Alert, logs, App Insights excerpt, SRE Agent transcript, source references |

Supported regions in the official lab docs include `eastus2`, `swedencentral`, and `australiaeast`. Validate availability before the session.

## Validation Checkpoints

- Ask participants to explain what the starter lab deploys.
- Confirm they understand why Owner role may be required for RBAC assignments.
- Confirm they know when to stop troubleshooting Azure policy and use fallback evidence.
- Remind teams not to paste secrets, tenant IDs, tokens, or private incident details into notes.

## Common Gaps

- Treating this as a GitHub/Codespaces setup activity.
- Spending too long on subscription policy.
- Missing `Microsoft.App` provider registration.
- Not distinguishing live lab from fallback evidence.

## Coach Prompt

Ask: Which real Azure workload would benefit most from an SRE Agent, and what signal would you connect first?
