# Activity 01: Connect a service to Azure SRE Agent

**Session outcome:** Grubify or your approved service runs, and Azure SRE Agent can read its resources and telemetry. A service health check and an agent query verify the connection.

## Scenario

Deploy the official Grubify starter lab, or reuse the monitored customer service
selected for the engagement. Connect or repair its approved
resource and telemetry access, then verify what the agent can read.
If it is already connected, test the connection without redeploying.

Start with Azure; GitHub is optional. The SRE Agent must be able to read Azure resources, observability data, incidents, and knowledge.

## Goals

- Deploy the Grubify starter lab, or connect the selected customer service.
- Locate the Azure SRE Agent in the SRE Agent portal.
- Identify the deployed Azure resources and observability stores.
- Capture the baseline healthy app URLs and resource names.
- Explain what the agent can investigate before source code is connected.

> [!TIP]
> You can replace Grubify with a service your team operates.
> Skip all deployment commands for an existing service. Approve agent access
> to its resource group, logs, metrics, traces, alerts, and knowledge sources.

## Deploy Grubify

### Approve the service and check access

Choose the customer service and name its owner. Confirm the resource group, telemetry stores, and the agent's approved permissions. Use the same service throughout this track.

For an existing service, skip deployment. Confirm Azure SRE Agent can use its region and the owner can grant the intended resource and telemetry access.

For Grubify practice, obtain subscription and cost approval before deploying. Check the tools:

```bash
npm run setup:sre-agent
az version
azd version
git --version
python3 --version
```

Authenticate through the approved Azure process and check the subscription:

```bash
az login --use-device-code
azd auth login --use-device-code
az account show
```

The lab needs Owner or equivalent access to a pre-provisioned environment, `Microsoft.App` provider registration, and a supported region: `eastus2`, `swedencentral`, or `australiaeast`. Register the provider only with approval:

```bash
az provider register -n Microsoft.App --wait
```

If live access is unavailable, use the fallback packet and mark it **practice**. It cannot prove a live service connection. Sample deployment is also practice; customer completion requires the approved customer service.

### Deploy only when needed

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

Deployment can take several minutes. If a role, policy, region, or cost restriction
blocks it, use the fallback packet as practice. Do not claim a live connection.

## Verify the agent

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

## Capture baseline evidence

Record:

| Evidence | Value |
| --- | --- |
| Resource group | `<name>` |
| Azure region | `<region>` |
| Azure SRE Agent name | `<name>` |
| Grubify or customer service frontend URL, if relevant | `<url>` |
| Grubify or customer service API URL | `<url>` |
| Log Analytics workspace | `<name>` |
| Application Insights resource | `<name>` |
| Azure Monitor alert rule | `<name>` |

Open the Grubify frontend and perform one healthy action. For a customer service,
perform an approved action or endpoint check that should succeed. Save the result
with a timestamp and confirm that its telemetry appears in the connected store.

## Ask the agent

Start a new chat in Azure SRE Agent. If using your own service, replace Grubify in these prompts:

```text
What Azure resources are connected to this Grubify lab, and what telemetry can you use during an incident?
```

Then ask:

```text
Summarize the Grubify app architecture and the HTTP error runbook you have available.
```

Check the named resources and telemetry against the portal. A setup screenshot
alone does not prove that the agent can read service evidence.

## Deliverables

- Record the service owner, approved resource scope, and whether the work used a customer service, Grubify, or a fallback packet.
- Save the passing service health check and matching telemetry.
- Record the agent response that cites the connected service resources.
- Assign an owner to any connection gap. Label sample or packet results **practice**.
