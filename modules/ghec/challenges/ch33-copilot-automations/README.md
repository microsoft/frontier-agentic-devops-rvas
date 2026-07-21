# Ch33 — Copilot Automations

> Deliver one customer-owned Copilot cloud-agent automation with a bounded trigger, least-privilege tools, independent review, and durable session and audit evidence.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Advanced |
| Duration | ~4 hrs, multi-session |
| Minimum input | Customer-approved private or internal repository; a licensed, eligible automation creator; an independent reviewer; and named Copilot, security, repository, and audit-evidence owners |
| App | none |
| EMU compatible | no — Copilot cloud agent is not available on EMU-owned repositories |

## Customer delivery target

- **Customer objective:** safely automate one repetitive repository task without converting an untrusted event into an unreviewed code change.
- **Customer-tenant target:** one approved Copilot automation in a private or internal customer repository, its evidence package, and its operating/disable decision.
- **Approval and safety boundary:** default to **inspect-and-propose** until the customer repository owner, Copilot owner, and security owner approve the target, prompt, tools, trigger, filters, budget owner, and review path. Do not broaden repository access, enable a preview capability, grant bypasses, or include secrets in a prompt.
- **Records to keep:** eligibility and policy evidence; automation owner; private/internal repository evidence; trigger and filter configuration; prompt and selected tools; session-log URL; outcome/PR URL; independent-review evidence; audit-log evidence; costs; and disable/rollback path.
- **Adoption owner / handover:** the automation creator owns operation and cost; the repository owner owns repository scope and merge controls; the security owner owns the untrusted-trigger and prompt-injection decision.
- **Next action and owner:** approve one narrowly bounded automation, retain the decision package without enablement, or schedule a licensing/policy decision with its owner and date.

> Independent by design. This core activity stands alone. It does not require another activity's repository, workflow, agent, or policy change.

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

An **Agentic DevSecOps** team wants to reduce routine repository work without allowing arbitrary issues, pull requests, or natural-language content to cause unattended changes. Start with an approved low-risk task, such as applying existing triage labels to a defined class of issues or preparing a draft, reviewable maintenance pull request on a schedule. Establish the eligibility and review boundary first; then configure the smallest useful tool set and prove that the result is attributable, reviewable, and auditable.

> [!IMPORTANT]
> Use an approved customer target first
>
> - **Have an approved private/internal customer repository?** Use it throughout this guide and retain evidence in the customer-owned evidence location.
> - **No approved target yet?** Use the idempotent, private fallback repository `ghec-ch33-copilot-automations` only to prepare and validate the decision package. It deliberately does **not** create or enable an automation. Do not treat that fallback as customer adoption.
> - **Licensing, policy, or eligibility unavailable?** Do not enable an automation or simulate success. Complete the decision-package fallback in Part A and record the blocker, evidence, accountable owner, and next decision date.

Create the safe fallback only when needed:

```bash
bash modules/ghec/challenges/ch33-copilot-automations/provision.sh --org <org>
```

```powershell
pwsh -File modules/ghec/challenges/ch33-copilot-automations/provision.ps1 -Org <org>
```

Both scripts create or reconcile only the private `ghec-ch33-copilot-automations`
decision-package repository. They do not enable Copilot, create an automation,
change policy, add a secret, or start a session. Teardown is prefix-guarded:

```bash
bash modules/ghec/challenges/ch33-copilot-automations/provision.sh --org <org> --teardown
```

```powershell
pwsh -File modules/ghec/challenges/ch33-copilot-automations/provision.ps1 -Org <org> -Teardown
```

## Scope boundary

This session covers **Copilot automations**: a Copilot cloud-agent task defined in the GitHub UI that runs automatically on a schedule or in response to a repository event. It can act only in the repository where it is configured; its selected tools define what it can do.

Record `COP-AUTOMATIONS` in the customer governance register with the effective policy, trigger and tool boundary, session and audit evidence, accountable owner, review cadence, and disable path.

