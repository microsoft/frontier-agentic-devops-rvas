# Fix XSS & Unsafe Output: Delivery Assurance

Review this activity against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` contains the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** Name the customer target and approving owner.
- **Evidence:** Check the Definition of Done in `README.md` and link or attach the evidence.
- **Open risk:** Name each unresolved risk and accountable owner, or enter `none`.
- **Next decision:** Name the next action, owner, and date.

## Session-specific reviewer focus

- Do not stop at the alert location. Trace the data source and output sink.
- Input filtering alone is insufficient. Require safe rendering or context-appropriate encoding.
- Security fixes can break page rendering. Test the affected UI path after each change.
