# Ch31: Advanced Copilot environment configuration

**Session outcome:** An approved shared-runtime, private-dependency, or runner requirement works in a real Copilot session or review. The owner has verified the intended access boundary.

## When to use this session

Complete the basic setup inside Ch19 or Ch32. Use this optional session only when that first run reveals a concrete requirement:

| Requirement | Configure |
|---|---|
| Private build dependency | Scoped Agents credentials and the package manager's approved registry configuration |
| Shared runtime or disposable test service | Deterministic setup steps and the required service |
| Different review environment | A dedicated code-review setup with a documented reason |
| Approved compute or network requirement | The supported runner and explicit network controls |

If the standard hosted environment already works, skip this session. A small public sample cannot prove private-registry or internal-runner access.

## Prerequisites

Use the existing approved repository and working Ch19 agent task or Ch32 review. Involve its Copilot owner and the administrator who controls the dependency, runner, or network boundary. Confirm effective feature availability and cost approval before changing configuration.

## Tasks

### Part A: Identify the missing requirement

1. Read the first run's setup log. Name the exact failed dependency or missing capability and the acceptance test.
2. Agree the smallest scope with its owner. Prefer standard GitHub-hosted runners; do not attach an internal runner or create a secret merely for this exercise.
3. Reuse the [first-run setup](../../resources/copilot-first-run.md). Keep one `copilot-setup-steps` job on the default branch. Copilot recognizes `steps`, `permissions`, `runs-on`, `services`, `snapshot`, and `timeout-minutes`; the maximum timeout is **59 minutes**.

### Part B: Configure only the selected requirement

**Private dependency:** Use an Agents variable for non-sensitive settings and an Agents secret for the smallest approved credential. Actions, Codespaces, and Dependabot secrets are separate and are not passed to cloud agent. Limit organization values to selected repositories; repository values override same-named organization values. Configure the existing package manager to resolve the approved dependency without printing credentials.

**Runtime or service:** Add the actual toolchain or a disposable test service to the setup job. Pin the dependency versions the application uses. No production state or broad write token belongs in setup. A failed setup step skips the remaining steps and leaves Copilot with the state reached so far, so make failures clear.

**Dedicated review setup:** Keep `.github/workflows/copilot-code-review.yml` only when code review needs a different environment. It takes precedence over the shared setup for review. Use the same single-job contract and test it through Ch32's actual review.

**Runner or network:** Ask the organization owner to select the approved runner and document its cost and reachable endpoints. Cloud agent supports Ubuntu x64 or Windows 64-bit. Code review supports Ubuntu x64 and, for self-hosted use, ARC-managed scale sets. Use ephemeral, single-use self-hosted runners.

Cloud agent's integrated firewall is incompatible with self-hosted runners. Security must approve customer-managed network controls before changing it; Windows also needs those controls. Do not give agent jobs unrestricted internal-network access.

Treat exposed credentials as accessible to the scripts Copilot runs. Use short-lived credentials when supported, inspect logs, and rotate after testing when required. Approve `COPILOT_MCP_` values separately; they are available only to MCP servers.

Use this prompt if the existing setup needs an application-specific edit:

```text
Inspect the current Copilot setup workflow and the failed setup log.
Requirement: [exact dependency, runtime, service, or approved runner].
Acceptance test: [existing command and expected result].
Change only what this requirement needs. Keep the supported single-job contract,
least privilege, and deterministic installation. Do not add production access
or put credential values in files or logs. Identify missing administrator
decisions before editing. Show the diff and the test to run.
```

Fill in the requirement and test first. Review the patch with the accountable owner.

### Part C: Verify it in the existing task or review

1. Merge the reviewed setup change to the default branch. Run the normal Actions check where it can validate the setup; it may not have the same credentials as the agent.
2. Repeat the bounded Ch19 task or Ch32 review that exposed the gap. Confirm its log shows the selected setup, intended runner, and successful dependency or service access.
3. Run the application's acceptance test and inspect the produced diff or review. Keep human approval and required CI unchanged.
4. Verify a denied access case where the platform allows a safe test. Confirm the scoped credential or runner cannot reach an unrelated resource.
5. Record the setup commit and actual session/review link in the existing adoption issue. Name the setup owner and rollback, such as reverting the configuration or removing the approved Agents scope.

For organization instructions, set only a short shared rule in **Organization settings → Copilot → Custom instructions**, then verify it in the selected real run. Avoid repeating repository-specific instructions. A single observed result cannot guarantee future AI behavior.

If the capability or approval is unavailable, record the failed check and its owner. Do not bypass a policy or count a proposed workflow as implementation.

## References

- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [Configure secrets and variables](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/configure-secrets-and-variables)
- [Configure runners for code review](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-runners)
- [Organization custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
