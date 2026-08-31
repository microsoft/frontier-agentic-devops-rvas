# Ch49: Release Governance Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer organization, release repository, release owner, approver group, and production settings boundary.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link release candidate issue, approval evidence, release notes, tag/release proof, and rollback decision.
- **Open risk:** record unresolved release ruleset, environment approval, deployment protection, rollback automation, or `none`.
- **Next decision:** record the first production release, control rollout, ruleset approval, or follow-up action with owner and date.

## Session-specific reviewer focus

- Confirm that each release has a traceable request, approval, evidence record, and rollback decision.
- **Governance controls:** Confirm release owner, approver, release-note standard, tag naming, exception path, and evidence retention location.
- Ask which controls are advisory and which rulesets or environments enforce. Check who can publish outside the approved path.
- Ask where the release links to its approval and what evidence proves rollback readiness.
