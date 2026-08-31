# Fix Injection Vulnerabilities: Delivery Assurance

Review this activity against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` contains the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** Name the customer target and approving owner.
- **Evidence:** Check the Definition of Done in `README.md` and link or attach the evidence.
- **Open risk:** Name each unresolved risk and accountable owner, or enter `none`.
- **Next decision:** Name the next action, owner, and date.

## Session-specific reviewer focus

- Reject input sanitization or regex filtering as the primary injection defense. Validation can enforce an input policy but cannot reliably prevent injection.
- After one fix, ask the team to search for the same unsafe query pattern elsewhere.
- Treat Copilot Autofix and other assistance as proposed work. Review it through existing PR and GHAS controls.
