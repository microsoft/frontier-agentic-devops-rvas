# Explore the Attack Surface — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer delivery team members may confuse shared default-branch alerts with their personal branch work; remind them this activity is reconnaissance only and later PR checks...
- Customer delivery team members often skim alert titles without opening full paths and traces; push them to inspect locations, flows, and surrounding code before summarizing.
- Dependabot can feel separate from code scanning; frame it as another part of the same attack surface inventory.
