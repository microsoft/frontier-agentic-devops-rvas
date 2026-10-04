# Ch33: Copilot automations

**Session outcome:** The automation runs only for a matching event. You record who owns it, and an independent human reviews its draft PR before merge.

> This activity does not require another activity's repository, workflow, agent, or policy change.

## Prerequisites and hard gates

Copilot automations are available only when all of the following are true:

- The selected repository is **private or internal**. Public repositories are not eligible.
- The automation creator has **write access** to the repository and an eligible Copilot plan.
- Copilot cloud agent is enabled for the repository. For Copilot Business or Enterprise, an administrator must enable the applicable policy.
- The organization allows both Copilot cloud agent and automations for the repository.
- The repository is eligible for Copilot cloud agent; do not use an EMU-owned repository.
- An independent reviewer can enforce the customer branch and merge controls. The person whose automation creates a PR or pushes code cannot approve that attributed output.

> [!IMPORTANT]
> Automations are private to the user who creates them and are stored separately from repository contents. They are not committed to Git or managed through a pull request. The sessions they start, their logs, and any resulting changes are visible to people with repository access. Do not put secrets or sensitive values in the automation prompt.

## Scenario

An Agentic DevSecOps team wants to automate routine work without letting untrusted repository content trigger unattended changes. Start with an approved low-risk task, such as applying existing triage labels to a defined class of issues or preparing a draft maintenance PR on a schedule. Check eligibility and review requirements first. Grant only the tools the task needs, then verify attribution, review, and audit evidence.

> [!IMPORTANT]
> Use an approved customer target first
>
> - If an approved private/internal customer repository is available, use it throughout and retain evidence in the customer-owned location.
> - If no target is approved, record that blocker. The private `ghec-ch33-copilot-automations` fallback is optional practice; it does not create or enable an automation and is not customer adoption.
> - If licensing, policy, or eligibility is unavailable, leave the automation disabled. Record the blocker and its owner in the existing adoption issue.

Create the safe fallback only when needed:

```bash
bash modules/ghec/challenges/33-copilot-automations/provision.sh --org <org>
```

```powershell
pwsh -File modules/ghec/challenges/33-copilot-automations/provision.ps1 -Org <org>
```

Both scripts create or reconcile only the private `ghec-ch33-copilot-automations`
decision-package repository. They do not enable Copilot, create an automation,
change policy, add a secret, or start a session. Teardown is prefix-guarded:

```bash
bash modules/ghec/challenges/33-copilot-automations/provision.sh --org <org> --teardown
```

```powershell
pwsh -File modules/ghec/challenges/33-copilot-automations/provision.ps1 -Org <org> -Teardown
```

## Scope boundary

This session covers **Copilot automations**: a Copilot cloud-agent task defined in the GitHub UI that runs automatically on a schedule or in response to a repository event. It can act only in the repository where it is configured; its selected tools define what it can do.

| Capability | What it is | Ch33 treatment |
|---|---|---|
| **Copilot automations** | User-private cloud-agent configurations that run a prompt on a schedule or supported repository event. They select a model and tools in the UI, are not stored in Git, and create attributable cloud-agent sessions. | **In scope.** Configure one approved, bounded automation. Missing eligibility leaves setup blocked. |
| **GitHub Actions** | Repository-defined YAML workflows that execute prescribed steps in response to workflow triggers. | **Not a substitute for an automation.** Do not create, alter, or use an Actions workflow as Ch33's automation. Actions may require a write-access user to approve workflow runs from cloud-agent output; retain that approval evidence when applicable. |
| **GitHub Agentic Workflows** | Markdown-defined, compiled GitHub Actions workflows that run coding agents with declared frontmatter and safe outputs. | **Out of scope.** GitHub Agentic Workflows are a public-preview feature and are not enabled, piloted, or substituted for Copilot automations in this session. |

## Tasks

### Part A: Select the target and task