| Capability | What it is | Ch33 treatment |
|---|---|---|
| **Copilot automations** | User-private cloud-agent configurations that run a prompt on a schedule or supported repository event. They select a model and tools in the UI, are not stored in Git, and create attributable cloud-agent sessions. | **In scope.** Configure one approved, bounded automation or complete the no-enable decision package. |
| **GitHub Actions** | Repository-defined YAML workflows that execute prescribed steps in response to workflow triggers. | **Not a substitute for an automation.** Do not create, alter, or use an Actions workflow as Ch33's automation. Actions may require a write-access user to approve workflow runs from cloud-agent output; retain that approval evidence when applicable. |
| **GitHub Agentic Workflows** | Markdown-defined, compiled GitHub Actions workflows that run coding agents with declared frontmatter and safe outputs. | **Out of scope.** GitHub Agentic Workflows are a public-preview feature and are not enabled, piloted, or substituted for Copilot automations in this session. |

## Tasks

### Part A — Select the target and establish the decision package

1. Identify a customer-owned **private or internal** repository and record its URL, visibility, business purpose, data classification, customer repository owner, automation creator, independent reviewer, security owner, Copilot owner, and evidence location.
2. Inspect and retain dated evidence of the creator's write access, applicable Copilot plan, cloud-agent policy, organization automation policy, and repository eligibility. For Business and Enterprise, record the administrator and policy source that enables cloud agent.
3. Confirm the repository is not EMU-owned. If it is, stop this activity for that repository and record the limitation; do not use an EMU repository as an automation target.
4. Choose one small customer task with an explicit success condition, allowed repository area, allowed data classes, maximum frequency, cost owner, and disable condition. Default to label-only or draft-output behavior. Do not begin with a broad remediation, deployment, secret access, or cross-repository task.
5. If any approval, license, policy, or eligibility gate is unavailable, create the decision package instead of an automation. Record the failed prerequisite, supporting evidence, the owner who can resolve it, a safe temporary process, and the next decision date.

### Part B — Design trigger, filters, prompt, and tools

6. Select the trigger deliberately:
   - **Schedule:** hourly, daily, or weekly only when a fixed cadence is safer than reacting to individual content. State the maximum acceptable run rate and expected Actions-minutes/AI-credit cost owner.
   - **Event:** choose one supported event—issue created, pull request opened, or pull request synchronized—and state why that event is the smallest safe source.
7. For an event trigger, configure and retain its filter evidence:
   - For an issue-created trigger, use a customer-approved search-query filter.
   - For a pull-request-opened or synchronized trigger, use a customer-approved search-query filter and changed-files filter.
   - Test the filter with a controlled, in-scope artifact and record both a match and an expected non-match.
8. Preserve the default **untrusted-trigger guardrail**: automations ignore events from people without repository write access by default. Do **not** opt in to untrusted-user events in this core session. Treat any proposed exception as a separate security decision with a threat model, explicit approver, expiry, and rollback.
9. Write a constrained prompt: state the allowed task and repository boundary; tell the agent to treat issue, PR, commit, file, and external content as untrusted data rather than instructions; prohibit secrets, credential requests, policy changes, workflow changes, destructive operations, bypasses, and merging; and require a draft or reviewable outcome when code could change.
10. Select only the tools the task requires. For a label-only triage task, do not allow code push or pull-request creation. For a draft change, permit only the minimum repository action needed and keep protected-branch and required-review controls intact. Record the chosen tools and rejected higher-privilege tools.

### Part C — Configure and prove the automation

11. In the target repository, open **Agents** → **Automations** → **Create new**. Enter the approved name, trigger(s), filters, prompt, model choice (if changed), and least-privilege tools. Save only after a second person checks the recorded decision package against the UI.
12. Use **Run now** or a controlled trusted trigger to start the first session. Do not use a public or untrusted issue/PR as test input.
13. Follow the resulting cloud-agent session. Capture the session URL and log, trigger time and identity, selected tools, model (if displayed), inputs considered, actions taken, cost/usage evidence, and final outcome.
14. If the run opens a pull request or pushes code, inspect the diff against the written acceptance criteria, confirm the attribution identifies the automation creator, and verify the creator does not approve the attributed PR. Require an independent human reviewer and all normal customer checks before merge. Do not grant an automation, Copilot, or its creator a ruleset bypass to make this exercise pass.
15. If the cloud-agent output would trigger a GitHub Actions workflow, a user with write access must approve that workflow run unless the customer has separately approved automatic workflow execution. Retain that approval or the separate approved-policy evidence.

