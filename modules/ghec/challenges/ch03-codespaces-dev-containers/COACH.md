# Ch03 — Codespaces & Dev Containers — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Prebuild-aware setup belongs in `onCreateCommand` or `updateContentCommand`; do not accept dependency installation only in `postCreateCommand`.
- Confirm the recorded trigger, regions, retained versions, and freshness behavior match the customer team's cost and dependency-freshness needs.
- Inspect the successful prebuild workflow and a new **Prebuild ready**
  Codespace, then confirm `CSP-DEVCONTAINER` and `CSP-PREBUILDS` are recorded
  in the governance register with effective-setting evidence.
