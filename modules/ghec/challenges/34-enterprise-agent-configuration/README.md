# Ch34: Enterprise agent configuration

Use this session after a repository pilot works and the approved agent must serve multiple organizations. Reuse Ch31's instructions and Ch32's review evidence. A single-repository team doesn't need it.

**Session outcome:** An enterprise custom agent comes from a protected `.github-private` source selected in AI Controls. You tested that a change propagates and that a revert rolls it back.

> [!IMPORTANT]
> **An authorized enterprise owner must select the configuration source** in AI Controls. Never claim the agent or source is active until the configuration summary shows it.

## Prerequisites

- An enterprise owner with access to **Enterprise settings → AI Controls → Agents**, and an organization that can own `.github-private`.
- Copilot Business or Copilot Enterprise for the intended organizations.
- A review team for the repository's protected paths, and an approver for rollback.

Organization custom instructions are a separate setting and don't change precedence. See [Ch31](../31-copilot-environment-instructions/README.md). Don't add tools, secrets, or MCP servers here. Managed settings and plugin standards are out of scope.

## Tasks

### Part A: Protect the source repository

1. Open **Enterprise settings → AI Controls → Agents** and note the current configuration source. Don't infer it from repository contents.
2. In the approved source organization, create `.github-private` if it doesn't exist, using your enterprise governance template or baseline.
3. Add root `CODEOWNERS` entries. Replace the team with your review team:

   ```text
   /agents/ @customer/enterprise-ai-controls
   /CODEOWNERS @customer/enterprise-ai-controls
   ```

4. Create an active default-branch ruleset that protects `/agents/` and `CODEOWNERS`. Require pull requests and Code Owner review, and restrict direct updates. Keep bypass actors few. Confirm a non-owner can open a PR but can't merge a protected change without approval.

### Part B: Select the source in AI Controls

5. As the enterprise owner, go to **Enterprise settings → AI Controls → Agents**. In **Configuration source**, select the organization that holds `.github-private`, then save.
6. Check the **Configuration summary** shows the expected organization and repository. If not, stop and fix the setting before going on.

### Part C: Add one enterprise agent

7. Open a pull request in `.github-private` that adds `agents/agentic-devsecops.agent.md`. Enterprise custom agents use the root `agents` directory, not `.github/agents`. Start from this least-privilege baseline and adapt it to your policy:

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

8. Get the Code Owner approval and merge. Keep the PR URL and merged SHA.
9. Refresh the configuration summary. In an approved, non-sensitive repository with a supported client, check that **Agentic DevSecOps** is visible and selectable. A merged PR alone doesn't prove propagation.

A repository-level agent with the same filename overrides an organization-level one, which overrides an enterprise-level one. Pick a unique name so nobody mistakes an override for the enterprise agent.

### Part D: Test change and rollback

10. Change the agent through a PR, for example tighten one sentence in the prompt. After the approved merge, repeat the check from step 9 and confirm the new behavior.
11. Roll back with a revert PR to the last known-good commit, approved like any other change. Don't overwrite protected files directly. Check the configuration summary and repeat the client check. Note the revert SHA in the change record.

**Blocked:** without enterprise-owner access or approval, stop and note the blocker in the adoption issue. The session isn't complete until the source is selected and the agent appears. Don't create a similarly named repository and call it the AI Controls source.

## Reference links

- [Creating a `.github-private` repository](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/create-github-private-repo)
- [Preparing to use custom agents in your enterprise](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-agents/prepare-for-custom-agents)
- [Creating custom agents for Copilot cloud agent](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/create-custom-agents)
- [Adding organization custom instructions for GitHub Copilot](https://docs.github.com/en/enterprise-cloud@latest/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
- [Custom agents configuration reference](https://docs.github.com/en/enterprise-cloud@latest/copilot/reference/custom-agents-configuration)
