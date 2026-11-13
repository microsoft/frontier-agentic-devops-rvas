# Ch32: Copilot code review

**Session outcome:** Copilot reviewed a real pull request, a human triaged every comment, and automatic review runs on a narrow ruleset pilot with human approval and merge controls unchanged.

> [!IMPORTANT]
> Copilot leaves a **Comment** review. It doesn't approve, request changes, satisfy a required approval, or block a merge. Human reviewers decide, under the existing `CODEOWNERS` and ruleset controls.

## Prerequisites

- A customer repository with a named owner, `CODEOWNERS` coverage, and a small real pull request to review.
- Copilot code review enabled by the effective enterprise and organization policy.
- Permission to edit a repository ruleset.

**Blocked:** if Copilot code review, the repository, or ruleset access is missing, stop. Note the blocker and its owner in the adoption issue. The session isn't complete.

**No target yet?** Create a sample repository with a small PR to review. It runs the same real review:

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch32 --org <org>
```

```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch32 --org <org>
```

It creates `ghec-ch32-copilot-code-review` with a PR and repository-wide Copilot instructions. It sets no policy, ruleset, `CODEOWNERS` rule, or automatic review. Re-running is idempotent, and teardown is prefix-guarded.

## Tasks

### Part A: Request and triage a manual review

1. Open or select a small pull request. In the **Reviewers** sidebar, select **Copilot** and click **Request**. The REST review-request endpoint also works for `copilot-pull-request-reviewer[bot]`.
2. A human reviewer reads each Copilot comment against the change, tests, and repository conventions. Mark each one accepted, rejected with a reason, deferred, or noise.
3. Resolve or discuss the comments, then get the normal human and `CODEOWNERS` reviews. Merge only after those pass.

### Part B: Pilot automatic review

4. Create a repository branch ruleset for one narrow pilot. Target only the intended branches. Use an organization ruleset later, for an approved cohort.
5. Enable **Automatically request Copilot code review**. Two options are off by default:
   - **Review new pushes** adds coverage but repeats comments.
   - **Review draft pull requests** gives early feedback but adds noise.
6. Open a new non-sensitive PR on a targeted branch. Check the PR timeline: Copilot is requested **without** a manual click, and the human and `CODEOWNERS` reviews are still required.

### Part C: Check setup and instructions

7. Read the [first-run setup and instructions](../../resources/copilot-first-run.md). Copilot reads instruction files from the PR's **head branch**, so review changes to them like code.
8. Review uses a working `.github/workflows/copilot-setup-steps.yml` by default. If the log shows a runtime, private-dependency, or runner gap, continue with [Ch31](../31-copilot-environment-instructions/README.md). Otherwise skip it.

**Optional:** public-preview features (MCP tools, agent skills, "Fix with Copilot") aren't needed here.

### Part D: Rollback

9. To roll back, set the ruleset to **Disabled** or remove the Copilot rule. Keep the human-review and `CODEOWNERS` gates. Confirm the next PR gets no automatic request.

## Reference links

- [About GitHub Copilot code review](https://docs.github.com/en/copilot/concepts/agents/code-review)
- [Using GitHub Copilot code review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review)
- [Configuring automatic code review by GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review)
- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [Adding repository custom instructions for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- [Managing rulesets for repositories in your organization](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization)
