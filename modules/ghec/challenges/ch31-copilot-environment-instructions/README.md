# Ch31 — Copilot Environment & Instructions

> Deliver a customer-approved, observable Copilot environment: deterministic setup, scoped instructions, least privilege, and a decision package when a live feature is unavailable.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Advanced |
| Duration | ~3 hrs |
| Minimum input | Authorized customer repository, repository owner, and Copilot policy/availability view |
| App | Customer repository; optional safe fallback repository |
| EMU compatible | yes — assess and record the actual availability of cloud agent and code review; do not assume either feature or policy is available |

## Customer delivery target

- **Customer objective:** make Copilot cloud-agent and code-review work reproducibly in an approved repository without widening access, runner, service, or secret exposure.
- **Customer-tenant target:** a default-branch setup workflow, concise repository and path instructions, and a record of the effective organization, runner, network, and secret boundaries.
- **Approval boundary:** work in an approved customer repository first. A repository owner approves workflow/instruction changes; the Copilot owner confirms feature policy; security approves any private-network runner, service, or Agents secret. Do not enable a policy, add a secret, or attach an internal runner merely to complete this activity.
- **Records to keep:** target and owners, policy/availability evidence, merged default-branch commit and Actions URL, instruction inventory and precedence review, runner/secrets decision, agent/session or review evidence, open risks, and next decision.
- **Fallback:** if policy or feature access is unavailable, produce the decision package in Part H. Use `ghec-ch31-*` only as a safe, non-production seed to validate repository files; it is never a substitute for customer approval.

## Prerequisites and availability

- An authorized customer repository and named repository, Copilot, security, and platform/runner owners.
- Copilot Business or Copilot Enterprise availability must be inspected, not inferred. Cloud agent, code review, organization instructions, runner choices, and organization policy can vary by subscription, policy, repository, identity model, and current feature availability.
- Repository administrator access is needed to set Agents secrets/variables; organization-owner access is needed for organization-level versions and policy/runner decisions. A contributor may prepare a pull request but must not self-approve a privileged change.
- Optional fallback tooling: `gh >= 2.x`, `git`, and `jq`. The provisioning scripts create only a small public seed; they do **not** change Copilot policy, create a secret, configure a runner, or invoke an agent.

## Scenario

The customer wants **Agentic DevSecOps** teams to use Copilot cloud agent and Copilot code review predictably. Today, an agent may spend time rediscovering dependencies, reviewers lack repository context, and no one can say which instructions, runner, or credentials are in scope. Establish a small, reviewable baseline on a customer target, prove what happened in GitHub's UI, and retain a decision package when the required capability cannot be used.

> [!IMPORTANT]
> **Start with the customer target.** Substitute its name for `ghec-ch31-copilot-environment-instructions` throughout. Do not put a production secret, internal endpoint, or customer data in the fallback repository.

## Safe fallback repository

Use this only if no approved customer target is available:

```bash
bash modules/ghec/challenges/ch31-copilot-environment-instructions/provision.sh --org <org>
```

```powershell
pwsh -File modules/ghec/challenges/ch31-copilot-environment-instructions/provision.ps1 -Org <org>
```

It creates `ghec-ch31-copilot-environment-instructions`, a tiny Node.js fixture, a default-branch `.github/workflows/copilot-setup-steps.yml`, repository/path instructions, and a bounded issue. The repository contains no secret, service, self-hosted runner, policy update, or production material. Teardown is prefix-guarded:

```bash
bash modules/ghec/challenges/ch31-copilot-environment-instructions/provision.sh --org <org> --teardown
```

```powershell
pwsh -File modules/ghec/challenges/ch31-copilot-environment-instructions/provision.ps1 -Org <org> -Teardown
```

## Tasks

### Part A — Authorize the target and establish the decision point

1. Record the customer repository, default branch, data classification, accountable repository/Copilot/security/runner owners, authorized change scope, and evidence location.
2. Inspect and record the effective availability/policy for **Copilot cloud agent**, **Copilot code review**, and **organization custom instructions**. Record an unavailable, disabled, EMU, licensing, or preview limitation precisely; do not work around it.
3. Choose one bounded validation change with no production data. State whether the proof will be a cloud-agent task, a code review, or both. Capture the expected evidence before changing configuration.

### Part B — Configure and activate common setup steps

