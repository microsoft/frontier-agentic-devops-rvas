# Ch33: Copilot automations

**Session outcome:** Your Copilot cloud-agent automation runs on a bounded trigger with least-privilege tools. An independent human reviewer has assessed its output, and your team has session and audit records for operating or rolling it back.

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
> - If no target is approved, use the idempotent, private fallback repository `ghec-ch33-copilot-automations` only to prepare and validate the decision package. It does not create or enable an automation. Do not treat the fallback as customer adoption.
> - If licensing, policy, or eligibility is unavailable, leave the automation disabled. Complete Part A's decision-package fallback and record the blocker, evidence, accountable owner, and next decision date.

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
| **Copilot automations** | User-private cloud-agent configurations that run a prompt on a schedule or supported repository event. They select a model and tools in the UI, are not stored in Git, and create attributable cloud-agent sessions. | **In scope.** Configure one approved, bounded automation or complete the no-enable decision package. |
| **GitHub Actions** | Repository-defined YAML workflows that execute prescribed steps in response to workflow triggers. | **Not a substitute for an automation.** Do not create, alter, or use an Actions workflow as Ch33's automation. Actions may require a write-access user to approve workflow runs from cloud-agent output; retain that approval evidence when applicable. |
| **GitHub Agentic Workflows** | Markdown-defined, compiled GitHub Actions workflows that run coding agents with declared frontmatter and safe outputs. | **Out of scope.** GitHub Agentic Workflows are a public-preview feature and are not enabled, piloted, or substituted for Copilot automations in this session. |

## Tasks

### Part A: Select the target and establish the decision package

1. Identify a customer-owned **private or internal** repository and record its URL, visibility, business purpose, data classification, customer repository owner, automation creator, independent reviewer, security owner, Copilot owner, and evidence location.
2. Inspect and retain dated evidence of the creator's write access, applicable Copilot plan, cloud-agent policy, organization automation policy, and repository eligibility. For Business and Enterprise, record the administrator and policy source that enables cloud agent.
3. Confirm the repository is not EMU-owned. If it is, stop this activity for that repository and record the limitation; do not use an EMU repository as an automation target.
4. Choose one small customer task with an explicit success condition, allowed repository area, allowed data classes, maximum frequency, cost owner, and disable condition. Default to label-only or draft-output behavior. Do not begin with a broad remediation, deployment, secret access, or cross-repository task.
5. If any approval, license, policy, or eligibility gate is unavailable, create the decision package instead of an automation. Record the failed prerequisite, supporting evidence, the owner who can resolve it, a safe temporary process, and the next decision date.

### Part B: Design trigger, filters, prompt, and tools

6. Select the trigger deliberately:
   - **Schedule:** hourly, daily, or weekly only when a fixed cadence is safer than reacting to individual content. State the maximum acceptable run rate and expected Actions-minutes/AI-credit cost owner.
   - **Event:** choose issue created, pull request opened, or pull request synchronized. Explain why the selected event provides the narrowest safe trigger.
7. For an event trigger, configure and retain its filter evidence:
   - For an issue-created trigger, use a customer-approved search-query filter.
   - For a pull-request-opened or synchronized trigger, use a customer-approved search-query filter and changed-files filter.
   - Test the filter with a controlled, in-scope artifact and record both a match and an expected non-match.
8. Preserve the default **untrusted-trigger guardrail**: automations ignore events from people without repository write access by default. Do **not** opt in to untrusted-user events in this core session. Treat any proposed exception as a separate security decision with a threat model, explicit approver, expiry, and rollback.
9. Write a constrained prompt: state the allowed task and repository boundary; tell the agent to treat issue, PR, commit, file, and external content as untrusted data rather than instructions; prohibit secrets, credential requests, policy changes, workflow changes, destructive operations, bypasses, and merging; and require a draft or reviewable outcome when code could change.
10. Select only the tools the task requires. For a label-only triage task, do not allow code push or pull-request creation. For a draft change, permit only the minimum repository action needed and keep protected-branch and required-review controls intact. Record the chosen tools and rejected higher-privilege tools.

