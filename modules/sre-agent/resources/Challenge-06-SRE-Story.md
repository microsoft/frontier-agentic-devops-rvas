# Challenge 06 SRE Story Companion

This companion note keeps the game-day story aligned around the official Microsoft Azure SRE Agent starter lab.

## Scenario

The team has deployed or been given access to the Grubify sample app and Azure SRE Agent. The app is healthy at baseline. During the game day, a controlled failure causes the ordering flow to fail or degrade.

The team must use Azure SRE Agent as the primary investigation surface. GitHub appears only after Azure evidence supports source-aware remediation.

## Participant Mission

Produce a short operational response that explains:

- the user-visible symptom;
- the Azure signal that started the investigation;
- the evidence Azure SRE Agent gathered;
- the likely cause and alternatives;
- the mitigation or remediation path;
- the recovery evidence;
- the follow-up improvement needed before production autonomy.

## Evidence Packet

Coaches should prepare enough evidence for teams to reason without guessing:

- Azure Monitor alert;
- Log Analytics query result;
- Application Insights trace or exception;
- Grubify endpoint or UI symptom;
- Azure SRE Agent transcript;
- runbook or knowledge excerpt;
- optional source-code reference;
- optional GitHub issue or PR packet.

## Suggested Flow

1. Declare the incident from the user impact.
2. Review Azure alert and telemetry.
3. Ask Azure SRE Agent to investigate with evidence.
4. Validate the agent's claims.
5. Use source context only after operational evidence is established.
6. Create remediation work.
7. Prove recovery.
8. Identify one guardrail or context improvement.

## Coach Notes

Keep the challenge focused on Azure SRE Agent. If teams turn it into a generic GitHub PR exercise, redirect them to the Azure signal and agent transcript.

Good prompts:

- Which Azure signal started the investigation?
- What evidence did Azure SRE Agent actually inspect?
- What would disprove the likely cause?
- What human approval is needed before mitigation?
- What context should be added before trusting more autonomy?
