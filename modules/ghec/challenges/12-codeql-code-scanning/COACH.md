# Ch12 — Code Scanning with CodeQL & Autofix — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner configures CodeQL, reads vulnerability data-flow paths, reviews Autofix patches, and gates merges on scan status.
- **Control-catalogue evidence:** Using `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md`, confirm `SEC-CODE-SCANNING` is `approved pilot` only after effective-setting inspection, with workflow, analysis, triage, and PR-gate evidence.
- Ask "what's the path from user input to the dangerous sink?" (→ data flow from source to sink) and "how would you prioritize alerts?" (→ critical/high first, with a false-positive review cadence).
- Ask "what exact check does the merge gate wait for?" (→ the `code-scanning/codeql` check) and "what does it cost to scan all repositories rather than only high-risk ones?"
