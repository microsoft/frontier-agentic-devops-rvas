# Ch34 — Enterprise Agent Configuration — Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). The paired `README.md` is canonical.

## Assurance record

- **Authorized scope:** enterprise, source organization, affected organizations, enterprise-owner authority, change approver, and rollback owner.
- **Evidence:** AI Controls configuration summary, `.github-private` source URL and commit, CODEOWNERS/ruleset evidence, pull request approvals, organization-instruction evidence, propagation test, and rollback record.
- **Open risk:** unsupported client, lower-level duplicate agent, missing Code Owner, propagation variance, or unavailable enterprise access; name the owner.
- **Next decision:** approve implementation, correct the source/ruleset, expand a proven configuration, revert, or obtain enterprise access.

## Reviewer focus

- Confirm the actual `.github-private` repository—not a `ghec-ch34-*` fallback—was selected under AI Controls → Agents → Configuration source.
- Confirm `/agents/` and `/CODEOWNERS` are Code Owner protected and an active ruleset requires the customer’s approved review and bypass model.
- Confirm the enterprise agent display name is exactly **Agentic DevSecOps**, its source path is `agents/agentic-devsecops.agent.md`, and its initial tools are least privilege with no MCP, secrets, managed settings, or plugin standards.
- Ask for both precedence records: custom instructions are personal, path-specific repository, repository-wide, agent, then organization; duplicate custom-agent names resolve from repository to organization to enterprise.
- Require source SHA and supported-client propagation evidence. A merged pull request alone is not proof of propagation.
- If enterprise access is absent, accept only an approval-ready decision package plus implementation PR/patch marked pending enterprise application; reject any claim that fallback resources completed enterprise configuration.
- Confirm rollback is an approved revert to a known-good source commit, followed by configuration-summary and propagation validation.
