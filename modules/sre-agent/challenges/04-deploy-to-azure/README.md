# Challenge 04: Deploy to Azure with GitHub Actions

## Scenario

The team has established a GitHub workflow and used Copilot and agents to improve the service. Now stakeholders want proof that changes can move through a repeatable path into an Azure-hosted runtime with appropriate gates.

Your mission is to build or complete a CI/CD path that validates a pull request, deploys to Azure, and captures enough runtime evidence for an operations handoff.

This is where the deterministic/probabilistic seam becomes visible. Agents and Copilot can propose workflow changes, but tests, schemas, permissions, environment protection, and human approvals decide what reaches Azure.

## Goals

- Create or improve a GitHub Actions workflow for build/test validation.
- Add an Azure deployment step using workshop-provided environment details.
- Use GitHub Environments, secrets, approvals, or protection rules where available.
- Verify the deployed service and capture runtime evidence.
- Produce a deployment record that supports later incident response.
- Identify which deployment decisions are deterministic gates and which are agent-assisted recommendations.

## Estimated Time

75 minutes.

## Tasks

1. Review the deployment target and credentials or federated identity approach provided by the coach.
2. Inspect existing workflow files, if any, and identify missing build/test/deploy stages.
3. Add or update a GitHub Actions workflow for pull request validation.
4. Add or update a deployment workflow for the Azure target.
5. Configure environment protection or approval if the workshop repository supports it.
6. Mark the seam in your pull request or deployment note: model proposes, deterministic substrate disposes. List the tests, schemas, allowlists, permissions, approval gates, and human checkpoints that decide whether the deployment proceeds.
7. Run the workflow and inspect logs, artifacts, and deployment status.
8. Validate the running service endpoint or review the coach-provided deployment evidence packet.
9. Record deployment evidence for Challenge 06: commit SHA, run link, environment, endpoint, warnings, and gate outcomes.

## Success Criteria

- A workflow validates pull requests or the main branch.
- Deployment to Azure runs successfully, or the team uses the documented fallback packet when access is blocked.
- Secrets or credentials are not exposed in logs or committed files.
- Environment controls are visible, even if simplified for the workshop.
- The team captures deployment evidence that can be used during incident triage.
- The team can explain what an agent is allowed to suggest and what only deterministic gates or humans can authorize.

## Hints

- Prefer workload identity or approved secret patterns provided by the coach. Do not invent credentials.
- Keep the workflow readable. Future operators need to understand what happened.
- If deployment fails, inspect logs and create a remediation issue. That still supports the learning path.
- Capture links and timestamps now. Incident response is harder when evidence is reconstructed later.
- Do not put secrets in prompts or agent runtime. Use scoped permissions and safe outputs.
- Treat the workflow file as executable governance, not just automation glue.

## Coach Validation Checkpoints

- Ask the team to show the workflow run and explain each stage.
- Check that no secret values appear in committed files or logs.
- Confirm the deployment target or fallback evidence is recorded.
- Ask what signal proves the deployed service is healthy.
- Ask where the deterministic/probabilistic seam appears in this pipeline.
- Decide whether the team should proceed hands-on to Challenge 05/06 or switch to simulation packets.

## Deliverables

- GitHub Actions workflow for validation and deployment, or documented use of a coach-provided baseline.
- Deployment evidence note with run link, commit SHA, environment, and endpoint or simulated endpoint.
- Gate map showing tests, schemas, allowlists, approvals, permissions, and human checkpoints.
- Follow-up issue for any deployment risk discovered.
