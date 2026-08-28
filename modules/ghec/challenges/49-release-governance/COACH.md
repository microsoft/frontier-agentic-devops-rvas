# Ch49 — Release Governance — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer organization, release repository, release owner, approver group, and production settings boundary.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link release candidate issue, approval evidence, release notes, tag/release proof, and rollback decision.
- **Open risk:** record unresolved release ruleset, environment approval, deployment protection, rollback automation, or `none`.
- **Next decision:** record the first production release, control rollout, ruleset approval, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: releases have an auditable request, approval, evidence, and rollback trail.
- **Governance controls:** Confirm release owner, approver, release-note standard, tag naming, exception path, and evidence retention location.
- Implementation risks to verify: ask "which controls are advisory today versus enforced by rulesets or environments?" and "who can publish a release outside the approved path?"
- Delivery lead prompts: ask "where is the approval linked to the release?" and "what evidence would prove rollback readiness before production rollout?"
