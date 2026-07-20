# Activity 03: Onboard Service Context and Response Plans

## Scenario

Azure SRE Agent is only useful when it has the right starting context. In this activity, you inspect the service knowledge, response plans, custom agents, and team memory that shape how it responds to Grubify incidents.

## Goals

- Verify what context Azure SRE Agent has loaded.
- Review knowledge files, runbooks, and architecture context.
- Understand the incident-handler, code-analyzer, and issue-triager roles when available.
- Inspect how Azure Monitor alerts route to the agent.
- Add safe team memory for ownership and escalation.

## Estimated Time

45 minutes.

> [!IMPORTANT]
> **Bring your own service (do this first)**
>
> This activity is most valuable when Azure SRE Agent learns the context for a service your team will keep operating after the session. If you have a candidate Azure workload in a subscription you control, onboard **that** service everywhere this guide references Grubify so its real runbooks, architecture notes, telemetry, response plans, and ownership context stay useful in your tenant.
>
> - **Have a candidate?** Inspect and improve the context for your own service: connected Azure resources, alert routes, knowledge files, response plans, custom agents, and safe team memory. Use real operational context, but do not paste secrets, private contacts, or sensitive tenant details into notes or chat.
> - **No suitable Azure service yet?** Use Grubify below as the safe fallback target for practicing context onboarding.
>
> Tell your coach which path you took — bringing your own is the goal; Grubify is the fallback.

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

If you are using a fallback packet, your coach will provide screenshots or a setup summary for these areas.

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

Capture the parts of the answer that are grounded in connected resources or knowledge. Mark anything vague as an open question.

## Add Safe Team Memory

Add a small, non-sensitive memory:

```text
Remember that for this lab, the operator validates recovery, the reviewer approves GitHub remediation work, and the escalation handler decides whether autonomous mitigation is allowed.
```

Do not store real personal data, private escalation contacts, secrets, or tenant-specific details.

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

## Success Criteria

- The team can explain what context the agent has and where it came from.
- The team can name at least one runbook or knowledge source the agent should use.
- The team can explain the alert-to-agent path at a high level.
- Missing context is captured as a follow-up, not ignored.