4. Add or review `.github/workflows/copilot-setup-steps.yml`. It must contain exactly one job named `copilot-setup-steps`. The file is the shared environment baseline: cloud agent uses it, and code review reuses it by default.
5. Merge the file to the repository's **default branch**. Its special Copilot behavior does not activate while it exists only on a feature branch. Keep `workflow_dispatch` and path-triggered `push`/`pull_request` events so the normal Actions workflow supplies visible validation.

```yaml
name: Copilot setup steps

on:
  workflow_dispatch:
  push:
    paths: [.github/workflows/copilot-setup-steps.yml]
  pull_request:
    paths: [.github/workflows/copilot-setup-steps.yml]

jobs:
  copilot-setup-steps:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm
      - run: npm ci
      - run: npm test
```

6. Keep the job narrow. Copilot recognizes only `steps`, `permissions`, `runs-on`, `services`, `snapshot`, and `timeout-minutes`; the timeout maximum is **59 minutes**. Add a service only when the bounded test demonstrably needs it, use a disposable service with no production state, and remove it when no longer needed. A failed setup step leaves Copilot with the state reached so far, so make setup deterministic and fail clearly.
7. Run the workflow from **Actions** after it is on the default branch. Retain the successful run URL, job log, commit SHA, runner label, elapsed time, and installed/test output. This proves the workflow itself; it does not yet prove an agent/reviewer used it.

### Part C — Define repository and path-specific instructions

8. Create or review `.github/copilot-instructions.md`. Keep broadly applicable instructions short and testable: project layout, trusted build/test commands, non-negotiable security boundaries, and pull-request expectations. Do not place credentials, customer data, or long policy manuals in instructions.
9. Add narrowly scoped `.github/instructions/NAME.instructions.md` files with `applyTo` frontmatter. For example:

```markdown
---
applyTo: "src/**/*.js"
---
Use CommonJS module exports in this repository. Add or update the matching test
under `test/`, and run `npm test` before proposing a change.
```

Matching path-specific and repository-wide instructions are both used. At GitHub.com these are supported for cloud agent and code review; confirm tool-specific support before claiming an IDE result.
10. Inventory any `AGENTS.md`, `CLAUDE.md`, or `GEMINI.md`. For agent instructions, the nearest `AGENTS.md` in the directory tree takes precedence. Avoid duplicated or contradictory requirements.
11. Record organization instructions in **Organization settings → Copilot → Custom instructions**. On GitHub.com, all relevant sets are provided to Copilot in this order: personal, matching path-specific repository, repository-wide, agent, then organization instructions. Organization instructions are supported for GitHub.com Chat, cloud agent, and code review; they are the organization-wide baseline, not a replacement for repository-specific guidance. Resolve conflicts with the owner rather than relying on model behavior.

### Part D — Decide whether code review needs a separate environment

12. Start with the shared `copilot-setup-steps.yml`: both cloud agent and code review use it by default. Create `.github/workflows/copilot-code-review.yml` **only** when code review needs a genuinely different setup, such as a smaller dependency install, different test preparation, or a separately approved runner.
13. If you create it, document why common setup is insufficient, apply the same single `copilot-setup-steps` job contract and least privilege, put it on the relevant branch, and validate it with a review. Do not create a duplicate just because code review exists; it introduces drift and a second control surface.

### Part E — Enforce least privilege and platform constraints

14. Set setup-job `permissions` to the smallest requirement. `contents: read` is sufficient to check out code; do not grant write permissions, `id-token`, packages, deployments, or broad tokens without a documented test dependency and approval. Copilot receives its own token for its operations.
15. Record the runner decision. Standard GitHub-hosted runners are the baseline. Organization owners can choose a default runner for both cloud agent and code review and can prevent repositories from overriding it. Larger runners cost more; record cost owner and network rationale.
16. For self-hosted use, require an approved **ephemeral, single-use** runner. Cloud agent supports Ubuntu x64 or Windows 64-bit; code review supports Ubuntu x64 and only ARC-managed scale sets are supported. Segment network access, permit only required endpoints, and do not give a Copilot job broad internal-network access. Cloud agent's integrated firewall is incompatible with self-hosted runners and must be deliberately addressed by security; Windows also needs customer-managed network controls.
17. Use **Agents** secrets and variables only. They are separate from Actions, Codespaces, Dependabot, and other secret types; those other types are not passed to cloud agent. Use an Agents **variable** for non-sensitive configuration and an Agents **secret** for the smallest scoped credential required by a private build/test dependency. Limit organization-level items to selected repositories; repository-level values override same-named organization values. Do not add a secret to demonstrate this activity.
18. Treat anything exposed to the agent environment as accessible to scripts/tools it runs. Use short-lived, least-privileged credentials, mask/inspect logs, rotate after a test where required, and separately approve `COPILOT_MCP_` values because those are available only to MCP servers.

