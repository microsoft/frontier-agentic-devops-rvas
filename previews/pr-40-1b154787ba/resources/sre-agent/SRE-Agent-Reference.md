# Azure SRE Agent reference

Use these sources to check product capabilities and plan the Azure SRE Agent lab.

## Official Microsoft lab

Use the official Microsoft repository:

- `microsoft/sre-agent`
- `labs/starter-lab`

The starter lab deploys an Azure SRE Agent connected to the Grubify sample app. It includes Azure Container Apps, Log Analytics, Application Insights, Azure Monitor alerts, managed identity/RBAC, knowledge files, response plans, and optional GitHub connection.

Use these lab scenarios in the course:

| Scenario | Why it fits |
| --- | --- |
| Break the app, then ask the agent to investigate logs and remediate | Uses Azure SRE Agent without requiring GitHub. |
| Analyze the root cause using source code and create an issue | Links Azure incident evidence to code. |
| Issue triage | Optional extension; not the core track. |

## What Azure SRE Agent does

Azure SRE Agent is a reliability assistant for operations work. Its official community repository links to labs, sample environments, prompt guides, issue reporting, product documentation, the portal, pricing, official plugins, discussions, and videos.

Azure SRE Agent is the main product in this track. GitHub supports remediation work.

## Source-code connection

With a connected GitHub or Azure DevOps repository, Azure SRE Agent can:

- analyze source during investigations;
- return file and line references for suspected problems;
- create To-Do investigation plans;
- correlate production symptoms to code changes;
- create pull requests when repository connection, run mode, permissions, and branch state allow it.

Do not require live pull request creation in every environment. Require a source-aware investigation and either a reviewed pull request packet or a remediation issue with evidence, validation, and human approval.

## Recipes and plugins

`microsoft/sre-agent/sreagent-templates` includes production-oriented recipes. The most relevant simple recipe is `azmon-lawappinsights`, which connects Azure Monitor, Log Analytics, and Application Insights.

`Azure/sre-agent-plugins` is the official plugin repository. Introduce plugins as optional additions.

## Access requirements

Live behavior depends on tenant policy, role assignments, region, connector availability, product access, and run mode. If access is blocked, use the fallback model in [Reference Architecture](Reference-Architecture.md).

## Primary sources

- [microsoft/sre-agent](https://github.com/microsoft/sre-agent)
- [microsoft/sre-agent starter lab](https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab)
- [microsoft/sre-agent recipes](https://github.com/microsoft/sre-agent/tree/main/sreagent-templates)
- [Azure/sre-agent-plugins](https://github.com/Azure/sre-agent-plugins)
- [Connect source code in Azure SRE Agent](https://learn.microsoft.com/en-us/azure/sre-agent/connect-source-code)
