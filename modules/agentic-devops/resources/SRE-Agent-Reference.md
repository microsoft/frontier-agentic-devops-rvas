# Azure SRE Agent Reference

This note gives the curriculum team a source-backed baseline for Challenge 6 and related coach material. It is intentionally practical: what the tool is for, what source-code context adds, how plugins fit, and how this hackathon should use those ideas without overpromising product behavior.

## What Azure SRE Agent Is

Azure SRE Agent is a reliability assistant for operations work. The official community repo describes it as a place for Azure SRE Agent resources, labs, sample environments, prompt guides, issue reporting, and links to the product docs, portal, pricing, official plugins, discussions, and videos.

For this hackathon, treat Azure SRE Agent as the operations side of the agentic DevOps loop. Earlier challenges ask teams to plan, code, review, deploy, and validate a change. Challenge 6 asks what happens after that change is running: which signals matter, what evidence should be gathered, what likely cause can be defended, and what follow-up work should become an issue or pull request.

## Source-Code Connection

The Microsoft Learn source-code connection guide says a connected GitHub or Azure DevOps repository lets the agent use source code during investigations. The documented outcomes include:

- analyzing source during investigations;
- returning file and line references for suspected problems;
- creating To-Do Plans that show investigation steps;
- correlating production symptoms to code changes;
- creating pull requests from chat when repository connection, Review or Autonomous run mode, and an existing source branch with committed changes are in place.

Authentication can use OAuth or a Personal Access Token. Repository selection can come from a dropdown, and teams can also type a repository URL directly when the repo is not listed. The docs also describe an MCP plus custom agent option when the team needs broader GitHub API access, such as searching code, reading files, or listing commits across repositories.

The curriculum should not require live pull-request creation in every customer environment. A safer baseline is: connect source where access allows it, then ask participants to produce an investigation summary that includes the suspected code area, the operational symptom, and the change or follow-up they would open.

## Plugin Model

The official plugin repo, `Azure/sre-agent-plugins`, states that its plugins are designed for Azure SRE Agent and may not work with other coding agents. Plugins live under `plugins/`, and new plugins are registered by adding entries to `.github/plugin/marketplace.json`.

For the hackathon, plugins should be framed as extension points rather than required setup. Coaches can explain that plugins let the agent work with additional operational systems or domain-specific tools, but Challenge 6 should still work as a packet-based exercise when tenant policy, licensing, or access prevents live plugin use.

## How This Hackathon Uses SRE Agent Practices

Challenge 6 should use Azure SRE Agent practices to close the loop from delivery to operations:

- Start from a realistic production signal, such as an alert, failed health check, latency spike, failed deployment validation, or customer-impact report.
- Ask teams to gather evidence before choosing a fix. Useful evidence includes deployment records, workflow runs, logs, traces, metrics, recent commits, pull requests, and known runbook steps.
- Use source context when available to connect symptoms to likely code paths.
- Require a customer-safe incident summary: what happened, what is known, what is still uncertain, what action is recommended, and what follow-up work should be tracked.
- Keep human review visible. Even when an agent proposes a cause or remediation, the team should explain how they validated it.

## Delivery Caveats

Azure SRE Agent capabilities, GitHub agent workflows, source-code integration, and pull-request creation can vary by tenant policy, region, product availability, and run mode. Coaches should validate access before delivery and keep a simulated incident packet ready.

The fallback should preserve the learning objective. If live SRE Agent access is not available, teams can still inspect the same evidence packet, write the To-Do Plan manually, identify the likely source area, and draft the follow-up issue or pull request summary.

## Primary Sources

- [microsoft/sre-agent](https://github.com/microsoft/sre-agent)
- [Azure/sre-agent-plugins](https://github.com/Azure/sre-agent-plugins)
- [Connect source code in Azure SRE Agent](https://learn.microsoft.com/en-us/azure/sre-agent/connect-source-code)