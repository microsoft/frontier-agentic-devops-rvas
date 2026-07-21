# Ch08 — Repository Rulesets & Custom Properties — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner makes governance follow metadata instead of repo names — custom properties drive a property-targeted org ruleset.
- **Governance register rows:** Confirm two register rows added: (1) custom repository properties (schema defined, values set on repos) with links to API schema export; (2) organization rulesets (property-targeted, enforcement active, bypass logs documented). Both rows use `approved pilot` status and link to API snapshots.
- Implementation risks to verify: ask "what makes a repo created next week automatically inherit these rules without anyone editing the ruleset?" (→ the property condition + a default property value on new repos).
- Delivery lead prompts: ask "which two rules would stack if a repo matched multiple property conditions?" and "what's the difference between disabling a ruleset and adding a bypass actor?"
