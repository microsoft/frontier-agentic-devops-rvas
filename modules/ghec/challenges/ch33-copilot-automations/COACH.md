# Ch33 — Copilot Automations — Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` is the canonical task, evidence, and Definition of Done guide.

## Assurance record

- **Authorized scope:** record the customer private/internal repository, named repository owner, automation creator, independent reviewer, security/Copilot owner, and approval.
- **Evidence:** link the eligibility, configuration, controlled-trigger, session-log, review, audit-log, and operating evidence required by `README.md`.
- **Open risk:** record the unresolved licensing, policy, cost, prompt-injection, untrusted-trigger, review, or data-exposure risk and accountable owner; record `none` only when none remains.
- **Next decision:** record approved pilot, inspect-and-propose, unavailable, or not-applicable decision with owner and target date.

## Session-specific reviewer focus

- Confirm the target is private or internal and eligible for Copilot cloud agent; public repositories and EMU-owned repositories are not valid live targets.
- Confirm the default guardrail remains: event-triggered automations ignore users without repository write access. An exception is not part of this session.
- Compare the saved prompt and tool selection with the approved task. It must treat trigger/repository content as untrusted data, exclude secrets and bypasses, and grant no unnecessary write capability.
- Confirm each resulting PR or code push is attributed to the automation creator and independently reviewed. The creator must not approve their own attributed output.
- Verify session evidence and customer audit-log evidence are both retained, with a cost owner, stop conditions, disable route, and review cadence.
- Reject substitutions: GitHub Actions is not a Copilot automation, and GitHub Agentic Workflows are public preview and out of scope.
- When licensing, policy, approval, or eligibility is unavailable, confirm no automation was enabled and the decision package names the blocker, evidence, owner, and next decision.
