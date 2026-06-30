# Scripts

Run scripts from the repository root unless a script says otherwise.

## Doctor

Run the SRE Agent setup doctor before Challenge 01 and again before Challenge 04:

```bash
npm run setup:sre-agent
```

The doctor checks core tools, GitHub authentication, sample app tests, and the local agentic workflow spec validator. Azure CLI access is reported as a warning so teams can keep moving with fallback packets when subscription access is blocked.

## Simulate Checkout Incident

```bash
modules/sre-agent/resources/scripts/simulate-checkout-incident.sh checkout_error
modules/sre-agent/resources/scripts/simulate-checkout-incident.sh checkout_latency
```

The script is safe and local-only. It starts the sample app, captures health and checkout responses, writes evidence under `modules/sre-agent/resources/runbooks/generated/`, and stops the app before exiting.

## Capture Deployment Evidence

```bash
APP_URL=https://<your-container-app-fqdn> \
GITHUB_RUN_URL=https://github.com/<org>/<repo>/actions/runs/<run-id> \
modules/sre-agent/resources/scripts/capture-deployment-evidence.sh
```

The script writes a markdown evidence note under `modules/sre-agent/resources/runbooks/generated/`. Use it after a healthy Azure deployment and after any controlled incident-mode deployment.

## Validate Agentic Workflow Specs

```bash
bash modules/sre-agent/resources/scripts/validate-agentic-workflow-specs.sh
```

The validator checks the Peli's Factory / GitHub Agentic Workflows-inspired markdown specs under `modules/sre-agent/resources/agentic-workflows/` for required frontmatter, review sections, safe-output sections, and `gh aw compile` notes. It does not require `gh-aw` to be installed.
