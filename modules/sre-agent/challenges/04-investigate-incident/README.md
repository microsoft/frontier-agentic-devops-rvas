# Challenge 04: Investigate a Controlled Azure Incident

## Scenario

You will intentionally break Grubify and use Azure SRE Agent to investigate the resulting Azure signal. The point is to practice evidence-first operations: start from user impact and telemetry, then let the agent help collect and explain evidence.

## Goals

- Trigger a controlled Grubify failure.
- Observe the symptom and Azure Monitor incident path.
- Use Azure SRE Agent to investigate logs, metrics, traces, resources, and runbooks.
- Separate likely cause, alternatives, and unknowns.
- Mitigate or recover only after evidence supports the action.

## Estimated Time

60 minutes.

## Trigger the Incident

From the starter lab:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
bash scripts/break-app.sh
```

Open the Grubify frontend and reproduce the failure. In the official lab this commonly appears as an Add to Cart/API failure.

If using fallback evidence, open the coach-provided incident packet instead.

## Capture the Starting Signal

Record:

| Field | Value |
| --- | --- |
| Start time | `<timestamp>` |
| User-visible symptom | `<what failed>` |
| Affected endpoint or action | `<endpoint/action>` |
| Alert or incident name | `<name>` |
| First telemetry source checked | `<logs/metrics/traces/alert>` |

## Ask Azure SRE Agent to Investigate

Use a prompt like:

```text
The Grubify API is failing for the Add to Cart flow. Investigate using the connected Azure resources, logs, metrics, traces, and HTTP error runbook. Give me the evidence, likely cause, alternatives, and a safe mitigation plan.
```

If an incident activity already exists, open it and review the agent's autonomous investigation.

## Validate the Evidence

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

Do not accept a confident agent answer unless it cites evidence you can inspect.

## Mitigate and Recover

Ask the agent:

```text
Based on the evidence, what mitigation is safe for this lab, and what validation should prove recovery?
```

If the lab allows mitigation, run the recommended lab-safe recovery or follow your coach's instruction. Verify in the Grubify UI or with endpoint checks.

## Deliverables

- Incident starting signal.
- Azure SRE Agent investigation summary.
- Evidence table.
- Likely cause, alternative, unknowns, and mitigation plan.
- Recovery evidence or a clear reason recovery was not attempted.

## Success Criteria

- The team starts from the alert/user symptom, not from a guessed code fix.
- The agent uses Azure evidence and runbook context.
- Likely cause and alternatives are separated.
- Mitigation is gated by human or coach review.
- Recovery is proven with observable evidence.
