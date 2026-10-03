# Activity 04: Investigate a controlled Azure incident

**Session outcome:** Your investigation links the observed symptom to Azure evidence you can inspect and explains the likely cause, alternatives, and unknowns. You have a safe mitigation plan and have verified recovery or explained why you did not attempt it.

## Scenario

Intentionally break Grubify, then use Azure SRE Agent to investigate the Azure signal. Start with user impact and telemetry; use the agent to collect and explain evidence.

## Goals

- Trigger a controlled Grubify failure.
- Observe the symptom and Azure Monitor incident path.
- Use Azure SRE Agent to investigate logs, metrics, traces, resources, and runbooks.
- Separate likely cause, alternatives, and unknowns.
- Mitigate or recover only after evidence supports the action.

> [!TIP]
> **Use your own service.** You can replace Grubify with a service your team operates.
> Start with a real alert, customer symptom, recent incident, or safely reproducible failure.
> Use the service's Azure Monitor signal, logs, metrics, traces, and runbooks.
> **Do not break production without an approved test path.**

## Trigger the incident

From the starter lab:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
bash scripts/break-app.sh
```

Open the Grubify frontend and reproduce the failure. In the official lab this commonly appears as an Add to Cart/API failure.

If using fallback evidence, open the provided incident packet instead.

## Capture the starting signal

Record:

| Field | Value |
| --- | --- |
| Start time | `<timestamp>` |
| User-visible symptom | `<what failed>` |
| Affected endpoint or action | `<endpoint/action>` |
| Alert or incident name | `<name>` |
| First telemetry source checked | `<logs/metrics/traces/alert>` |

## Ask Azure SRE Agent to investigate

Use a prompt like:

```text
The Grubify API is failing for the Add to Cart flow. Investigate using the connected Azure resources, logs, metrics, traces, and HTTP error runbook. Give me the evidence, likely cause, alternatives, and a safe mitigation plan.
```

If an incident activity already exists, review the agent's investigation there.

## Validate the evidence

Build an investigation note:

| Evidence | What it shows | Source |
| --- | --- | --- |
| Alert | `<signal>` | Azure Monitor |
| Log query | `<pattern/result>` | Log Analytics |
| Trace or exception | `<failure detail>` | Application Insights |
| Runbook step | `<recommended diagnostic>` | Knowledge |
| Resource state | `<container/revision/config>` | Azure |

Then write:

```md
Likely cause:
Alternative hypothesis:
Unknowns:
Safe mitigation:
Validation after mitigation:
```

**Do not accept an agent answer unless it cites evidence you can inspect.**

## Mitigate and recover

Ask the agent:

```text
Based on the evidence, what mitigation is safe for this lab, and what validation should prove recovery?
```

If the lab allows mitigation, run the recommended lab-safe recovery. Verify in the Grubify UI or with endpoint checks.

## Deliverables

- Incident starting signal.
- Azure SRE Agent investigation summary.
- Evidence table.
- Likely cause, alternative, unknowns, and mitigation plan.
- Recovery evidence or a clear reason recovery was not attempted.