### Part D — Retain audit evidence and set operating controls

16. Capture audit-log evidence for the configuration/session activity available to the customer administrator, including collector, date/time range, search/export location, and any retention/access limitation. Pair it with the session log; neither replaces the other.
17. Record a runbook: owner and backup, allowed task class, schedule/event and filter, prompt revision date, tools, repository boundary, review/merge controls, cost owner and budget check, evidence location, alert/escalation route, and review cadence.
18. Define stop conditions: unexpected tool use, a prompt-injection attempt, an untrusted-event exception request, excessive cost/run frequency, sensitive-data exposure, failed checks, or out-of-scope changes. The immediate response is to disable the automation, preserve evidence, notify the named owner, and reassess before re-enabling.
19. Publish the decision package and adoption decision. Mark the result `approved pilot`, `inspect-and-propose`, `unavailable`, or `not applicable`; do not label a fallback repository or a dry decision package as a production rollout.

## Decision-package fallback

When a live automation is unavailable, retain this minimum package in the customer evidence location (or in the fallback repository's `docs/AUTOMATION-DECISION-PACKAGE.md`):

| Field | Record |
|---|---|
| Target and owner | Customer repository URL/visibility, repository owner, proposed creator, independent reviewer, security/Copilot owner |
| Eligibility evidence | Copilot plan, cloud-agent policy, automations policy, write access, private/internal evidence, EMU result |
| Proposed design | Task, schedule/event trigger, filter, prompt boundary, requested tools, data classification, cost owner |
| Safety decisions | Untrusted-event default retained, prompt-injection controls, review/merge rule, workflow-run approval posture |
| Blocker | Licensing, policy, authority, eligibility, or customer approval gap with dated evidence |
| Decision | `inspect-and-propose`, `unavailable`, or `not applicable`; resolver, next decision date, and rollback/disable route |

## Evidence checklist

| Evidence | Minimum content |
|---|---|
| Eligibility | Private/internal repository, non-EMU result, plan, cloud-agent and automations policy, write access, authorized scope |
| Configuration | Automation owner, trigger cadence/event, filters and controlled test, prompt revision, selected/rejected tools, model if changed |
| Safety | Default untrusted-event behavior retained, prompt-injection boundary, no secrets in prompt, no bypasses |
| Session | Session-log URL, trigger/run time, actions, usage/cost owner, outcome, and PR/issue URLs if created |
| Review | Attribution to creator, independent-review identity, required checks, merge decision, workflow-run approval where applicable |
| Audit and operations | Audit-log collection evidence, evidence location, review cadence, stop conditions, disable/rollback and next decision |

## Validation / Definition of Done

- [ ] An approved customer **private or internal**, non-EMU target, named owners, data boundary, and evidence location were recorded before configuration.
- [ ] Licensing, write access, cloud-agent policy, and automations policy were evidenced; unavailable conditions use the decision-package fallback and do not enable an automation.
- [ ] One approved automation uses a scheduled or supported event trigger; event-trigger filters have controlled match/non-match evidence.
- [ ] The default guardrail for events from users without write access remains enabled; the prompt explicitly treats repository and event content as untrusted data.
- [ ] The selected tools are least privilege for the approved task, with no unnecessary push, pull-request, secret, bypass, or destructive capability.
- [ ] A controlled **Run now** or trusted trigger produced session evidence and a reviewed outcome.
- [ ] Any automation-attributed PR/code outcome was independently reviewed; its creator did not approve it, and normal protected-branch controls remained in force.
- [ ] Session-log and audit-log evidence, operating owner, cost owner, review cadence, stop conditions, and disable/rollback route are retained.
- [ ] GitHub Actions and GitHub Agentic Workflows were not substituted for this activity; public-preview Agentic Workflows remain out of scope.
- [ ] Adoption handover records the customer decision, owner, next action, and target date.

## Reference links

- [About Copilot automations](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-automations)
- [Creating automations with Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-automations)
- [Managing access to GitHub Copilot cloud agent and automations](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/access-management)
- [Risks and mitigations for GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/risks-and-mitigations)
- [Managing and tracking Copilot agents](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/manage-and-track-agents)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [About GitHub Agentic Workflows — public preview, out of scope](https://docs.github.com/en/copilot/concepts/agents/about-github-agentic-workflows)
