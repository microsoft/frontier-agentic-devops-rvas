# Prepare the first Copilot run

Use this inside the cloud-agent or code-review session. Reuse existing setup and instructions; do not create a second validation PR just for configuration.

## Give Copilot the repository's working commands

Review `.github/copilot-instructions.md`. Add only the layout, build/test commands, and review boundaries the first task needs. Keep credentials and customer data out of instructions.

For a JavaScript-specific convention, add `.github/instructions/javascript.instructions.md`:

```markdown
---
applyTo: "src/**/*.js"
---
Use this repository's existing module style. Update the matching behavior test
and run the commands documented in the README before proposing a change.
```

Review existing `AGENTS.md` and other instruction files for conflicts. The nearest `AGENTS.md` governs its directory. Matching repository and path instructions both apply. Code review reads instructions from the PR's head branch, so a human must inspect instruction changes in that PR.

## Add setup only when the run needs it

If standard setup already runs the application's tests, keep it. Otherwise add `.github/workflows/copilot-setup-steps.yml` using the project's actual runtime and install command. For a Node.js application with a committed lock file:

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
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version: '22'
          cache: npm
      - run: npm ci
      - run: npm test
```

Replace the runtime and commands for the application. Keep exactly one job named `copilot-setup-steps`, with the smallest permissions and a timeout below the **59-minute** maximum. Copilot uses the file only after it reaches the default branch.

Run its normal Actions check and merge through review. Then verify the actual Copilot session or review used the setup. A green Actions run alone is not proof.

Cloud agent and code review share this setup by default. Use [advanced configuration](../challenges/31-copilot-environment-instructions/README.md) only for a real private dependency, shared-runtime problem, or approved runner/network requirement. Organization-wide instructions also belong to that optional configuration path.
