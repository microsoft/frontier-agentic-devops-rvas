# Coach Guide: Activity 01 — Deploy Grubify and Create the Azure SRE Agent

## Expected Outcome

Teams deploy or inspect the official Grubify starter lab and can identify the Azure SRE Agent, app resources, observability stores, alerting path, and baseline healthy evidence.

## Coach Prep

Have the official lab ready:

- `microsoft/sre-agent/labs/starter-lab`
- `bash scripts/setup.sh` or a pre-provisioned equivalent
- Azure SRE Agent portal access
- Frontend/API URLs
- Resource group name
- Fallback screenshots for Full setup cards

## Strong Evidence

- Azure SRE Agent is visible in `https://sre.azure.com`.
- Teams can name Log Analytics, Application Insights, Azure Monitor, and Container Apps resources.
- Teams capture baseline Grubify health before breaking it.
- Teams can state what the agent knows before GitHub/source-code connection.

## Common Gaps

- Participants assume GitHub PR remediation is already available.
- Teams skip baseline evidence and go straight to breaking the app.
- Teams cannot find the agent portal or Full setup status.
- Teams confuse agent telemetry with app telemetry.

## Coach Hints

Ask:

- What evidence would prove the app was healthy before the incident?
- Which telemetry source would you expect the agent to query first?
- What does the agent not know yet without source code?

## Final Demo Pattern

Each team should show the agent in the portal, the Grubify endpoint, the resource inventory, and a short baseline note.
