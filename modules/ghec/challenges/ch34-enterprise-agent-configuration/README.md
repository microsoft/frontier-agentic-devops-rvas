# Ch34 — Enterprise Agent Configuration

> Deliver a customer-approved, auditable enterprise configuration source for an **Agentic DevSecOps** custom agent. Protect changes in `.github-private`, set that repository as the AI Controls configuration source, add deliberate organization instructions, and prove propagation and rollback.

| | |
|---|---|
| Track | Admin & Governance |
| Difficulty | Advanced |
| Duration | ~4 hrs, multi-session |
| Minimum input | Enterprise owner access to AI Controls, or an enterprise-owner sponsor who can apply an approval-ready implementation |
| App | none |
| EMU compatible | yes — this configures governance; do not create managed users or change identity settings |

## Customer delivery target

- **Customer objective:** establish a controlled, reviewable enterprise source for Copilot custom-agent configuration rather than distributing ungoverned agent files.
- **Customer-tenant target:** an approved organization-owned `.github-private` repository, selected in Enterprise **AI Controls → Agents → Configuration source**, with protected agent changes and one enterprise custom agent named **Agentic DevSecOps**.
- **Safety boundary:** begin with an approved customer target. Do not substitute a training repository for the enterprise configuration source, broaden agent tools, add secrets, enable MCP servers, or change unrelated Copilot policy as part of this activity.
- **Records to keep:** approved scope, source organization and repository, source commit and pull request, CODEOWNERS and ruleset evidence, AI Controls configuration-summary evidence, propagation test result, rollback commit, approvers, and review date.
- **Adoption handover:** the enterprise AI-controls owner accepts the source and propagation result; security/platform owners accept the agent boundary; each organization owner accepts its organization instructions.

