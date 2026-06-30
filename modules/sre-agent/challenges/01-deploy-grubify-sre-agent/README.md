# Challenge 01: Deploy Grubify and Create the Azure SRE Agent

## Scenario

Now deploy the official Azure SRE Agent starter lab. This creates the monitored Grubify sample application and the Azure SRE Agent context needed for the rest of the track.

This challenge is Azure-first. GitHub is optional at this stage; the primary outcome is that the SRE Agent can see Azure resources, observability data, incidents, and knowledge.

## Goals

- Deploy the Grubify starter lab or use an equivalent coach-provisioned environment.
- Locate the Azure SRE Agent in the SRE Agent portal.
- Identify the deployed Azure resources and observability stores.
- Capture the baseline healthy app URLs and resource names.
- Explain what the agent can investigate before source code is connected.

## Estimated Time

75 minutes.

## Deploy

From the official lab:

```bash
LAB_DIR="$(bash modules/sre-agent/resources/scripts/ensure-starter-lab.sh)"
cd "$LAB_DIR"
bash scripts/setup.sh
```

If you prefer manual setup:

```bash
LAB_DIR="$(bash modules/sre-agent/resources/scripts/ensure-starter-lab.sh)"
cd "$LAB_DIR"

az login --use-device-code
azd auth login --use-device-code
az provider register -n Microsoft.App --wait

azd env new sre-lab
azd env set AZURE_LOCATION eastus2
azd up

bash scripts/post-provision.sh
```

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

Treat the answers as orientation. You will validate investigation claims in later challenges.

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
