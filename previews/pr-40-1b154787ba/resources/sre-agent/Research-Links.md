# Research links

Use these Agentic DevSecOps references when writing activity guides and setup instructions.

## Azure SRE Agent

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [microsoft/sre-agent](https://github.com/microsoft/sre-agent) | Source for SRE Agent labs, sample environments, prompt guides, docs links, feedback, and community resources. | Official community hub. Good starting point for Activity 01 setup and Activity 04 investigation preparation. |
| [Azure/sre-agent-plugins](https://github.com/Azure/sre-agent-plugins) | Source for the plugin model. | Official plugin repo. Plugins live under `plugins/` and are registered in `.github/plugin/marketplace.json`. |
| [Connect source code in Azure SRE Agent](https://learn.microsoft.com/en-us/azure/sre-agent/connect-source-code) | Source for source-code connection behavior and prerequisites. | Covers GitHub and Azure DevOps repo connection, OAuth/PAT auth, investigation file:line references, To-Do Plans, symptom-to-code correlation, and PR creation caveats. |
| [Azure SRE Agent documentation](https://learn.microsoft.com/en-us/azure/sre-agent/) | Main product documentation entry point. | Use for setup and current product behavior close to delivery date. |

## GitHub Copilot agents

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [GitHub Copilot agents concepts](https://docs.github.com/en/copilot/concepts/agents) | Source for agent concepts across cloud agent, CLI, app, code review, memory, hooks, third-party coding agents, agent apps, skills, and enterprise management. | Optional background for Activity 05 source-remediation review; keep feature availability caveats in the customer delivery team guide. |
| [GitHub Copilot cloud agent concepts](https://docs.github.com/en/copilot/concepts/agents/cloud-agent) | Source for asynchronous coding-agent work. | Use for Activity 05, where an agent works on an issue and a human reviews the result. |
| [About GitHub Copilot code review](https://docs.github.com/en/copilot/concepts/agents/code-review) | Source for PR review behavior. | Use when explaining that agent-created changes still need human review. |

## Agentic SDLC methodology

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [The Agentic SDLC Handbook](https://danielmeppiel.github.io/agentic-sdlc-handbook/) | Explains responsibilities for humans, agents, and platform controls in Activities 03-05. | Daniel Meppiel's handbook is a living pre-release under CC BY-NC-ND 4.0. Summarize and attribute; do not copy long passages. |

## GitHub Agentic Workflows

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [GitHub Agentic Workflows](https://github.github.com/gh-aw/) | Background on Markdown-authored workflows compiled into guarded GitHub Actions automation. | Early-stage technology; treat as supervision-required background, not a required activity dependency. |

## GitHub Actions and delivery

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [GitHub Actions quickstart](https://docs.github.com/en/actions/get-started/quickstart) | Basic Actions workflow reference. | Optional reference for the local workflow templates; Activity 04 is an Azure incident investigation. |
| [GitHub Actions starter workflows](https://github.com/actions/starter-workflows) | Workflow examples. | Useful fallback when teams need a starting point for CI or deployment. |

## What The Hack format

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [microsoft/WhatTheHack](https://github.com/microsoft/WhatTheHack) | Reference for activity-based delivery sessions. | What The Hack activities state tasks and goals without step-by-step instructions. Organizers guide without giving direct answers. |
| [GitHub Copilot What The Hack](https://github.com/microsoft/WhatTheHack/tree/master/071-GitHubCopilot) | Reference for Copilot learning flow. | Optional background for Activity 05 source-remediation review. |

## Azure Operational Excellence

| Source | Use in curriculum | Notes |
| --- | --- | --- |
| [Azure Well-Architected: Operational excellence](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/) | Reliability and operations guidance for Activities 04 and 05. | Official guidance covers DevOps culture, development standards, observability, automation, safe deployments, operational tasks, and incident response. |
| [Design an incident response strategy](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/incident-response) | Incident response design reference. | Use to keep SRE response work tied to operational practice rather than tool demos. |
| [Design for observability](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/observability) | Observability reference. | Useful when defining the evidence packet for Activity 04. |
| [Use safe deployment practices](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/safe-deployments) | Deployment safety reference. | Supports Activity 01 deployment setup and Activity 05 remediation work with validation and approval; it is not an Activity 04 deployment exercise. |

## Check before delivery

- Re-check Azure SRE Agent and GitHub Copilot agent docs before delivery. Some features require preview access, specific run modes, supported regions, repository permissions, or tenant policy approval.
- Use a fallback packet when live access is blocked, but keep the same artifacts: signal, evidence, suspected cause, remediation path, and follow-up work item.
