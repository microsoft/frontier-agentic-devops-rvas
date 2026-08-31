# Activity 03: Onboard Service Context and Response Plans

## Scenario

Azure SRE Agent needs accurate context. Inspect the service knowledge, response plans, custom agents, and team memory that guide its response to Grubify incidents.

## Goals

- Verify what context Azure SRE Agent has loaded.
- Review knowledge files, runbooks, and architecture context.
- Understand the incident-handler, code-analyzer, and issue-triager roles when available.
- Inspect how Azure Monitor alerts route to the agent.
- Add safe team memory for ownership and escalation.

> [!TIP]
> **Bring your own service:** onboard a service your team will operate after the session, wherever this guide references Grubify, using its real runbooks, architecture notes, alert routes, response plans, and ownership context. **Do not paste secrets, private contacts, or sensitive tenant details into notes or chat.** No suitable service? Use Grubify to practise context onboarding.

## Inspect Connected Context

In the Azure SRE Agent portal, open the agent created for the lab and inspect:

| Area | What to look for |
| --- | --- |
| Azure resources | Grubify Container Apps, resource group, managed identity |
| Incidents | Azure Monitor connection and alert response path |
| Knowledge | HTTP error runbook and app architecture notes |
| Custom agents | `incident-handler`, `code-analyzer`, `issue-triager` when configured |
| Response plans | Alert routing and autonomous/review behavior |
| Global tools | Azure observability and optional GitHub tools |

If you are using a fallback packet, use the provided screenshots or setup summary for these areas.

## Ask Context Questions

Use Azure SRE Agent chat:

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

## Add Safe Team Memory

Add a small, non-sensitive memory:

```text
Remember that for this lab, the operator validates recovery, the reviewer approves GitHub remediation work, and the escalation handler decides whether autonomous mitigation is allowed.
```

**Do not store personal data, private escalation contacts, secrets, or tenant-specific details.**

## Build the Context Map

Create a table:

| Context item | Source | How it helps incident response | Missing or risky? |
| --- | --- | --- | --- |
| App architecture | Knowledge file | Explains API/frontend shape | `<yes/no>` |
| HTTP error runbook | Knowledge file | Gives diagnostic sequence | `<yes/no>` |
| Azure Monitor alert | Incident platform | Starts investigation | `<yes/no>` |
| Log Analytics | Connector | Supports KQL evidence | `<yes/no>` |
| Application Insights | Connector | Supports traces/exceptions | `<yes/no>` |
| Team memory | Memory | Clarifies ownership | `<yes/no>` |

## Deliverables

- Context map.
- One validated agent answer about architecture.
- One validated agent answer about runbook or response plan.
- One safe team memory or a note explaining why memory was skipped.
