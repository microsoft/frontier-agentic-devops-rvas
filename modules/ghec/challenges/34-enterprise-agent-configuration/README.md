# Ch34: Enterprise agent configuration

Use this session only after a repository pilot works and the approved agent must serve multiple organizations. Reuse Ch31's instructions and Ch32's review evidence. A single-repository team doesn't need enterprise configuration.

**Session outcome:** Your enterprise custom agent uses a protected `.github-private` configuration source, and you tested instruction propagation and rollback. Without enterprise-owner access, implementation is blocked.

> [!IMPORTANT]
> **An authorized enterprise owner must select the configuration source.** They create or pick the real `.github-private` repository and set it in AI Controls. If you don't have enterprise access, record the blocker as described in [Part F](#part-f-no-enterprise-access-decision-package). Never claim the enterprise agent or configuration source is active.

## Prerequisites

- A named enterprise owner with access to **Enterprise settings → AI Controls → Agents**, and a named organization that can own the enterprise configuration repository.
- Copilot Business or Copilot Enterprise availability for the intended organizations. Record availability and supported-client limits before testing.
- Named enterprise AI-controls, security, platform, organization-policy, and rollback approvers.
- A customer change record and non-secret evidence location.
- A review team or named maintainers for the `.github-private` repository.

## Scope and guardrails

The enterprise agent source and organization custom instructions are separate settings. Organization instructions aren't enterprise policy, and an enterprise custom agent doesn't change instruction precedence. Don't broaden agent tools, add secrets, enable MCP servers, or change unrelated Copilot policy in this session.

**Out of scope:** managed settings and plugin standards. Any preview work on them needs its own availability check, approval, change control, and rollback plan.

## Tasks

### Part A: Authorize the target and record the baseline

1. Record the customer enterprise, source organization, affected organizations, Copilot plan and availability, supported clients, change ticket, evidence location, approvers, and rollback owner.
2. Open **Enterprise settings → AI Controls → Agents**. Capture a dated, non-secret screenshot or export of the current configuration source and configuration summary. If no enterprise owner can inspect it, record that limit. Don't infer the source from repository contents.
3. Pick the customer organization that will own the enterprise source. Confirm that creating or changing its `.github-private` repository is approved, and that its default branch, visibility, maintainers, and retention meet customer policy.
4. Leave the setting as it is until the enterprise owner authorizes the source and the change.

### Part B: Create and protect the enterprise source

5. In the approved source organization, create `.github-private` if it doesn't exist. Use the enterprise governance template or an approved customer baseline. This repository is an enterprise governance artifact, not a `ghec-ch34-*` fallback resource.
6. Add root `CODEOWNERS` entries that require the enterprise AI controls reviewers for `/agents/` and `/CODEOWNERS`. Replace the team in this example with the customer's review team:

   ```text
   /agents/ @customer/enterprise-ai-controls
   /CODEOWNERS @customer/enterprise-ai-controls
   ```

7. Create an active ruleset for the default branch that protects the agent paths and `CODEOWNERS`. Require pull requests and Code Owner review, restrict direct updates, and record the bypass actors (keep them few), the justification, and the audit route. Use the customer's normal required checks. Don't invent a check for this session.
8. Capture the ruleset ID or URL for the default branch and the effective `CODEOWNERS` evidence. Confirm that a non-owner can propose a pull request but can't merge changes to protected agent files without the required approval.

### Part C: Set the AI Controls configuration source

9. As the enterprise owner, go to **Enterprise settings → AI Controls → Agents**. In **Configuration source**, select the organization that contains the approved `.github-private` repository.
10. Save the change and capture the resulting **Configuration summary**. Record the source organization, repository, date, actor, source commit, and the organizations expected to receive the enterprise configuration.
11. If the summary doesn't show the expected source, stop. Fix the enterprise setting or source repository only through the approved change, then capture new evidence. The source is active only once you select it in AI Controls.

### Part D: Implement the enterprise custom agent

