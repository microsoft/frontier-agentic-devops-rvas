# Ch04 — GitHub Actions CI Fundamentals — Delivery Assurance

This is a concise review overlay. Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); the paired `README.md` is the canonical source for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Customer adoption outcome: the customer implementation owner builds a real CI pipeline that runs across a matrix, caches deps, publishes artifacts, and sets default token permissions (`read-only` for workflows).
- **Governance controls:** Confirm `ACT-ALLOWED-ACTIONS`, `ACT-ENABLEMENT`, `ACT-WORKFLOW-TOKEN`, `ACT-FORK-PR`, and `ACT-RETENTION` in the existing register. `ACT-ENABLEMENT` must show the effective enterprise policy, CI compatibility evidence, and preservation of the approved `docs/actions-governance-decision.md` choice.
- Implementation risks to verify: ask "what exact string does the merge gate look for?" (→ check name) and "what makes the second run faster than the first?" (→ cache hit + cache scope).
- Delivery lead prompts: ask "what's the risk if a workflow can write a token back to the repo?" (→ supply-chain attack) and "how long should Actions cache survive?" (→ org policy).
