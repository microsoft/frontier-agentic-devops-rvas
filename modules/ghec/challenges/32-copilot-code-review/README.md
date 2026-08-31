# Ch32 — Copilot Code Review

> Deliver an evidence-backed Copilot code review operating model: manual review on a real pull request, a bounded decision on automatic review, and human-owned merge controls.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Intermediate |
| Duration | 180 min |
| Minimum input | An organization, a named repository owner, and effective Copilot code review availability |
| App | none |
| EMU compatible | yes — confirm the effective policy and repository eligibility |

> [!IMPORTANT]
> Copilot leaves a **Comment** review. It does not approve, request changes, satisfy a required approval, or block a merge. Human reviewers and existing `CODEOWNERS` / ruleset controls remain the merge decision.

## Prerequisites and availability decision

1. Select an approved customer repository **before** using a sample. Record its repository owner, human-review owners, `CODEOWNERS` coverage, data classification, expected PR volume, and approving customer owner.
2. Inspect the effective enterprise and organization Copilot policy. Record whether Copilot code review is enabled, who can request it, plan/licensing or AI-credit conditions, and any repository exclusions.
3. Confirm that Actions/runner, network, and cost owners accept the environment used for agentic review capabilities. A failed or unavailable Actions capability must be recorded; it is not a reason to weaken human review gates.
4. If the customer repository or Copilot code review is unavailable, do **not** enable a workaround. Use the decision-package fallback below: record the unavailable condition, evidence, risk owner, proposed scope, rollback, and review date.

## Safe fallback repository

Use this only when an approved customer target is not available:

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch32 --org <org>
```

```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch32 --org <org>
```

The fallback is intentionally isolated and namespaced `ghec-ch32-*`. It creates `ghec-ch32-copilot-code-review`, a small review-candidate PR, repository-wide Copilot instructions, and a decision-package template. It creates **no** Copilot policy, ruleset, `CODEOWNERS` rule, or automatic review setting. Re-running is idempotent; teardown must remain prefix-guarded.

> **Integration note:** the shared setup dispatcher resolves the provisioners in this activity directory. Use the customer target first; the fallback remains only a safe place to prepare evidence and a decision package.

## Tasks

### Part A — Establish the review boundary and evidence baseline

1. Export or screenshot the effective Copilot policy and the repository's rulesets, branch protections, and `CODEOWNERS`. Record collection date, source level (`enterprise`, `org`, or `repo`), collector, and non-secret evidence location.
2. Define what Copilot review is expected to find, what remains a human-only decision (architecture, risk acceptance, approvals, merge), and the escalation path for a false positive or suspected missed issue.
3. Record the review cohort: repositories, branches, PR types, draft treatment, expected volume, named human reviewers, `CODEOWNERS` paths, and exclusions. Do not assume an organization-wide rule is appropriate for every repository.

### Part B — Request and assess a manual Copilot review

4. Open or select a bounded pull request. In the PR **Reviewers** sidebar, select **Copilot** and click **Request**. Alternatively, use the REST review-request endpoint to request `copilot-pull-request-reviewer[bot]`.
5. Read every Copilot comment against the change, tests, threat model, and repository conventions. A designated human reviewer must classify each comment as accepted, rejected with rationale, deferred, or duplicate/noise.
6. Resolve or discuss comments as appropriate, then obtain the normal human and `CODEOWNERS` reviews. Preserve the PR timeline, reviewer decisions, and final merge result as evidence. Do not count Copilot's comment review as an approval.
7. Re-request a review only when a human reviewer judges it useful. Record that manual re-review is deliberate; automatic re-review of new pushes is a separate ruleset option.

### Part C — Decide automatic review at repository or organization scope

8. Inspect a **repository branch ruleset** first for a narrow pilot, or an **organization ruleset** only where the customer has an approved cohort and ownership model. Target the intended branches and, for organization scope, the intended repositories—not an unreviewed blanket estate.
9. In the ruleset, assess **Automatically request Copilot code review**. Set the enforcement and scope only after the accountable owner approves the pilot.
10. Treat **Review new pushes** and **Review draft pull requests** as deliberate, optional choices:
   - New-push review increases coverage but can repeat comments and consume additional capacity.
   - Draft review can surface feedback early but may create noise before a human is ready to request review.
   - Neither option is required to complete this activity.
11. Validate on one non-sensitive pilot PR: capture the ruleset export, the PR timeline showing the automatic request, comment triage, human/CODEOWNERS review, and the result. If access or policy prevents the pilot, complete the decision package rather than forcing enablement.

### Part D — Align setup and review context

12. Inspect `.github/copilot-instructions.md`, `AGENTS.md`, and applicable path-specific `.github/instructions/**/*.instructions.md`. Keep review guidance factual: supported commands, intentional patterns, security checks, and paths requiring human owner review. Copilot uses instructions from the PR's **base branch**.
13. Inspect the shared `.github/workflows/copilot-setup-steps.yml`. Copilot code review reuses this setup by default. Keep it least-privilege, reproducible, and suitable for both code review and any cloud-agent use that shares it.
14. Assess—not require—an optional dedicated `.github/workflows/copilot-code-review.yml` when code review needs a different environment. If present, it takes precedence over the shared setup file for code review. Record runner, permissions, dependencies, network/firewall posture, cost owner, and rollback.
15. **Preview capabilities are optional and are not required.** Do not enable MCP tools, agent skills, “Fix with Copilot,” or any other public-preview capability to complete this activity. If the customer elects to assess one, record availability, data/tool boundary, approval, and a separate rollback decision.

### Part E — Evidence, rollback, and handover

16. Define rollback before expanding: disable or change the automatic-review rule in the relevant ruleset; restore the prior ruleset configuration; retain human-review and `CODEOWNERS` gates; and remove the dedicated review environment only if it is separately approved for removal. Capture before/after exports and the rollback executor.
17. Handover the operating record to the repository owner and set a review date for comment usefulness, false-positive rate, review latency, Actions/runner cost, coverage, and any exception.

## Decision-package fallback

When Copilot code review, policy authority, Actions capacity, or a customer repository is unavailable, deliver a decision package instead of a simulated enablement: the effective policy/plan result and why a live pilot didn't run; the proposed repository cohort, branches, PR types, and automatic-review options considered; the required human reviewers, `CODEOWNERS`, and merge rules (with a statement that Copilot is not an approval); the shared/dedicated setup-file assessment; the risk/rollback plan; and a named approver with review date.

## Reference links

- [About GitHub Copilot code review](https://docs.github.com/en/copilot/concepts/agents/code-review)
- [Using GitHub Copilot code review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [Adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- [Managing rulesets for repositories in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization)
