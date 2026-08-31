# Ch51: LFS and Monorepo Governance Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` defines the tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record the customer organization, monorepo target, storage/quota owner, area owners, and migration boundary.
- **Evidence:** inspect the completed Definition of Done in `README.md`; link repository size evidence, LFS patterns, CODEOWNERS map, large-file intake issue, and next rollout decision.
- **Open risk:** record unresolved history rewrite, LFS quota, package ownership, generated asset, ruleset, or `none`.
- **Next decision:** record migration approval, first package cohort, LFS quota owner decision, or follow-up action with owner and date.

## Session-specific reviewer focus

- Confirm that monorepo ownership boundaries are visible and that teams review large files before storage risk grows.
- **Governance controls:** Confirm CODEOWNERS owner model, approved LFS patterns, exception path, quota owner, migration approver, and evidence retention location.
- Ask what happens when a team adds a 200 MB model or binary and who approves history rewrites or LFS migrations.
- Ask where package ownership boundaries are enforced. Separate documented large-file controls from enforced controls.
