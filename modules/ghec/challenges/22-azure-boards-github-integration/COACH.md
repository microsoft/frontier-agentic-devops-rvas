# Ch22 — Connect Azure Boards to GitHub — Delivery Assurance

Review the completed work against the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md) and the paired `README.md` Definition of Done.

## Assurance record

- **Authorized scope:** record the customer target and approving owner.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link or attach the evidence.
- **Open risk:** record the unresolved risk and accountable owner, or `none`.
- **Next decision:** record the handover, pilot, rollout, cutover, or follow-up action with owner and date.

## Reviewer focus

- **Expected outcome:** the customer implementation owner connects Azure Boards to GitHub so post-migration commits and pull requests continue to link to work items.
- **Reason:** GitHub Enterprise Importer migrates Git source, pull requests, and existing work-item links, but not Azure Boards work items or backlog state. This activity restores the link for new work after cutover.
- **Preferred evidence:** use a real migrated repository and a low-risk Azure Boards work item. If the production project is not authorized, validate with a disposable work item and record the production connection plan.
- **Check these risks:** the Azure Boards App is scoped to the selected repository, the repository connects to only one Azure DevOps project, and a merged PR with `Fixes AB#<id>` creates the expected state transition.