> [!IMPORTANT]
> **Enterprise access is a real delivery path, not an optional screenshot exercise.** An authorized enterprise owner must create or select the actual `.github-private` repository and set it as the AI Controls configuration source. If that access is unavailable, deliver the approval-ready package and implementation pull request described in [Part F](#part-f--no-enterprise-access-decision-package); do **not** claim the enterprise agent or configuration source is active.

## Prerequisites

- A named enterprise owner with access to **Enterprise settings → AI Controls → Agents**, and a named organization that can own the enterprise configuration repository.
- Copilot Business or Copilot Enterprise availability for the intended organizations. Record availability and supported-client limitations before testing.
- Named enterprise AI-controls, security, platform, organization-policy, and rollback approvers.
- A customer change record and non-secret evidence location.
- A review team or named maintainers for the `.github-private` repository.

## Scope and guardrails

This activity governs these customer register controls:

- `COP-ENTERPRISE-AGENT-SOURCE`
- `COP-ENTERPRISE-AGENT-CHANGE-CONTROL`
- `COP-ORG-CUSTOM-INSTRUCTIONS`
- `COP-AGENT-CONFIGURATION-ROLLBACK`

The enterprise agent source and organization custom instructions are different configuration surfaces. Do not represent organization instructions as enterprise policy, and do not assume an enterprise custom agent changes instruction precedence.

**Out of scope:** managed settings and plugin standards. Treat them as optional preview work requiring separate availability assessment, approval, change control, and rollback. Do not configure, validate, or report them as complete in this activity.

## Tasks

### Part A — Authorize the target and record the baseline

1. Record the customer enterprise, source organization, affected organizations, Copilot plan/availability, supported clients, change ticket, evidence location, approvers, and rollback owner.
2. Inspect **Enterprise settings → AI Controls → Agents**. Capture a dated, non-secret screenshot or export of the current configuration source and configuration summary. If no enterprise owner can inspect it, record that limitation; do not infer the source from repository contents.
3. Select the customer organization that will own the actual enterprise source. Confirm that creating or changing its `.github-private` repository is approved and that its default branch, visibility, maintainers, and retention meet customer policy.
4. Record the initial decision as `inspect-and-propose` until the enterprise owner authorizes the change. Use `approved implementation` only after the named approver authorizes the actual source and change.

### Part B — Create and protect the real enterprise source

5. In the approved source organization, create `.github-private` if it does not already exist. Use the enterprise governance template or an approved customer baseline. This repository is an enterprise governance artifact, not a `ghec-ch34-*` fallback resource.
6. Add root `CODEOWNERS` entries that require the designated enterprise AI-controls reviewers for `/agents/` and `/CODEOWNERS`. Example—replace the team with the customer-owned review team:

   ```text
   /agents/ @customer/enterprise-ai-controls
   /CODEOWNERS @customer/enterprise-ai-controls
   ```

7. Create an active ruleset for the default branch that protects the agent paths and `CODEOWNERS`. Require pull requests and Code Owner review, restrict direct updates, and record the narrowly scoped bypass actors, justification, and audit route. Use the customer’s normal required checks; do not invent a check solely for this activity.
8. Capture the default-branch protection/ruleset ID or URL and the effective CODEOWNERS evidence. Confirm that a non-owner can propose a pull request but cannot merge protected-agent changes without the required approval.

### Part C — Set the AI Controls configuration source

9. As the enterprise owner, go to **Enterprise settings → AI Controls → Agents**. In **Configuration source**, select the organization that contains the approved `.github-private` repository.
10. Save the change and capture the resulting **Configuration summary**. Record the source organization, repository, date, actor, source commit, and the organizations expected to receive the enterprise configuration.
11. If the summary does not show the expected source, stop. Correct the enterprise setting or source repository only through the approved change, then capture new evidence. A repository that exists but is not selected in AI Controls is not an active enterprise configuration source.

### Part D — Implement the enterprise custom agent

12. Create a pull request in the selected `.github-private` repository. Add `agents/agentic-devsecops.agent.md` at the repository root—enterprise custom agents use the root `agents` directory, not `.github/agents`.
13. Preserve the display name **Agentic DevSecOps**. Start with an explicit, least-privilege tool list and no MCP configuration, secrets, or plugin configuration. Use this approved baseline only after adapting the customer policy:

   ```markdown
   ---
   name: Agentic DevSecOps
   description: Reviews proposed changes for secure delivery practices and produces evidence-backed recommendations.
   tools: [read, search]
   disable-model-invocation: true
   ---

   # Agentic DevSecOps

   Review the supplied repository context and identify secure-delivery risks,
   missing tests, and evidence gaps. Explain recommendations and affected files.

   Do not execute commands, edit files, access secrets, add integrations, or
   approve exceptions. Escalate policy conflicts to the named customer owner.
   ```

14. Have the required Code Owners approve the pull request. Record the pull request URL, approving identity, merged commit SHA, agent filename, name, description, tool boundary, and any customer-approved deviations from the baseline.
15. After merge, refresh the enterprise AI Controls configuration summary and test the agent only in an approved, non-sensitive repository and supported client. Record the agent’s visibility/selection result, tested organization/repository, client, time, source SHA, and any limitation. Do not claim propagation from a merged pull request alone.

### Part E — Configure organization instructions and document precedence

16. At each in-scope organization, an organization owner opens **Settings → Copilot → Custom instructions** and adds short, broadly applicable instructions. Keep organization instructions separate from the enterprise agent prompt and from repository-specific implementation guidance. For example:

   ```text
   Follow approved secure-delivery standards and explain material security risks.
   Do not request, expose, or place secrets in code, logs, or examples.
   Escalate policy exceptions to the repository security owner; do not approve them.
   ```

17. Record the instruction text, organization, owner, save time, supported environments, and validation result. Organization custom instructions are currently supported for Copilot Chat, code review, and cloud agent on GitHub.com; record unsupported-client limitations rather than assuming universal propagation.
18. Record this explicit **custom-instruction precedence** for GitHub.com:

   1. Personal instructions
   2. Path-specific repository instructions (`.github/instructions/**/*.instructions.md`)
   3. Repository-wide instructions (`.github/copilot-instructions.md`)
   4. Agent instructions (for example, `AGENTS.md`)
   5. Organization custom instructions

   All relevant instruction sets are provided, but a higher item takes precedence when they conflict. The enterprise custom agent does not turn organization instructions into a highest-priority policy layer.

19. Also record **custom-agent duplicate-name precedence**: a repository-level agent overrides an organization-level agent, and an organization-level agent overrides an enterprise-level agent when their filenames conflict. Protect the `Agentic DevSecOps` filename and choose a unique name so a lower-level override cannot be mistaken for the enterprise agent.

### Part F — No-enterprise-access decision package

20. If enterprise access is unavailable, create an approval-ready decision package—not a completion claim. It must name the source organization, proposed `.github-private` visibility, CODEOWNERS team, ruleset requirements/bypass model, the AI Controls configuration-source change, the exact `Agentic DevSecOps` file, proposed organization instructions, test plan, rollback owner, and requested enterprise-owner decision.
21. Create an implementation pull request or reviewable patch against the customer-approved `.github-private` source when repository access is available. If it is not available, attach a patch with the intended `CODEOWNERS` and `agents/agentic-devsecops.agent.md` paths to the approval record. Mark it **pending enterprise application**.
22. Include dated evidence of the access limitation, stakeholder approval request, risk assessment, affected organizations, propagation checks to perform, and a revert plan. Do not create a similarly named repository and describe it as the AI Controls source.
23. Use the optional `ghec-ch34-enterprise-agent-configuration` fallback only as a private, namespaced decision-package workspace when the customer approves one. It is not `.github-private`, is never an AI Controls source, and cannot satisfy the enterprise implementation criteria.

### Part G — Change approval, propagation, and rollback

24. For every source change, use a pull request with the required Code Owner and change-record approval. Baseline the current source commit and configuration-summary evidence before merging.
25. Validate propagation after the approved merge using the designated supported client and non-sensitive test repository. Record expected versus actual agent availability/behavior, source SHA, test time, tester, organization, and evidence link. Investigate unexpected results before expanding scope.
26. Roll back by opening and approving a revert pull request to the last known-good source commit; do not directly overwrite protected files. Re-check the AI Controls configuration summary and repeat the supported-client validation. Record the revert SHA, propagation result, incident/change reference, owner, and next review date.
27. Update the existing customer governance register with all four controls, effective source/status, customer-approved path, objective evidence, owner, exception/rollback route, and next decision.

## Validation / Definition of Done

- [ ] The actual customer `.github-private` repository, source organization, CODEOWNERS, ruleset, default branch, required reviewers, and bypass model are evidenced.
- [ ] The enterprise owner selected the source organization under AI Controls → Agents → Configuration source and the Configuration summary confirms it.
- [ ] The protected source contains an approved enterprise agent named **Agentic DevSecOps** with a documented least-privilege tool boundary and no unapproved MCP, secret, managed-setting, or plugin configuration.
- [ ] Organization custom instructions are saved and evidenced separately for each intended organization.
- [ ] Both the custom-instruction precedence and lower-level custom-agent duplicate-name override behavior are documented and tested or recorded as a limitation.
- [ ] An approved supported-client, non-sensitive propagation test records source SHA, result, evidence, and owner.
- [ ] The change record has a baseline, approval, merge/source SHA, propagation evidence, revert procedure, rollback owner, and next review date.
- [ ] If enterprise access was unavailable, the customer has an approval-ready decision package and implementation PR/patch marked pending enterprise application—without a false completion claim.
- [ ] Managed settings and plugin standards remain explicitly out of scope and were not enabled.

## Reference links

- [Creating a `.github-private` repository](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/create-github-private-repo)
- [Preparing to use custom agents in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/prepare-for-custom-agents)
- [Creating custom agents for Copilot cloud agent](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents)
- [Adding organization custom instructions for GitHub Copilot](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
- [About customizing GitHub Copilot responses](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/prompting/response-customization)
- [Custom agents configuration reference](https://docs.github.com/en/enterprise-cloud@latest/copilot/reference/custom-agents-configuration)
