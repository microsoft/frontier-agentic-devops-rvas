# Ch17 — Webhooks & GitHub Apps — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner receives webhook deliveries, verifies their signatures, and uses a GitHub App when the integration must act on GitHub.
- Confirm the effective repository and organization webhook settings, GitHub App permissions and installation scope, signature verification, and credential rotation.
- **Enterprise hook boundary:** If enterprise hooks are in scope, confirm their event scope, receiver, HMAC verification, and retention without conflating them with repository or organization hooks.
- Ask "what exact bytes did you sign, and what exact bytes did GitHub sign?" (→ the raw request body) and "what happens if someone replays an old delivery?" (→ check for a duplicate `X-GitHub-Delivery`).
- Ask "which credential is allowed to comment?" (→ the App installation token, not a personal token or webhook secret).
