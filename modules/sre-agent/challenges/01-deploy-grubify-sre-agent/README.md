# Activity 01: Deploy Grubify and Create the Azure SRE Agent

## Scenario

Now deploy the official Azure SRE Agent starter lab. This creates the monitored Grubify sample application and the Azure SRE Agent context needed for the rest of the track.

This activity is Azure-first. GitHub is optional at this stage; the primary outcome is that the SRE Agent can see Azure resources, observability data, incidents, and knowledge.

## Goals

- Deploy the Grubify starter lab or use an equivalent coach-provisioned environment.
- Locate the Azure SRE Agent in the SRE Agent portal.
- Identify the deployed Azure resources and observability stores.
- Capture the baseline healthy app URLs and resource names.
- Explain what the agent can investigate before source code is connected.

## Estimated Time

75 minutes.

> [!IMPORTANT]
> **Bring your own service (do this first)**
>
> This activity is most valuable when the Azure SRE Agent is connected to an Azure service or application your team will keep operating after the session. If you have a candidate workload in a subscription you control, point the SRE Agent at **that** service everywhere this guide references Grubify so the setup, telemetry, incidents, and context live in your tenant.
>
> - **Have a candidate?** Use an existing Azure service that is already deployed, observable, and approved for the agent to access. Confirm the agent has permission to read the resource group, logs, metrics, traces, alerts, and any knowledge sources you want it to use; skip deploying Grubify unless your coach asks for a parallel practice target.
> - **No suitable Azure service yet?** Deploy Grubify below as the safe fallback target for learning the workflow.
>
> Tell your coach which path you took — bringing your own is the goal; Grubify is the fallback.

## Deploy

From the official lab:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
bash scripts/setup.sh
```

When the setup script asks for a GitHub username, press **Enter** unless your coach has already provided a lab GitHub repository. Activity 01 does not require GitHub; skipping it still deploys Grubify, Azure Monitor, Log Analytics, Application Insights, knowledge files, and the Azure SRE Agent.

If your coach provides a GitHub repository for source-code scenarios, the current starter lab expects a repository named `grubify` under the owner you enter. For example, for `https://github.com/contoso-team-01/grubify`, enter `contoso-team-01`. Do not enter an email address, token, `@handle`, full repository URL, or the original sample owner.

If you prefer manual setup:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab

az login --use-device-code
azd auth login --use-device-code
az provider register -n Microsoft.App --wait

azd env new sre-lab
azd env set AZURE_LOCATION eastus2
azd up

bash scripts/post-provision.sh
```

For manual Activity 01 setup, leave `GITHUB_USER` unset unless your coach tells you to connect source code now.

Deployment can take several minutes. If deployment fails because of role, policy, region, or cost restrictions, switch to the coach fallback packet.

## Verify the Agent

Open the Azure SRE Agent portal:

```text
https://sre.azure.com
```

In **Full setup**, confirm the available cards:

| Card | Expected result |
| --- | --- |
| Azure resources | Resource group connected |
| Incidents | Azure Monitor connected |
| Knowledge sources | Runbook and architecture context available |
| Code | Optional at this stage |

## Capture Baseline Evidence

Record:

| Evidence | Value |
| --- | --- |
| Resource group | `<name>` |
| Azure region | `<region>` |
| Azure SRE Agent name | `<name>` |
| Grubify frontend URL | `<url>` |
| Grubify API URL | `<url>` |
| Log Analytics workspace | `<name>` |
| Application Insights resource | `<name>` |
| Azure Monitor alert rule | `<name>` |

Open the Grubify frontend and perform one healthy action. If your coach provides endpoint checks, run them and save the result.

## Ask the Agent

Start a new chat in Azure SRE Agent and ask:

```text
What Azure resources are connected to this Grubify lab, and what telemetry can you use during an incident?
```

Then ask:

```text
Summarize the Grubify app architecture and the HTTP error runbook you have available.
```

Treat the answers as orientation. You will validate investigation claims in later activities.

## Deliverables

- Healthy deployment evidence.
- Azure SRE Agent setup screenshot or note.
- Resource and telemetry inventory.
- Short note: what the agent can investigate now, and what it cannot yet know without source-code context.

## Success Criteria

- Grubify is deployed live or represented by fallback evidence.
- The Azure SRE Agent is visible and running.
- The team can identify the Azure Monitor, Log Analytics, and Application Insights pieces.
- The team captures enough baseline information to compare against a later incident.
