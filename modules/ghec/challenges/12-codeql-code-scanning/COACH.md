# Ch12 — Code Scanning with CodeQL & Autofix — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner stands up CodeQL scans (default and advanced), reads real vulnerability findings via their data-flow paths, applies autofix where safe, and gates merges on scan status.
- **Control-catalogue evidence:** Using `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`, confirm `SEC-CODE-SCANNING` is `approved pilot` only after effective-setting inspection, with workflow, analysis, triage, and PR-gate evidence.
- Implementation risks to verify: ask "what's the path from user input to the dangerous sink?" (→ data-flow from source to sink) and "how would you prioritize alerts?" (→ critical/high first, false-positive review cadence).
- Delivery lead prompts: ask "what exact check does the merge gate wait for?" (→ the `code-scanning/codeql` check) and "what's the cost of scanning all repos vs high-risk only?"
