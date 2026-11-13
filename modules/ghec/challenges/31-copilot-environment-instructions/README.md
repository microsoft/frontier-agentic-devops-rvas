# Ch31: Advanced Copilot environment configuration

**Session outcome:** The runtime, private-dependency, or access gap that your [Ch32](../32-copilot-code-review/README.md) review exposed is fixed, and a rerun of that review passes.

## When to use this session

Use it only if the Ch32 review log shows a concrete gap, such as a failed private dependency, a missing runtime or test service, or a needed runner. If the standard hosted environment already works, skip it.

**Blocked:** if the feature, access, or approval is missing, stop. Note the blocker and its owner in the adoption issue. The session isn't complete.

## Prerequisites

The Ch32 repository, plus someone who can merge to the default branch and, for secrets or runners, the administrator who owns that boundary. Confirm the cost is approved first.

## Tasks

1. Read the failed setup log. Write down the exact failure and the acceptance test that should pass.
2. Fix only that gap in `.github/workflows/copilot-setup-steps.yml` (see [first-run setup](../../resources/copilot-first-run.md)). Keep one `copilot-setup-steps` job on the default branch. The maximum timeout is **59 minutes**.

   - **Private dependency:** add an Agents variable for non-sensitive settings and an Agents secret for the smallest approved credential. Actions, Codespaces, and Dependabot secrets aren't passed to cloud agent. Configure the package manager to resolve the dependency without printing credentials.
   - **Runtime or service:** add the toolchain or a disposable test service, with pinned versions. Keep production state and broad tokens out of setup.
   - **Runner or network:** use a GitHub-hosted runner unless the administrator approves otherwise. Self-hosted runners must be ephemeral. The cloud agent firewall doesn't work with them, so security must approve the network controls first.

   Treat any exposed credential as readable by scripts Copilot runs. Prefer short-lived credentials and rotate after testing.
3. Merge the reviewed change to the default branch.
4. **Rerun the Ch32 review.** Confirm the log shows your setup and that dependency or service access now succeeds. Run the acceptance test.
5. If you can test it safely, confirm the credential or runner can't reach an unrelated resource.
6. Link the setup commit and the passing review in the adoption issue. Rollback is reverting the change or removing the Agents secret.

**Optional:** a dedicated `.github/workflows/copilot-code-review.yml` overrides the shared setup for review only. Add it only if review truly needs a different environment. Short organization-wide instruction rules live in [Organization custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions).

## References

- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [Configure secrets and variables](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/configure-secrets-and-variables)
- [Configure runners for code review](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-runners)
- [Organization custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
