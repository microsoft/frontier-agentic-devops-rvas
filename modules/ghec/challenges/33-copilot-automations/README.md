# Ch33: Copilot automations

**Session outcome:** The automation runs only for a matching event. You record who owns it, and an independent human reviews its draft PR before merge.

> This session doesn't depend on any other session's repository, workflow, agent, or policy change.

## Prerequisites and hard gates

Copilot automations are available only if all of these are true:

- The selected repository is **private or internal**. Public repositories aren't eligible.
- The automation creator has **write access** to the repository and an eligible Copilot plan.
- Copilot cloud agent is enabled for the repository. For Copilot Business or Enterprise, an administrator must enable the applicable policy.
- The organization allows both Copilot cloud agent and automations for the repository.
- The repository is eligible for Copilot cloud agent. Don't use an EMU-owned repository.
- An independent reviewer can enforce the customer's branch and merge controls. The person whose automation creates a PR or pushes code can't approve that output.

> [!IMPORTANT]
> Automations are private to the user who creates them and are stored outside the repository. They aren't committed to Git or managed through a pull request. The sessions they start, their logs, and any resulting changes are visible to people with repository access. Never put secrets or sensitive values in the automation prompt.

## Scenario

An Agentic DevSecOps team wants to automate routine work without letting untrusted repository content trigger unattended changes. Start with an approved low-risk task, such as applying existing triage labels to a defined class of issues, or preparing a draft maintenance PR on a schedule. Check eligibility and review requirements first. Grant only the tools the task needs, then verify attribution, review, and audit evidence.

> [!IMPORTANT]
> Use an approved customer target first
>
> - If you have an approved private or internal customer repository, use it throughout and keep the evidence in the customer's location.
> - If no target is approved, record that blocker. The private `ghec-ch33-copilot-automations` fallback is optional practice. It doesn't create or enable an automation and isn't customer adoption.
> - If licensing, policy, or eligibility isn't available, leave the automation disabled. Record the blocker and its owner in the adoption issue.

Create the fallback only if you need it:

```bash
bash modules/ghec/challenges/33-copilot-automations/provision.sh --org <org>
```

```powershell
pwsh -File modules/ghec/challenges/33-copilot-automations/provision.ps1 -Org <org>
```

Both scripts create or reconcile only the private `ghec-ch33-copilot-automations`
decision-package repository. They don't enable Copilot, create an automation,
change policy, add a secret, or start a session. Teardown is prefix-guarded:

```bash
bash modules/ghec/challenges/33-copilot-automations/provision.sh --org <org> --teardown
```

```powershell
pwsh -File modules/ghec/challenges/33-copilot-automations/provision.ps1 -Org <org> -Teardown
```

## Scope boundary

This session covers **Copilot automations**: Copilot cloud agent tasks defined in the GitHub UI that run on a schedule or when a repository event fires. An automation acts only in the repository where you configure it, and its selected tools define what it can do.

| Capability | What it is | Ch33 treatment |
|---|---|---|
| **Copilot automations** | User-private cloud-agent configurations that run a prompt on a schedule or supported repository event. They select a model and tools in the UI, aren't stored in Git, and create cloud agent sessions you can attribute. | **In scope.** Configure one approved, bounded automation. If you're not eligible, setup is blocked. |
| **GitHub Actions** | Repository-defined YAML workflows that execute prescribed steps in response to workflow triggers. | **Not a substitute for an automation.** Don't create, change, or use an Actions workflow as the automation. Actions may require a user with write access to approve workflow runs from cloud agent output. Keep that approval as evidence. |
| **GitHub Agentic Workflows** | Markdown-defined, compiled GitHub Actions workflows that run coding agents with declared frontmatter and safe outputs. | **Out of scope.** GitHub Agentic Workflows are in public preview. Don't enable them, pilot them, or use them in place of Copilot automations here. |

## Tasks

### Part A: Select the target and task

1. Pick a customer-owned **private or internal** repository. Record its URL, visibility, business purpose, data classification, repository owner, automation creator, independent reviewer, security owner, Copilot owner, and evidence location.
2. Collect dated evidence of the creator's write access, Copilot plan, cloud agent policy, organization automation policy, and repository eligibility. For Business and Enterprise, record the administrator and the policy that enables cloud agent.
3. Confirm the repository isn't EMU-owned. If it is, stop for that repository and record the limitation. An EMU repository can't be an automation target.
4. Choose one small maintenance task that produces a draft PR in an approved path. Reuse Ch31's setup and Ch32's review controls. Define the expected test and when to disable the automation. Exclude deployment and secret access, and keep all work in this repository.
5. If an approval, license, policy, or eligibility gate is missing, stop setup. Record the failed prerequisite and the owner who can resolve it in the adoption issue. You don't need a separate fallback repository.

