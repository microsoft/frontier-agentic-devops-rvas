# Ch17 — Webhooks & GitHub Apps — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner receives real webhook deliveries, verifies them cryptographically, and graduates from passive listener (webhooks) to active responder (GitHub App identity).
- **Governance register row:** Confirm one register row added for webhooks/GitHub Apps: webhook scope (repo + org), App permissions (granular per use case), signature verification requirement documented, installation scope and credential rotation policy recorded. Row uses `approved pilot` or `inspect-and-propose` depending on App scope (org-wide vs repo-specific).
- Implementation risks to verify: ask "what exact bytes did you sign, and what exact bytes did GitHub sign?" (→ raw request body) and "what happens if a bad actor replays an old delivery?" (→ duplicate-check on X-GitHub-Delivery).
- Delivery lead prompts: ask "which of your three credentials is allowed to comment?" (→ App installation token only, not personal token or webhook).