12. Create a pull request in the selected `.github-private` repository. Add `agents/agentic-devsecops.agent.md` in the root `agents` directory. Enterprise custom agents don't use `.github/agents`.
13. Keep the display name **Agentic DevSecOps**. Start with an explicit, least-privilege tool list and no MCP configuration, secrets, or plugin configuration. Adapt this baseline to the customer policy before using it:

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

14. Have the required Code Owners approve the pull request. Record the pull request URL, approver, merged commit SHA, agent filename, name, description, tool boundary, and any customer-approved deviations from the baseline.
15. After the merge, refresh the enterprise AI Controls configuration summary and test the agent in an approved, non-sensitive repository with a supported client. Record whether the agent is visible and selectable, the organization and repository, client, time, source SHA, and any limitation. A merged pull request alone doesn't prove propagation.

### Part E: Configure organization instructions and document precedence

16. Reuse the approved organization instructions from Ch31. Change them, with the organization owner, only if they don't meet a cross-organization need. Keep them separate from the enterprise agent prompt. For example:

   ```text
   Follow approved secure-delivery standards and explain material security risks.
   Do not request, expose, or place secrets in code, logs, or examples.
   Escalate policy exceptions to the repository security owner; do not approve them.
   ```

17. Record the instruction text, organization, owner, save time, supported environments, and validation result. Organization custom instructions currently work in Copilot Chat, code review, and cloud agent on GitHub.com. Record the clients that don't support them instead of assuming they apply everywhere.
18. Record this **custom-instruction precedence** for GitHub.com:

   1. Personal instructions
   2. Path-specific repository instructions (`.github/instructions/**/*.instructions.md`)
   3. Repository-wide instructions (`.github/copilot-instructions.md`)
   4. Agent instructions (for example, `AGENTS.md`)
   5. Organization custom instructions

   Copilot gets all the relevant instruction sets, and when they conflict, the higher item wins. An enterprise custom agent doesn't make organization instructions the top policy layer.

19. Also record **custom agent duplicate-name precedence**: when filenames conflict, a repository-level agent overrides an organization-level agent, which overrides an enterprise-level agent. Protect the `Agentic DevSecOps` filename and pick a unique name, so nobody mistakes a lower-level override for the enterprise agent.

### Part F: No-enterprise-access decision package

20. If you don't have enterprise access, record the proposed source, the intended agent, and the owner approval you need in the adoption issue. Mark implementation **blocked / not tested**.
21. If a draft helps the owner approve, prepare a PR or patch with the intended `CODEOWNERS` and `agents/agentic-devsecops.agent.md` paths. Mark it **pending enterprise application**. A draft is optional and doesn't prove rollout.
22. Keep the no-access result with the owner request. Don't create a similarly named repository and call it the AI Controls source.
23. You don't need a separate fallback workspace. The optional `ghec-ch34-enterprise-agent-configuration` workspace is practice only, and is never an AI Controls source.

### Part G: Change approval, propagation, and rollback

24. Make every source change through a pull request with the required Code Owner and change-record approval. Record the current source commit and configuration summary before merging.
25. After the approved merge, validate propagation with the supported client and a non-sensitive test repository. Record expected versus actual agent availability and behavior, source SHA, test time, tester, organization, and evidence link. Investigate unexpected results before expanding scope.
26. To roll back, open and approve a revert pull request to the last known-good source commit. Don't overwrite protected files directly. Re-check the AI Controls configuration summary and repeat the supported-client validation. Record the revert SHA, propagation result, incident or change reference, owner, and next review date.

## Reference links

- [Creating a `.github-private` repository](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/create-github-private-repo)
- [Preparing to use custom agents in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/prepare-for-custom-agents)
- [Creating custom agents for Copilot cloud agent](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents)
- [Adding organization custom instructions for GitHub Copilot](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
- [About customizing GitHub Copilot responses](https://docs.github.com/en/enterprise-cloud@latest/copilot/concepts/prompting/response-customization)
- [Custom agents configuration reference](https://docs.github.com/en/enterprise-cloud@latest/copilot/reference/custom-agents-configuration)