### Part B: Design trigger, filters, prompt, and tools

6. Choose a supported repository event and a narrow filter for the maintenance task. State the maximum run rate and the cost owner. Add a schedule only after the event tests pass.
7. For an event trigger, configure the filters and keep the test results:
   - For an issue-created trigger, use a customer-approved search-query filter.
   - For a pull-request-opened or synchronized trigger, use a customer-approved search-query filter and changed-files filter.
   - Test the filter with an approved issue or PR and record both a match and an expected non-match.
8. Keep the default **untrusted-trigger guardrail**: automations ignore events from people without repository write access. Do **not** opt in to untrusted-user events in this session. Treat any proposed exception as a separate security decision with a threat model, an explicit approver, an expiry, and a rollback.
9. Write a tight prompt. State the allowed task and the repository boundary. Tell the agent to treat issue, PR, commit, file, and external content as untrusted data, not instructions. Prohibit secrets, credential requests, policy changes, workflow changes, destructive operations, bypasses, and merging. If code could change, require a draft or otherwise reviewable result.
10. Select only the tools the task needs. For label-only triage, don't allow code push or pull request creation. For a draft change, allow only the minimum repository action and keep protected-branch and required-review controls intact. Record the tools you chose and the higher-privilege tools you rejected.

### Part C: Configure and prove the automation

11. In the target repository, open **Agents** → **Automations** → **Create new**. Enter the approved name, triggers, filters, prompt, model (if changed), and least-privilege tools. Have a second person check the scope and tools before you save.
12. Use **Run now** or a controlled, trusted trigger to start the first session. Never use a public or untrusted issue or PR as test input.
13. Follow the resulting cloud agent session. Capture the session URL and log, trigger time and identity, selected tools, model (if shown), inputs considered, actions taken, cost and usage evidence, and the final outcome.
14. Inspect the draft PR and its attribution. The creator can't approve output attributed to them. Require passing CI and an independent human review before merging. If no reviewable PR appears, investigate or record the run as incomplete. A label alone doesn't complete the task.
15. If the cloud agent's output triggers a GitHub Actions workflow, a user with write access must approve that run, unless the customer separately approved automatic workflow runs. Keep that approval, or the evidence of the approved policy.

### Part D: Retain audit evidence and set operating controls

16. Capture audit log evidence for the configuration and session activity the customer administrator can see: who collected it, the date and time range, where the search or export lives, and any retention or access limit. Pair it with the session log. Neither replaces the other.
17. Record the creator and backup contact, with instructions for disabling the automation. Automations are private to their creators, even in team-owned repositories. When the creator leaves, disable the original. The approved successor recreates and tests it.
18. Define stop conditions: unexpected tool use, a prompt injection attempt, a request for an untrusted-event exception, excessive cost or run frequency, sensitive-data exposure, failed checks, or out-of-scope changes. When one hits, disable the automation, preserve the evidence, notify the named owner, and reassess before re-enabling.
19. Record whether the automation was enabled for the authorized repository, left disabled, unavailable, or not applicable. A fallback repository or draft decision package isn't a production rollout.

## Decision-package fallback

If live setup isn't possible, keep the target, the intended task, and the failed
eligibility or approval check in the adoption issue. Name the owner
who can resolve it. A draft configuration can help that owner decide. You don't need a full
decision package or a new repository. Mark implementation
**blocked / not tested**.

Keep the reviewed draft PR and both event results. The non-matching event must not start a session.

## Reference links

- [About Copilot automations](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-automations)
- [Creating automations with Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations)
- [Managing access to GitHub Copilot cloud agent and automations](https://docs.github.com/en/copilot/concepts/enterprise/cloud-agent-access)
- [Risks and mitigations for GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/risks-and-mitigations)
- [Managing and tracking Copilot agents](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/manage-and-track-agents)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [About GitHub Agentic Workflows](https://docs.github.com/en/copilot/concepts/agents/about-github-agentic-workflows). Public preview; out of scope.
