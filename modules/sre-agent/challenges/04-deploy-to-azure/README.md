# Challenge 04: Deploy to Azure with GitHub Actions

## Scenario

You have a tested sample service. Now make GitHub the path to Azure: validate the app, deploy it to a coach-provided Azure Container Apps target, capture runtime evidence, and run one controlled failure so the next challenge has real operational signal.

## Goals

- Deploy the sample app through GitHub Actions, not portal clicks.
- Use the workshop-approved Azure identity path.
- Capture deployment evidence that an SRE could use later.
- Demonstrate one safe Azure runtime failure.
- Separate agent suggestions from deterministic gates and human approvals.

## Estimated Time

75 minutes.

## Before You Start

Run the setup doctor:

```bash
npm run setup:sre-agent
```

Ask your coach for the Azure target values:

| Value | Where it is used |
| --- | --- |
| `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` | GitHub environment or repository variables for `azure/login` |
| `AZURE_RESOURCE_GROUP` | Container App resource group |
| `AZURE_CONTAINER_APP` | Existing or coach-provisioned Container App |
| `ACR_NAME`, `ACR_LOGIN_SERVER` | Image registry used by the deployment workflow |

If Azure access is blocked, use the coach fallback packet and still complete the evidence and gate-map steps.

## Run

1. Copy the starter workflow:

   ```bash
   mkdir -p .github/workflows
   cp modules/sre-agent/resources/workflows/azure-container-apps-deploy.yml .github/workflows/sre-sample-app-azure.yml
   ```

2. Configure a GitHub Environment named `sre-agent-azure`. Add an approval rule if your workshop repo allows it.
3. Add the Azure values above as repository or environment variables. Do not commit credentials or paste secrets into prompts.
4. Open a pull request with the workflow and sample app Dockerfile.
5. Confirm the pull request validation job runs `npm ci` and `npm test`.

## Deploy Healthy

From the Actions tab, run **SRE Sample App - Azure Container Apps** with `incident_mode` set to `healthy`.

After it completes, capture the endpoint and write the evidence note:

```bash
APP_URL=https://<your-container-app-fqdn> \
GITHUB_RUN_URL=https://github.com/<org>/<repo>/actions/runs/<run-id> \
modules/sre-agent/resources/scripts/capture-deployment-evidence.sh
```

Check the service manually:

```bash
curl --fail-with-body https://<your-container-app-fqdn>/healthz
curl --fail-with-body https://<your-container-app-fqdn>/api/checkout
```

## Demonstrate a Controlled Azure Failure

Run the same workflow again with one incident mode:

| Mode | Expected signal |
| --- | --- |
| `checkout_error` | `/api/checkout` returns HTTP 500 and `/healthz` reports degraded |
| `checkout_latency` | `/api/checkout` returns HTTP 503 after a delay and `/healthz` reports degraded |

The final runtime check may fail after the deployment updates the app. That is expected for this lab. Treat the failed step as operational evidence, not as a workshop failure.

Capture a second evidence note for the degraded deployment. You will use the healthy and degraded evidence in Challenge 06.

## Inspect

Create a short deployment note with:

- GitHub Actions run URL.
- Commit SHA.
- Azure environment and endpoint.
- Whether environment approval was required.
- Health and checkout status for `healthy` mode.
- Health and checkout status for incident mode.
- Any warnings or failed steps.

## Build the Gate Map

List what decides whether a change reaches Azure:

| Gate | Deterministic or human-owned? | Evidence |
| --- | --- | --- |
| Sample app tests | Deterministic | Workflow log |
| Azure identity and permissions | Deterministic | `azure/login` and Azure CLI output |
| Environment approval | Human-owned | GitHub Environment review |
| Runtime health check | Deterministic | `curl /healthz` |
| Agent or Copilot workflow suggestion | Advisory | PR discussion or review comment |

Add any repo-specific gates your team uses.

## Success Criteria

- Pull request validation runs against the sample app.
- A GitHub Actions workflow deploys to Azure Container Apps, or the team uses a coach fallback packet with the same evidence shape.
- No secrets or credentials are committed or printed.
- A healthy deployment has endpoint, run URL, commit SHA, and health evidence.
- A controlled failure mode is deployed or simulated and captured as evidence.
- The team can explain which gates are deterministic, which are human-owned, and which agent outputs are only advisory.
- Coach conversation — in your real deployment pipeline, where does the deterministic/probabilistic seam sit today: what does automation decide on its own, and what requires a human approval or deterministic gate before reaching production?

## Deliverables

- Pull request containing the deployment workflow or documented fallback use.
- Healthy deployment evidence note.
- Controlled failure evidence note.
- Gate map.
- Follow-up issue for any deployment risk discovered.
