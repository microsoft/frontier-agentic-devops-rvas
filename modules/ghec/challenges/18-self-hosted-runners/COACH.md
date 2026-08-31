# Ch18 — Self-Hosted & Larger Runners — Delivery Assurance

Review the completed work against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md) and the paired `README.md` Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Reviewer focus

- **Expected outcome:** the customer implementation owner registers self-hosted runners in an org runner group, targets workflows with labels, hardens runner isolation, and documents operational ownership.
- **Governance controls:** Confirm `RUN-RUNNER-GROUPS` and `RUN-HOST-HARDENING` in the existing register with effective-setting evidence and the selected path.
- **Enterprise runner boundary:** Confirm `RUN-REPOSITORY-RUNNERS` and `RUN-HOSTED-RUNNERS` show effective enterprise policy, runner-group/host-hardening compatibility, and owner; changes are proposals unless enterprise-authorized.
- **Check these risks:** ask "which credential does config.sh want, and how long does it live?" (→ registration token, good for one registration) and "what stops a rogue runner from stealing secrets?" (→ network isolation, secrets not passed to untrusted runners).
- **Ask:** "How do you audit which repos use which runners?" (→ labels in the workflow file + org runner API) and "What's the update/rotation cadence?" (→ quarterly or after an OS patch).
