# Activity 03: Connect and test response context

**Session outcome:** You have connected or repaired the service's runbook and response route. A safe test shows that Azure SRE Agent uses them correctly.

## Scenario

Use Grubify or the same customer service as Activity 01. Check the runbook version and alert route
with the service owner, then connect missing sources or repair stale links.

## Goals

- Verify what context Azure SRE Agent has loaded.
- Review knowledge files, runbooks, and architecture context.
- Connect or repair the runbook and Azure Monitor response route.
- Test that a safe alert reaches the expected response plan and uses the correct runbook.
- Use team memory only for service information missing from connected sources.

> [!TIP]
> You can replace Grubify with a service your team operates.
> Use its runbooks, architecture notes, alert routes, response plans, and ownership details.
> **Do not paste secrets, private contacts, or sensitive tenant details into notes or chat.**

## Inspect connected context

In the Azure SRE Agent portal, open the agent created for the lab and inspect:

| Area | What to look for |
| --- | --- |
| Azure resources | Grubify Container Apps, resource group, managed identity |
| Incidents | Azure Monitor connection and alert response path |
| Knowledge | HTTP error runbook and app architecture notes |
| Custom agents | `incident-handler`, `code-analyzer`, `issue-triager` when configured |
| Response plans | Alert routing and autonomous/review behavior |
| Global tools | Azure observability and optional GitHub tools |

If you are using a fallback packet, inspect its setup summary as practice.
It cannot prove a live connection or route.

## Connect or repair the response path

1. In the agent's knowledge sources, connect the approved runbook and architecture
   source, or update a stale connection. Check that the agent can retrieve the
   current version.
2. Connect the service's Azure Monitor incident source and configure its response
   plan or supported route. Confirm the target agent and human approval settings
   with the owner.
3. Send an approved test alert through that route, or inspect a recent real
   alert handled under the same configuration. Verify the target plan ran and
   referenced the intended runbook. Do not inject a production fault.

If the configuration is already correct, test it without changing it. If you
cannot test the route, mark it **not tested** and assign an owner to follow up.

## Ask context questions

Use Azure SRE Agent chat. If using your own service, replace Grubify in these prompts:

```text
What do you know about the Grubify architecture?
```

```text
Summarize the HTTP 500 errors runbook and the diagnostic steps it recommends.
```

```text
Which response plan or incident route would handle a Grubify HTTP error alert?
```

Capture claims supported by connected resources or knowledge. Mark the rest as open questions.

## Add team memory if needed

Only add memory when the team needs persistent context not already supplied by
its connected sources. Use approved role names, for example:

```text
Remember the approved recovery owner for <service> is <team role>. Use <approved runbook source> for its escalation path.
```

**Do not store personal data, private escalation contacts, secrets, or tenant-specific details.**

## Build the context map

Use the existing service record. If you need a separate context map, use this table:

| Context item | Source | How it helps incident response | Missing or risky? |
| --- | --- | --- | --- |
| App architecture | Knowledge file | Explains how the API and frontend connect | `<yes/no>` |
| HTTP error runbook | Knowledge file | Gives diagnostic sequence | `<yes/no>` |
| Azure Monitor alert | Incident platform | Starts investigation | `<yes/no>` |
| Log Analytics | Connector | Supports KQL evidence | `<yes/no>` |
| Application Insights | Connector | Supports traces/exceptions | `<yes/no>` |
| Team memory | Memory | Clarifies ownership | `<yes/no>` |

## Deliverables

- Record the connected runbook's source and version, plus the response route and any repairs.
- Save the safe test or recent alert result that shows the agent used the correct route and runbook.
- Check an agent answer against its source. Leave untested routes open for follow-up. Memory is optional.
