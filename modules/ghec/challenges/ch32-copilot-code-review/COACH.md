# Ch32 — Copilot Code Review — Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` is the canonical task, evidence, and rollback guide.

## Assurance record

- **Authorized scope:** customer repository/cohort, repository owner, effective Copilot-policy source, and approving owner.
- **Evidence:** dated policy and ruleset exports; manual-review PR timeline; human-review and `CODEOWNERS` evidence; setup decision; rollback record.
- **Open risk:** false positives, missed findings, review latency/noise, runner/network/cost exposure, or unavailable policy—with an accountable owner.
- **Next decision:** retain manual review, approve/expand/revert a bounded automatic-review pilot, or retain the decision-package fallback.

## Session-specific reviewer focus

- Confirm the team chose a customer target first. The `ghec-ch32-*` repository is a safe fallback, not proof of customer rollout.
- Verify that Copilot was manually requested on a PR and that a human reviewer triaged its comments. Copilot must not be represented as an approver or merge gate.
- Check the automatic-review decision separately at repository versus organization ruleset scope. Require bounded targeting, an accountable approver, and documented choices for new-push and draft review.
- Verify human review and `CODEOWNERS` controls remain effective and that bypasses were neither added nor broadened for Copilot.
- Check shared `copilot-setup-steps.yml` versus optional dedicated `copilot-code-review.yml` for least privilege, runner/network/cost evidence, and rollback. Do not require a dedicated file.
- Confirm public-preview options—MCP tools, agent skills, and Fix with Copilot—are explicitly optional and were not needed to complete the session.
- If availability or authority is missing, accept the decision package only when it records evidence, a risk owner, pilot conditions, rollback, and a dated next decision.