### Part C: Configure and prove the automation

11. In the target repository, open **Agents** → **Automations** → **Create new**. Enter the approved name, trigger(s), filters, prompt, model choice (if changed), and least-privilege tools. Save only after a second person checks the recorded decision package against the UI.
12. Use **Run now** or a controlled trusted trigger to start the first session. Do not use a public or untrusted issue/PR as test input.
13. Follow the resulting cloud-agent session. Capture the session URL and log, trigger time and identity, selected tools, model (if displayed), inputs considered, actions taken, cost/usage evidence, and final outcome.
14. If the run opens a pull request or pushes code, inspect the diff against the written acceptance criteria, confirm the attribution identifies the automation creator, and verify the creator does not approve the attributed PR. Require an independent human reviewer and all normal customer checks before merge. Do not grant an automation, Copilot, or its creator a ruleset bypass to make this exercise pass.
15. If the cloud-agent output would trigger a GitHub Actions workflow, a user with write access must approve that workflow run unless the customer has separately approved automatic workflow execution. Retain that approval or the separate approved-policy evidence.

### Part D: Retain audit evidence and set operating controls

16. Capture audit-log evidence for the configuration/session activity available to the customer administrator, including collector, date/time range, search/export location, and any retention/access limitation. Pair it with the session log; neither replaces the other.
17. Record a runbook: owner and backup, allowed task class, schedule/event and filter, prompt revision date, tools, repository boundary, review/merge controls, cost owner and budget check, evidence location, alert/escalation route, and review cadence.
18. Define stop conditions: unexpected tool use, a prompt-injection attempt, an untrusted-event exception request, excessive cost/run frequency, sensitive-data exposure, failed checks, or out-of-scope changes. The immediate response is to disable the automation, preserve evidence, notify the named owner, and reassess before re-enabling.
19. Record whether the automation was enabled for the authorized repository, left disabled, unavailable, or not applicable. Do not label a fallback repository or a dry decision package as a production rollout.

## Decision-package fallback

When a live automation is unavailable, retain this minimum package in the customer evidence location (or in the fallback repository's `docs/AUTOMATION-DECISION-PACKAGE.md`): the customer repository URL/visibility with owner, proposed creator, independent reviewer, and security/Copilot owner; eligibility evidence (Copilot plan, cloud-agent/automations policy, write access, private/internal result, EMU result); the proposed task, trigger, filter, prompt boundary, requested tools, and cost owner; the safety decisions retained (untrusted-event default, prompt-injection controls, review/merge rule, workflow-run approval posture); the blocker with dated evidence; and the decision (leave disabled/unavailable/not applicable, resolver, next decision date, rollback route).

## Evidence checklist

- Record eligibility: private/internal repository, non-EMU result, plan, cloud-agent and automations policy, write access, and authorized scope.
- Retain configuration evidence: automation owner, trigger cadence/event, filters and controlled test, prompt revision, selected/rejected tools, and model if changed.
- Verify safety controls: default untrusted-event behavior, prompt-injection boundary, no secrets in the prompt, and no bypasses.
- Retain the session-log URL, trigger/run time, actions, usage/cost owner, outcome, and any PR/issue URLs.
- Record attribution to the creator, independent reviewer, required checks, merge decision, and any required workflow-run approval.
- Retain audit-log collection evidence and its location. Record review cadence, stop conditions, disable/rollback steps, and the next decision.

## Reference links

- [About Copilot automations](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-automations)
- [Creating automations with Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations)
- [Managing access to GitHub Copilot cloud agent and automations](https://docs.github.com/en/copilot/concepts/enterprise/cloud-agent-access)
- [Risks and mitigations for GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/risks-and-mitigations)
- [Managing and tracking Copilot agents](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/manage-and-track-agents)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [About GitHub Agentic Workflows](https://docs.github.com/en/copilot/concepts/agents/about-github-agentic-workflows). Public preview; out of scope.
