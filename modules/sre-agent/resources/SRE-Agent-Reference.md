# Azure SRE Agent Reference

This note gives curriculum maintainers a source-backed baseline for the rebuilt Azure SRE Agent track.

## Official Microsoft Lab to Use

Use the official Microsoft repository:

- `microsoft/sre-agent`
- `labs/starter-lab`

The starter lab deploys an Azure SRE Agent connected to the Grubify sample app. It includes Azure Container Apps, Log Analytics, Application Insights, Azure Monitor alerts, managed identity/RBAC, knowledge files, response plans, and optional GitHub connection.

The lab scenarios are the right foundation for this course:

| Scenario | Why it fits |
| --- | --- |
| Break app -> agent investigates logs and remediates | Shows Azure SRE Agent as an operations assistant without requiring GitHub. |
| Source-code RCA and issue creation | Shows code context after Azure evidence is established. |
| Issue triage | Optional extension; not the core track. |

## What Azure SRE Agent Is

Azure SRE Agent is a reliability assistant for operations work. The official community repo describes it as a hub for Azure SRE Agent resources, labs, sample environments, prompt guides, issue reporting, product docs, portal links, pricing, official plugins, discussions, and videos.

For this track, Azure SRE Agent is the main product. GitHub is a supporting remediation target, not the primary learning objective.

## Source-Code Connection

The source-code connection documentation says a connected GitHub or Azure DevOps repository can let Azure SRE Agent:

- analyze source during investigations;
- return file and line references for suspected problems;
- create To-Do investigation plans;
- correlate production symptoms to code changes;
- create pull requests when repository connection, run mode, permissions, and branch state allow it.

The course should not require live PR creation in every environment. The baseline should be a source-aware investigation and a governed remediation issue or reviewed PR packet.

## Recipes and Plugins

`microsoft/sre-agent/sreagent-templates` includes production-oriented recipes. The most relevant simple recipe is `azmon-lawappinsights`, which connects Azure Monitor, Log Analytics, and Application Insights.

`Azure/sre-agent-plugins` is the official plugin repository. Plugins should be introduced as extension points, not required setup.

## Delivery Caveats

Live behavior depends on tenant policy, role assignments, region, connector availability, product access, and run mode. Coaches should always prepare a fallback evidence packet with the same learning shape: signal, Azure evidence, agent transcript, source lead, remediation work, recovery proof, and follow-up.

## Primary Sources

- [microsoft/sre-agent](https://github.com/microsoft/sre-agent)
- [microsoft/sre-agent starter lab](https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab)
- [microsoft/sre-agent recipes](https://github.com/microsoft/sre-agent/tree/main/sreagent-templates)
- [Azure/sre-agent-plugins](https://github.com/Azure/sre-agent-plugins)
- [Connect source code in Azure SRE Agent](https://learn.microsoft.com/en-us/azure/sre-agent/connect-source-code)
