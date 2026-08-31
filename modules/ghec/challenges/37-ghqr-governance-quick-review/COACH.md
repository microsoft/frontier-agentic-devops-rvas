# Ch37: Governance Quick Review with ghqr Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer organization, reviewer role, token boundary, evidence location, optional enterprise authorization, and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the `ghqr` report files, tool/version evidence, finding triage, and corroborating API/audit/settings evidence.
- **Open risk:** record unavailable checks, insufficient token scope, enterprise-only policy source, accepted exception, remediation dependency, or `none`.
- **Next decision:** record the handover, remediation pilot, enterprise-evidence request, exception review, or recurring posture-review cadence with owner and date.

## Session-specific reviewer focus

- Confirm that the governance owner has a read-only GitHub posture review and a prioritized remediation backlog.
- Ask which checks were unavailable and why. Separate organization settings from enterprise settings.
- Ask what an authorized remediation would change and what evidence would prove that the finding was resolved.

## Expected evidence

At the end of this work package, verify:

- Scan scope, customer approval, reviewer role, target host, and token boundary were recorded before execution.
- `ghqr -h` or equivalent tool/version evidence was captured.
- The organization scan command and generated report paths are recorded.
- Enterprise scan status is explicit: completed with authorization, or not authorized/not applicable.
- Material findings have evidence links, an owner, rollback needs, and a review cadence.
- At least one finding is corroborated with a GitHub setting, audit, or API query where available.
- No setting was changed without a separate approved change path.

## Delivery risks and recovery

### Token scope is insufficient
Symptom: `ghqr` reports unavailable checks or authorization failures.  
Fix: Record the degraded evidence boundary. Ask the customer owner to approve a new least-privilege token only if the missing surface is in scope. Do not treat unavailable checks as compliant.

### Enterprise-only settings are inferred from org-only evidence
Symptom: The participant claims an enterprise policy value after running only `ghqr scan -o <org>`.  
Fix: Mark the enterprise source unavailable and request enterprise owner evidence. Organization settings can show local posture but cannot prove hidden enterprise inheritance.

### Report artifacts expose sensitive posture
Symptom: The participant wants to commit raw reports to a public or broadly visible repository.  
Fix: Move reports to the customer-approved evidence location and retain only non-secret report artifacts.

### Findings become automatic remediation
Symptom: The participant starts changing settings directly from the `ghqr` recommendation list.  
Fix: Stop. Require a separate customer-approved change before modifying any setting.

### GHE.com data residency target fails
Symptom: Authentication or API host errors occur for a data-residency enterprise.  
Fix: Use `--hostname <customer>.ghe.com` or set `GH_HOST=<customer>.ghe.com`, then re-run only after the customer confirms the host and token are for that environment.

## Progressive support

Use these in order. Give the first prompt, wait, and add detail only when the delivery team is blocked.

1. Hint 1 (gentle): Start by writing down what you are allowed to inspect before you run the tool.
2. Hint 2 (medium): Keep the organization scan mandatory, and treat enterprise as optional unless the enterprise owner has authorized it.
3. Hint 3 (specific): Run `ghqr scan -o <org>`, keep the JSON plus Markdown or XLSX output, then corroborate and prioritize the top findings.

## Handover questions

Use these to confirm the adoption decision and accountable next step:

- Which `ghqr` findings are accepted as current baseline, proposed for change, or recorded as exceptions?
- Which findings require enterprise owner evidence before the organization owner can decide?
- What is the next posture-review cadence, and who owns it?
- Which single remediation candidate has enough evidence and approval to become a bounded pilot?

## Delivery notes

- This activity is read-only by default. Focus on sound evidence, source-level verification, and customer-owned decisions.
- Mock or replay output can be useful for facilitation, but customer evidence must come from the authorized customer scan unless clearly labelled otherwise.
- If a finding maps to an existing specialized lesson, route follow-up work there: Ch06 for organization baseline, Ch08 for rulesets/properties, Ch09 for audit evidence, Ch28 for enterprise identity/network, Ch29 for programmatic access, Ch30 for Copilot/AI governance, Ch34 for enterprise agent configuration, or Ch36 for repository intake.
