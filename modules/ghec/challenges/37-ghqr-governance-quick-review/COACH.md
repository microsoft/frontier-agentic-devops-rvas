# Ch37 — Governance Quick Review with ghqr — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer organization, reviewer role, token boundary, evidence location, optional enterprise authorization, and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the `ghqr` report files, tool/version evidence, finding triage, corroborating API/audit/settings evidence, and governance-register rows.
- **Open risk:** record unavailable checks, insufficient token scope, enterprise-only policy source, accepted exception, remediation dependency, or `none`.
- **Next decision:** record the handover, remediation pilot, enterprise-evidence request, exception review, or recurring posture-review cadence with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer governance owner has a broad, read-only GitHub posture review and a prioritized decision backlog tied to existing governance controls.
- **Governance controls:** Confirm findings are mapped to existing catalogue Control IDs where possible. Do not accept invented control IDs or a parallel findings spreadsheet as the source of truth.
- Implementation risks to verify: ask "which checks were unavailable, and why?" and "which settings came from organization scope versus enterprise scope?"
- Delivery lead prompts: ask "what would change if this finding became an approved pilot?" and "what evidence would prove the finding was resolved at the next review?"

## Expected evidence

At the end of this work package, verify:

- Scan scope, customer approval, reviewer role, target host, and token boundary were recorded before execution.
- `ghqr -h` or equivalent tool/version evidence was captured.
- The organization scan command and generated report paths are recorded.
- Enterprise scan status is explicit: completed with authorization, or not authorized/not applicable.
- Material findings are mapped into the governance register with existing control IDs, evidence links, owner, implementation path, exception/rollback, and review cadence.
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
Fix: Move reports to the customer-approved evidence location. Store links and non-secret summaries in the register.

### Findings become automatic remediation
Symptom: The participant starts changing settings directly from the `ghqr` recommendation list.  
Fix: Stop and return to the governance register. Convert findings into `inspect-and-propose` rows unless a separate approved pilot/change record exists.

### GHE.com data residency target fails
Symptom: Authentication or API host errors occur for a data-residency enterprise.  
Fix: Use `--hostname <customer>.ghe.com` or set `GH_HOST=<customer>.ghe.com`, then re-run only after the customer confirms the host and token are for that environment.

## Progressive support

Use these in order. Preserve customer ownership: give the first prompt, wait, then increase specificity only if the delivery team is blocked.

1. Hint 1 (gentle): Start by writing down what you are allowed to inspect before you run the tool.
2. Hint 2 (medium): Keep the organization scan mandatory, and treat enterprise as optional unless the enterprise owner has authorized it.
3. Hint 3 (specific): Run `ghqr scan -o <org>`, keep the JSON plus Markdown or XLSX output, then map the top findings to rows in the existing governance register.

## Handover questions

Use these to confirm the adoption decision and accountable next step:

- Which `ghqr` findings are accepted as current baseline, proposed for change, or recorded as exceptions?
- Which findings require enterprise owner evidence before the organization owner can decide?
- What is the next posture-review cadence, and who owns it?
- Which single remediation candidate has enough evidence and approval to become a bounded pilot?

## Delivery notes

- This activity is intentionally read-only by default. The value is in evidence quality, control mapping, and customer-owned decisions.
- Mock or replay output can be useful for facilitation, but customer evidence must come from the authorized customer scan unless clearly labelled otherwise.
- If a finding maps to an existing specialized lesson, route follow-up work there: Ch06 for organization baseline, Ch08 for rulesets/properties, Ch09 for audit evidence, Ch28 for enterprise identity/network, Ch29 for programmatic access, Ch30 for Copilot/AI governance, Ch34 for enterprise agent configuration, or Ch36 for repository intake.
