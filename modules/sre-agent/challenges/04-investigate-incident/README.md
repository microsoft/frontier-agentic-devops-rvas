# Activity 04: Investigate an incident with evidence

**Session outcome:** Your investigation links the symptom to Azure evidence you can inspect. You have recorded the investigation time and checked the evidence quality. Recovery is verified or marked not tested.

## Scenario

Investigate a current or recent incident from the service used in Activity 03.
Start with user impact and its Azure signal. Use a controlled Grubify failure only
for approved sample practice.

## Goals

- Select a service incident, or trigger a controlled Grubify failure.
- Observe the symptom and Azure Monitor incident path.
- Use Azure SRE Agent to investigate logs, metrics, traces, resources, and runbooks.
- Separate likely cause, alternatives, and unknowns.
- Mitigate or recover only after evidence supports the action.

> [!TIP]
> You can replace Grubify with a service your team operates.
> Start with a real alert, customer symptom, recent incident, or safely reproducible failure.
> Use the service's Azure Monitor signal, logs, metrics, traces, and runbooks.
> **Do not inject production faults for this activity.**

## Trigger a Grubify incident in the lab

Run these commands only in the approved starter lab, after agreeing on recovery
and stop conditions. Skip them for a customer incident:

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

Record when you start investigating and when the evidence supports a conclusion.
Keep these times separate from when the alert started and the service recovered.

## Ask Azure SRE Agent to investigate

Use a prompt like this, replacing Grubify and the symptom with the selected incident:

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

Record the elapsed investigation time. Note which claims have supporting sources
and which you corrected or could not verify. Claim an improvement only if you
have a comparable prior investigation to measure against.

## Mitigate and recover

Ask the agent:

```text
Based on the evidence, what mitigation is safe for this lab, and what validation should prove recovery?
```

In the lab, get the operator's approval before running the proposed recovery.
Repeat the previously failing action in the Grubify UI or run its endpoint checks.
Inspect fresh telemetry.
Record the check time and result.

For a customer incident, follow the existing change and incident process.
Record the recovery result you observed. Otherwise, mark **recovery not tested**
and name the owner and reason. An agent's suggestion does not prove recovery.

## Deliverables

- Incident starting signal.
- Azure SRE Agent investigation summary.
- Evidence table.
- Likely cause, alternative, unknowns, and mitigation plan.
- Recovery evidence or a clear reason recovery was not attempted.
- Record the investigation time and evidence quality. Claim improvement only when a comparison supports it.
