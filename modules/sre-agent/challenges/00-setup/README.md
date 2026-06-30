# Challenge 00: Prepare the Azure SRE Agent Lab

## Scenario

Your team is about to run an Azure SRE Agent lab using Microsoft's official Grubify starter environment. Before deploying anything, confirm that the tools, Azure access, region, and fallback path are ready.

The goal is not to build a custom app. The goal is to use a known Microsoft-provided sample so the rest of the track can focus on Azure SRE Agent behavior: observability, alert investigation, runbooks, source-code context, remediation, and recovery.

## Goals

- Understand the official `microsoft/sre-agent` starter lab.
- Confirm Azure CLI, Azure Developer CLI, Git, and Python prerequisites.
- Confirm Azure role and provider requirements.
- Select a supported Azure SRE Agent region.
- Decide whether your team will run the live lab or use coach-provided fallback evidence.

## Estimated Time

45 minutes.

## Official Lab Source

Use the Microsoft Azure SRE Agent repository:

```bash
LAB_DIR="$(bash modules/sre-agent/resources/scripts/ensure-starter-lab.sh)"
cd "$LAB_DIR"
```

The starter lab deploys:

| Component | Purpose |
| --- | --- |
| Azure SRE Agent | Investigates incidents and uses connected context |
| Grubify API and frontend | Sample food-ordering app to break and recover |
| Azure Container Apps | Runtime for the sample app |
| Log Analytics | Queryable logs for investigation |
| Application Insights | Request, exception, and trace context |
| Azure Monitor alert | Incident signal that can trigger agent investigation |
| Knowledge files and runbooks | Context the agent uses during response |

## Verify Prerequisites

Confirm the required tools:

```bash
az version
azd version
git --version
python3 --version || python --version
```

Sign in:

```bash
az login --use-device-code
azd auth login --use-device-code
az account show
```

Register the required resource provider:

```bash
az provider register -n Microsoft.App --wait
```

Confirm with your coach:

| Requirement | Needed for live lab |
| --- | --- |
| Azure subscription | Active subscription |
| Role | Owner, or a coach-provisioned environment |
| Region | `eastus2`, `swedencentral`, or `australiaeast` |
| Cost approval | Required before deployment |
| GitHub account | Optional for source-code and issue scenarios |

## Choose Your Path

| Path | Use when | You will do |
| --- | --- | --- |
| Live lab | Azure access is available | Deploy Grubify and Azure SRE Agent |
| Shared coach lab | A coach owns the Azure environment | Inspect shared resources and run guided prompts |
| Fallback packet | Azure access is blocked | Use prepared alerts, logs, screenshots, and source references |

Do not spend the workshop debugging subscription policy. If access is blocked, switch to the fallback packet and preserve the learning objective.

## Deliverables

- Selected path: live, shared coach lab, or fallback packet.
- Azure subscription, region, and resource group decision.
- Tool prerequisite check results.
- One note naming the Azure SRE Agent capabilities this track will exercise.

## Success Criteria

- The intended Azure subscription and region are known.
- Required tools are installed or a fallback path is selected.
- `Microsoft.App` is registered or registration is delegated to the coach.
- The team can explain what the Grubify starter lab deploys.
- No secrets, tokens, tenant details, or credentials are pasted into notes or prompts.
