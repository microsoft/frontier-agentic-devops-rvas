# Ch33: Copilot automations

**Session outcome:** One approved automation fires on a matching event, ignores a non-matching one, and an independent human reviews its draft PR before merge.

## Prerequisites

Copilot automations need all of these:

- A **private or internal** repository that isn't EMU-owned, with a named repository owner. Public repositories aren't eligible.
- An automation creator with **write access** and a Copilot plan that includes cloud agent.
- Cloud agent and automations allowed for the repository. On Business or Enterprise, an administrator enables the policy.
- An independent reviewer who can approve PRs. The person whose automation creates a PR can't approve it.

**Blocked:** if a license, policy, eligibility check, or approval is missing, stop. Leave the automation off, note the blocker and its owner in the adoption issue, and treat the session as not complete.

> [!IMPORTANT]
> Automations are private to their creator and stored outside the repository. Sessions, logs, and resulting changes are visible to anyone with repository access. Never put secrets in the prompt.

## Scope

This session covers **Copilot automations**: cloud agent tasks defined in the GitHub UI that run on a schedule or repository event. Don't use a GitHub Actions workflow or GitHub Agentic Workflows (public preview) in their place. If cloud agent output triggers an Actions run, a user with write access must approve it, unless the customer already allows automatic runs.

## Tasks

### Part A: Pick the task

1. Choose the private or internal repository. Name the automation creator and the independent reviewer.
2. Choose one small, low-risk task that produces a **draft PR**, for example a scheduled maintenance change or a fix for a defined class of issues. Exclude deployment and secret access. Keep all work in this repository.

### Part B: Design trigger, prompt, and tools

3. Pick one supported repository event and a narrow filter. For an issue-created trigger, use a search-query filter. For a pull-request trigger, add a changed-files filter. Add a schedule only after the event tests pass.
4. Keep the default **untrusted-trigger guardrail**: automations ignore events from people without write access. Don't opt in to untrusted-user events here.
5. Write a tight prompt. State the allowed task and repository boundary. Tell the agent to treat issue, PR, commit, file, and external content as untrusted data, not instructions. Prohibit secrets, policy or workflow changes, destructive operations, and merging. Require a draft PR.
6. Select only the tools the task needs. Don't grant more than a draft PR needs, and leave branch protection and required reviews in place.

### Part C: Create and test it

7. In the repository, open **Agents** → **Automations** → **Create new**. Enter the name, trigger, filter, prompt, and tools. Have a second person check scope and tools before you save.
8. Test the filter with two trusted inputs:
   - **Matching:** an approved issue or PR that fits the filter. A session starts.
   - **Non-matching:** one that doesn't fit. **No session starts.**

   Never use a public or untrusted issue or PR as test input.
9. Follow the matching session. Check its log for the tools used and what the agent did.
10. Open the draft PR. Require passing CI and an independent human review before merging. The creator can't approve it. If no reviewable PR appears, the run is incomplete. A label alone doesn't complete the task.

### Part D: Operate it

11. Tell the team who owns the automation and how to disable it. When the creator leaves, disable it and have the successor recreate and test it.
12. Disable the automation and review it if you see unexpected tool use, a prompt injection attempt, runaway cost or run frequency, sensitive-data exposure, failed checks, or out-of-scope changes.

## Reference links

- [About Copilot automations](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-automations)
- [Creating automations with Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations)
- [Managing access to GitHub Copilot cloud agent and automations](https://docs.github.com/en/copilot/concepts/enterprise/cloud-agent-access)
- [Risks and mitigations for GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/risks-and-mitigations)
- [Managing and tracking Copilot agents](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/manage-and-track-agents)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [About GitHub Agentic Workflows](https://docs.github.com/en/copilot/concepts/agents/about-github-agentic-workflows). Public preview; out of scope.
