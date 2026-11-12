# Ch32: Copilot code review

**Session outcome:** A human reviewer assessed Copilot's findings on a test pull request. Your team decided whether to enable automatic review for a limited scope, with human approval and merge controls unchanged.

> [!IMPORTANT]
> Copilot leaves a **Comment** review. It doesn't approve, request changes, satisfy a required approval, or block a merge. Human reviewers decide whether to merge, under the existing `CODEOWNERS` and ruleset controls.

## Prerequisites and availability decision

1. Pick an approved customer repository **before** you use a sample. Record its repository owner, human-review owners, `CODEOWNERS` coverage, data classification, expected PR volume, and approving customer owner.
2. Check the effective enterprise and organization Copilot policy. Record whether Copilot code review is enabled, who can request it, any plan, licensing, or AI-credit conditions, and any repository exclusions.
3. Confirm the Actions, runner, network, and cost owners accept the environment that agentic review uses. Record any Actions capability that failed or is unavailable. That is never a reason to weaken human review gates.
4. If the customer repository or Copilot code review isn't available, do **not** enable a workaround. Use the decision-package fallback below: record what's unavailable, the evidence, the risk owner, the proposed scope, the rollback, and a review date.

## Safe fallback repository

Use this only if you have no approved customer target:

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch32 --org <org>
```

```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch32 --org <org>
```

The fallback is isolated and namespaced `ghec-ch32-*`. It creates `ghec-ch32-copilot-code-review`, a small PR to review, repository-wide Copilot instructions, and a decision-package template. It creates **no** Copilot policy, ruleset, `CODEOWNERS` rule, or automatic review setting. Re-running is idempotent, and teardown stays prefix-guarded.

## Tasks

### Part A: Establish the review boundary and evidence baseline

1. Export or screenshot the effective Copilot policy and the repository's rulesets, branch protections, and `CODEOWNERS`. Record the collection date, source level (`enterprise`, `org`, or `repo`), collector, and where the non-secret evidence lives.
2. Define what Copilot review should find, what stays a human-only decision (architecture, risk acceptance, approvals, merge), and how to escalate a false positive or a suspected miss.
3. Record the review cohort: repositories, branches, PR types, draft treatment, expected volume, named human reviewers, `CODEOWNERS` paths, and exclusions. Don't assume an organization-wide rule fits every repository.

### Part B: Request and assess a manual Copilot review

4. Open or select a small pull request. In the PR **Reviewers** sidebar, select **Copilot** and click **Request**. Alternatively, use the REST review-request endpoint to request `copilot-pull-request-reviewer[bot]`.
5. Read every Copilot comment against the change, tests, threat model, and repository conventions. A designated human reviewer classifies each comment as accepted, rejected with a reason, deferred, or duplicate or noise.
6. Resolve the comments, or discuss any that stay open, then get the normal human and `CODEOWNERS` reviews. Keep the PR timeline, reviewer decisions, and final merge result as evidence. Copilot's comment review is not an approval.
7. Re-request a review only if a human reviewer finds it useful. Automatic re-review of new pushes is a separate ruleset option.

### Part C: Decide automatic review at repository or organization scope

8. Start with a repository branch ruleset for a narrow pilot. Use an organization ruleset only for an approved cohort with clear owners. Target only the intended branches and repositories.
9. In the ruleset, look at **Automatically request Copilot code review**. Set enforcement and scope only after the accountable owner approves the pilot.
10. **Review new pushes** and **Review draft pull requests** are optional, so choose them deliberately:
   - New-push review adds coverage but can repeat comments and use more capacity.
   - Draft review surfaces feedback early but can be noise before a human is ready to ask for review.
   - You don't need either to complete this session.
11. Validate on one non-sensitive pilot PR. Capture the ruleset export, the PR timeline showing the automatic request, the comment triage, the human and `CODEOWNERS` review, and the result. If access or policy blocks the pilot, record the blocker instead of enabling review anyway.

### Part D: Align setup and review context

12. Use the [first-run setup and instructions](../../resources/copilot-first-run.md) in this same review. Read the instruction files from the PR's **head branch** and review their changes, because they shape Copilot's findings.
13. Reuse a working `.github/workflows/copilot-setup-steps.yml` when present. Code review uses the shared setup by default. Add basic setup only if this review needs it, then verify the review used it. Ch31 isn't a prerequisite.
14. Use the optional Ch31 only for a real runtime, private-dependency, or runner gap. A dedicated `.github/workflows/copilot-code-review.yml` overrides the shared setup for review. Configure it only if the shared environment isn't enough.
15. **Preview capabilities are optional.** Don't enable MCP tools, agent skills, "Fix with Copilot," or any other public-preview capability to complete this session. If the customer chooses to assess one, record its availability, data and tool boundary, approval, and a separate rollback decision.

### Part E: Evidence, rollback, and handover

16. Define the rollback before you expand: disable or change the automatic-review rule in the ruleset, restore the previous ruleset configuration, keep the human-review and `CODEOWNERS` gates, and remove the dedicated review environment only if that removal is separately approved. Capture before and after exports, and record who will do the rollback.
17. Hand the operating record to the repository owner. Set a review date for comment usefulness, false-positive rate, review latency, Actions and runner cost, coverage, and any exception.

## Decision-package fallback

If a required feature, approval, or repository isn't available, record the
failed check and its owner in the adoption issue. Keep proposed
configuration only if it helps that owner decide. Don't simulate enablement
or require a separate decision package. Mark implementation
**blocked / not tested**. Copilot findings never replace human approval.

## Reference links

- [About GitHub Copilot code review](https://docs.github.com/en/copilot/concepts/agents/code-review)
- [Using GitHub Copilot code review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [Adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- [Managing rulesets for repositories in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization)
