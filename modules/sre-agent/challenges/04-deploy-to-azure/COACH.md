# Coach Guide: Challenge 04 — Deploy to Azure with GitHub Actions

### Expected Outcome

Teams deploy the sample app through GitHub Actions, capture a healthy runtime evidence note, then run one controlled Azure failure mode so Challenge 06 starts from real operational signal.

## Coach Prep

Prepare one of these paths before the workshop:

| Path | Use when | Coach provides |
| --- | --- | --- |
| Live Azure Container Apps | Teams have Azure access and enough time | Resource group, Container App, ACR, workload identity values, expected endpoint |
| Shared demo target | Only coaches should touch Azure | Screenshots/logs plus a reusable endpoint or run packet |
| Fallback packet | Azure access is blocked | Healthy deployment evidence and degraded deployment evidence with the same fields students would capture |

The live path expects GitHub variables named `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `AZURE_CONTAINER_APP`, `ACR_NAME`, and `ACR_LOGIN_SERVER`.

### Grounding conversation

Students are **expected to call you** before they consider this done.

**Their question:** In your real deployment pipeline, where does the deterministic/probabilistic seam sit today: what does automation decide on its own, and what requires a human approval or deterministic gate before reaching production?

Use these follow-ups:

- Which gate would stop a model-suggested workflow change from reaching production?
- What evidence would an on-call engineer need 30 minutes after this deployment?
- Where would a controlled failure belong in your real pipeline: pre-prod, canary, synthetic monitor, or incident drill?

### Strong Evidence

- Workflow has a validation job and a deployment job.
- Azure authentication uses `azure/login` with workload identity or coach-approved configuration.
- Secrets are not committed, printed, or passed to agent prompts.
- Healthy deployment evidence includes run URL, SHA, endpoint, health status, and checkout status.
- Controlled failure evidence shows `checkout_error` or `checkout_latency` and is clearly labeled as intentional.
- Gate map distinguishes deterministic checks, human approvals, and advisory agent output.

### Common Gaps

- Students treat random Azure permission failures as the main learning activity. Redirect to the fallback packet if access takes more than a few minutes.
- The workflow deploys but no one captures the endpoint or SHA.
- The controlled failure is not labeled, making it look like an accidental outage.
- Teams weaken checks to make the workflow pass.
- Agent-generated YAML is merged without human review.

### Coach Hint

The Azure target is the evidence source, not the puzzle. Keep students focused on a reviewable loop: PR validation, deployment, health evidence, controlled failure evidence, and recovery path.