1. Identify a customer-owned **private or internal** repository and record its URL, visibility, business purpose, data classification, customer repository owner, automation creator, independent reviewer, security owner, Copilot owner, and evidence location.
2. Inspect and retain dated evidence of the creator's write access, applicable Copilot plan, cloud-agent policy, organization automation policy, and repository eligibility. For Business and Enterprise, record the administrator and policy source that enables cloud agent.
3. Confirm the repository is not EMU-owned. If it is, stop this activity for that repository and record the limitation; do not use an EMU repository as an automation target.
4. Choose one small maintenance task that produces a draft PR in an approved path. Reuse Ch31's setup and Ch32's review controls. Define the expected test and when to disable the automation. Exclude deployment and secret access, and keep all work in this repository.
5. If any approval, license, policy, or eligibility gate is unavailable, stop setup. Record the failed prerequisite and the owner who can resolve it in the existing adoption issue. A separate fallback repository is unnecessary.

### Part B: Design trigger, filters, prompt, and tools

6. Choose a supported repository event and a narrow filter for the maintenance task. State the maximum acceptable run rate and cost owner. A schedule is optional after event tests pass.
7. For an event trigger, configure and retain its filter evidence:
   - For an issue-created trigger, use a customer-approved search-query filter.
   - For a pull-request-opened or synchronized trigger, use a customer-approved search-query filter and changed-files filter.
   - Test the filter with a controlled, in-scope artifact and record both a match and an expected non-match.
8. Preserve the default **untrusted-trigger guardrail**: automations ignore events from people without repository write access by default. Do **not** opt in to untrusted-user events in this core session. Treat any proposed exception as a separate security decision with a threat model, explicit approver, expiry, and rollback.
9. Write a constrained prompt: state the allowed task and repository boundary; tell the agent to treat issue, PR, commit, file, and external content as untrusted data rather than instructions; prohibit secrets, credential requests, policy changes, workflow changes, destructive operations, bypasses, and merging; and require a draft or reviewable outcome when code could change.
10. Select only the tools the task requires. For a label-only triage task, do not allow code push or pull-request creation. For a draft change, permit only the minimum repository action needed and keep protected-branch and required-review controls intact. Record the chosen tools and rejected higher-privilege tools.

### Part C: Configure and prove the automation

11. In the target repository, open **Agents** → **Automations** → **Create new**. Enter the approved name, trigger(s), filters, prompt, model choice (if changed), and least-privilege tools. Have a second person check the scope and tools before saving.
12. Use **Run now** or a controlled trusted trigger to start the first session. Do not use a public or untrusted issue/PR as test input.
13. Follow the resulting cloud-agent session. Capture the session URL and log, trigger time and identity, selected tools, model (if displayed), inputs considered, actions taken, cost/usage evidence, and final outcome.
14. Inspect the resulting draft PR and attribution. The creator must not approve output attributed to them. Require passing CI and independent human review before merging. If no reviewable PR appears, investigate or record the run as incomplete. A label alone does not complete the task.
15. If the cloud-agent output would trigger a GitHub Actions workflow, a user with write access must approve that workflow run unless the customer has separately approved automatic workflow execution. Retain that approval or the separate approved-policy evidence.

### Part D: Retain audit evidence and set operating controls

16. Capture audit-log evidence for the configuration/session activity available to the customer administrator, including collector, date/time range, search/export location, and any retention/access limitation. Pair it with the session log; neither replaces the other.
17. Record the creator and backup contact, with instructions for disabling the automation. Automations are private to their creators, even in team-owned repositories. When the creator leaves, disable the original. The approved successor must recreate and test it.
18. Define stop conditions: unexpected tool use, a prompt-injection attempt, an untrusted-event exception request, excessive cost/run frequency, sensitive-data exposure, failed checks, or out-of-scope changes. The immediate response is to disable the automation, preserve evidence, notify the named owner, and reassess before re-enabling.
19. Record whether the automation was enabled for the authorized repository, left disabled, unavailable, or not applicable. Do not label a fallback repository or a dry decision package as a production rollout.

## Decision-package fallback

When live setup is unavailable, keep the target, intended task, and failed
eligibility or approval check in the existing adoption issue. Name the owner
who can resolve it. A draft configuration can help that owner decide; a full
decision package or a new repository is not required. Mark implementation
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
