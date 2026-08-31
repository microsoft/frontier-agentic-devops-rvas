# Activity 01: Deploy Grubify and Create the Azure SRE Agent

## Scenario

Deploy the official Azure SRE Agent starter lab. It creates the monitored Grubify sample app and the agent context used later.

Start with Azure; GitHub is optional. The SRE Agent must be able to read Azure resources, observability data, incidents, and knowledge.

## Goals

- Deploy the Grubify starter lab or use an equivalent pre-provisioned environment.
- Locate the Azure SRE Agent in the SRE Agent portal.
- Identify the deployed Azure resources and observability stores.
- Capture the baseline healthy app URLs and resource names.
- Explain what the agent can investigate before source code is connected.

> [!TIP]
> **Bring your own service:** connect Azure SRE Agent to a service your team will operate after the session, wherever this guide references Grubify. It must be deployed, observable, and approved for agent access to the resource group, logs, metrics, traces, alerts, and knowledge sources.

## Deploy

From the official lab:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
bash scripts/setup.sh
```

When the setup script asks for a GitHub username, press Enter unless a lab GitHub repository has already been provided for you. Activity 01 does not require GitHub; skipping it still deploys Grubify, Azure Monitor, Log Analytics, Application Insights, knowledge files, and the Azure SRE Agent.

If a GitHub repository is provided for source-code scenarios, the current starter lab expects a repository named `grubify` under the owner you enter. For example, for `https://github.com/contoso-team-01/grubify`, enter `contoso-team-01`. Do not enter an email address, token, `@handle`, full repository URL, or the original sample owner.

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

For manual Activity 01 setup, leave `GITHUB_USER` unset unless you plan to connect source code now.

Deployment can take several minutes. If a role, policy, region, or cost restriction blocks it, use the fallback packet.

## Verify the Agent

Open the Azure SRE Agent portal:

```text
https://sre.azure.com
```

In Full setup, confirm the available cards:

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

Open the Grubify frontend and perform one healthy action. If endpoint checks are provided, run them and save the result.

## Ask the Agent

Start a new chat in Azure SRE Agent and ask:

```text
What Azure resources are connected to this Grubify lab, and what telemetry can you use during an incident?
```

Then ask:

```text
Summarize the Grubify app architecture and the HTTP error runbook you have available.
```

Use the answers for orientation. Validate any investigation claims later.

## Deliverables

- Healthy deployment evidence.
- Azure SRE Agent setup screenshot or note.
- Resource and telemetry inventory.
- Short note: what the agent can investigate now, and what it cannot yet know without source-code context.
