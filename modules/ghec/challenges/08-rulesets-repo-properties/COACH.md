# Ch08 — Repository Rulesets & Custom Properties — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: custom properties, rather than repository names, drive the customer’s organization ruleset.
- **Governance controls:** Confirm `REP-PROPERTY-SCHEMA`, `REP-ORG-RULESETS`, and `REP-REPO-RULESETS` in the existing register with effective-setting evidence and the selected path.
- Ask "what makes a repo created next week automatically inherit these rules without anyone editing the ruleset?" (→ the property condition + a default property value on new repos).
- Ask "which two rules would stack if a repo matched multiple property conditions?" and "what's the difference between disabling a ruleset and adding a bypass actor?"
