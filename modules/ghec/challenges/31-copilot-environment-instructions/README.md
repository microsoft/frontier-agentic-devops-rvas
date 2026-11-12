# Ch31: Advanced Copilot environment configuration

**Session outcome:** An approved shared-runtime, private-dependency, or runner requirement works in a real Copilot session or review, and the owner verified the access boundary.

## When to use this session

Do the basic setup in Ch19 or Ch32 first. Use this optional session only if that first run exposes a concrete requirement:

| Requirement | Configure |
|---|---|
| Private build dependency | Scoped Agents credentials and the package manager's approved registry configuration |
| Shared runtime or disposable test service | Deterministic setup steps and the required service |
| Different review environment | A dedicated code-review setup with a documented reason |
| Approved compute or network requirement | The supported runner and explicit network controls |

If the standard hosted environment already works, skip this session. A small public sample can't prove private-registry or internal-runner access.

## Prerequisites

Use the approved repository and the Ch19 agent task or Ch32 review that already works. Involve its Copilot owner and the administrator who controls the dependency, runner, or network boundary. Before you change configuration, confirm the feature is available and the cost is approved.

## Tasks

### Part A: Identify the missing requirement

1. Read the first run's setup log. Name the exact dependency that failed or capability that's missing, and the acceptance test.
2. Agree the smallest scope with its owner. Prefer standard GitHub-hosted runners. Don't attach an internal runner or create a secret just for this exercise.
3. Reuse the [first-run setup](../../resources/copilot-first-run.md). Keep one `copilot-setup-steps` job on the default branch. Copilot recognizes `steps`, `permissions`, `runs-on`, `services`, `snapshot`, and `timeout-minutes`; the maximum timeout is **59 minutes**.

### Part B: Configure only the selected requirement

**Private dependency:** Use an Agents variable for non-sensitive settings and an Agents secret for the smallest approved credential. Actions, Codespaces, and Dependabot secrets are separate and aren't passed to cloud agent. Limit organization values to selected repositories; repository values override same-named organization values. Configure the package manager to resolve the approved dependency without printing credentials.

**Runtime or service:** Add the actual toolchain or a disposable test service to the setup job. Pin the dependency versions the application uses. Keep production state and broad write tokens out of setup. A failed setup step skips the remaining steps and leaves Copilot with whatever state it reached, so make failures obvious.

**Dedicated review setup:** Keep `.github/workflows/copilot-code-review.yml` only if code review needs a different environment. It overrides the shared setup for review. Use the same single-job contract and test it with a real Ch32 review.

**Runner or network:** Ask the organization owner to pick the approved runner and document its cost and reachable endpoints. Cloud agent supports Ubuntu x64 or Windows 64-bit. Code review supports Ubuntu x64 and, for self-hosted use, ARC-managed scale sets. Use ephemeral, single-use self-hosted runners.

Cloud agent's integrated firewall doesn't work with self-hosted runners. Security must approve customer-managed network controls before you change it, and Windows needs those controls too. Never give agent jobs unrestricted internal-network access.

Assume any credential you expose is readable by the scripts Copilot runs. Use short-lived credentials where supported, check the logs, and rotate after testing if needed. Approve `COPILOT_MCP_` values separately. Only MCP servers can read them.

Use this prompt if the setup needs an application-specific edit:

```text
Inspect the current Copilot setup workflow and the failed setup log.
Requirement: [exact dependency, runtime, service, or approved runner].
Acceptance test: [existing command and expected result].
Change only what this requirement needs. Keep the supported single-job contract,
least privilege, and deterministic installation. Do not add production access
or put credential values in files or logs. Identify missing administrator
decisions before editing. Show the diff and the test to run.
```

Fill in the requirement and test first, then review the patch with the accountable owner.

### Part C: Verify it in the existing task or review

1. Merge the reviewed setup change to the default branch. Run the normal Actions check if it can validate the setup. It may not have the agent's credentials.
2. Repeat the Ch19 task or Ch32 review that exposed the gap. Confirm its log shows the setup you chose, the intended runner, and successful dependency or service access.
3. Run the acceptance test and inspect the diff or review it produced. Leave human approval and required CI as they are.
4. If you can test it safely, confirm the scoped credential or runner can't reach an unrelated resource.
5. Record the setup commit and the session or review link in the adoption issue. Name the setup owner and the rollback, such as reverting the configuration or removing the approved Agents scope.

For organization instructions, set only a short shared rule in **Organization settings → Copilot → Custom instructions**, then verify it in the real run. Don't repeat repository-specific instructions. One observed result doesn't guarantee future AI behavior.

If the capability or approval isn't available, record the failed check and its owner. Don't bypass a policy, and don't count a proposed workflow as done.

## References

- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [Configure secrets and variables](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/configure-secrets-and-variables)
- [Configure runners for code review](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-runners)
- [Organization custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
