# Scripts

Run scripts from the repository root unless a script says otherwise.

## Simulate Checkout Incident

```bash
Resources/scripts/simulate-checkout-incident.sh checkout_error
Resources/scripts/simulate-checkout-incident.sh checkout_latency
```

The script is safe and local-only. It starts the sample app, captures health and checkout responses, writes evidence under `Resources/runbooks/generated/`, and stops the app before exiting.

## Validate Agentic Workflow Specs

```bash
bash Resources/scripts/validate-agentic-workflow-specs.sh
```

The validator checks the Peli's Factory / GitHub Agentic Workflows-inspired markdown specs under `Resources/agentic-workflows/` for required frontmatter, review sections, safe-output sections, and `gh aw compile` notes. It does not require `gh-aw` to be installed.