### Part F — Validate visible behavior

19. Create a small pull request that changes a file covered by the path instruction. Confirm the changed/head branch contains the intended instructions: for pull-request review, Copilot reads repository instructions, agent instructions, and skills from the **head** branch, so this permits an instruction change to be tested before merging.
20. Request Copilot code review if it is available and approved. Retain the request/result URL and show whether feedback references the repository/path context. If the review is limited because GitHub-hosted runners are disabled, record that limitation rather than claiming agentic review ran.
21. If cloud agent is available and approved, assign it the bounded issue. In its session log, confirm setup steps appear, inspect the planned/actual commands and runner behavior, and review its pull request. Require normal human review and CI; instructions guide behavior but do not replace review gates.
22. Compare observed behavior to the expected instructions and setup. Record: applicable organization/repository/path/agent instruction files, exact commit SHA, Actions and session/review URLs, setup outcome, command/test result, unobserved behavior, and remediation. AI behavior is non-deterministic; a single success is evidence for the case tested, not a guarantee.

### Part G — Handover

23. Publish a concise operating record: approved repository classes, default-branch setup owner, instruction owners/review cadence, runner/secret/service boundaries, evidence links, exceptions, rollback (revert workflow/instruction commit or remove approved Agents scope), and next decision date.
24. Update the existing governance register with `COP-AGENT-ENVIRONMENT` and, for any approved cloud-agent use, `COP-CLOUD-AGENT`. Mark unavailable features `inspect-and-propose` or `not applicable`, never `approved pilot`.

### Part H — Decision-package fallback

Use this path when an organization policy, license, entitlement, required owner, or feature is unavailable:

1. Do not enable, bypass, or simulate a customer control. Capture the unavailable capability and dated source/evidence.
2. Produce a decision package containing the target repository class, proposed default-branch setup and instructions, policy/runner/Agents-secret impact, named approver, risk/rollback, validation plan, and decision required.
3. If allowed, run the safe `ghec-ch31-*` seed only to demonstrate a normal Actions workflow and file layout. Label its results **fallback evidence**, not customer-production evidence.
4. Set the next action: approve an eligible pilot, obtain policy access, remain unavailable, or retire the proposal.

## Validation / Definition of Done

- [ ] Customer target, authorized scope, owners, default branch, availability/policy evidence, and next decision are recorded.
- [ ] `copilot-setup-steps.yml` is on the target default branch, has one correctly named job, uses least privilege, and has a successful normal Actions run with retained URL/log/SHA.
- [ ] Repository-wide, applicable path-specific, agent, and organization instructions are inventoried; applicable precedence is documented and conflicts are resolved.
- [ ] The record says cloud agent and code review share setup by default; `copilot-code-review.yml` exists only with a documented review-specific need and validation.
- [ ] Runner type, network posture, allowed services, timeout at or below 59 minutes, cost owner, and a least-privilege permissions decision are documented.
- [ ] Agents secrets/variables are distinguished from Actions/Codespaces/Dependabot types; no secret was created for demonstration and any approved access is selected-repository, minimal, and owned.
- [ ] A real cloud-agent session and/or code-review result supplies visible evidence of the configuration, or the exact feature/runner limitation is captured.
- [ ] Human review/CI still gate changes; the handover names owners, cadence, rollback, evidence, risks, and next decision.
- [ ] If access was unavailable, the decision package is complete and any `ghec-ch31-*` result is clearly marked fallback-only.

## Reference links

- [Configure the development environment](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/customize-the-agent-environment)
- [About customizing GitHub Copilot responses](https://docs.github.com/en/copilot/concepts/prompting/response-customization?tool=webui)
- [Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- [Adding organization custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-organization-instructions)
- [Configure secrets and variables for Copilot cloud agent](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/configure-secrets-and-variables)
- [Configuring runners for GitHub Copilot code review](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-runners)
