# Ch04 — GitHub Actions CI Fundamentals — Delivery Assurance

Use this review overlay with the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Session-specific reviewer focus

- Expected outcome: the customer owner builds a CI pipeline that runs across a matrix, caches dependencies, publishes artifacts, and sets default workflow token permissions to `read-only`.
- Confirm the effective Actions policy, default token permissions, fork pull-request boundary, and retention settings, then verify the CI workflow is compatible with them.
- Check the exact status-check name used by the merge gate and the cache hit and scope that speed up the second run.
- Ask "what's the risk if a workflow can write a token back to the repo?" (→ supply-chain attack) and "how long should Actions cache survive?" (→ org policy).
