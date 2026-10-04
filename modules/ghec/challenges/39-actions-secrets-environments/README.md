# Ch39: Actions secrets and environments

**Session outcome:** The deployment job runs only from an allowed ref after independent environment approval. Rejected runs deploy nothing, and restoring the prior artifact passes its smoke test.

## Prerequisites

- An organization and repository where you have repository admin rights.
- Approved GitHub CLI authentication for the selected repository.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- Never pass secret values to setup scripts or store them in lesson evidence.

## Scenario

A deployment workflow uses repository-level secrets. Any job that can reference those names can try to use production credentials. Inventory the secrets without exposing values. Move deployment credentials to protected environments, then prove that reviewers and branch rules gate production access.

Reuse the Ch04 repository and tested artifact. Choose an existing non-production deployment target and its smoke test. Do not create another application or a production credential for this exercise. Ch49 separately handles release publication.

> [!IMPORTANT]
> Use the approved non-production deployment target. If none is available, stop and ask the deployment owner for one. An empty repository or a workflow that prints a message cannot prove deployment or recovery. Leave production controls unchanged.

Set the selected repository before starting:

```bash
export GH_REPO="YOUR-ORG/YOUR-CH04-REPOSITORY"
gh auth status
```

## Tasks

### Part A: Inventory without exposing values

1. Snapshot repository secret metadata:
   ```bash
   gh secret list --repo "$GH_REPO"
   ```
2. Snapshot environment names and protection settings:
   ```bash
   gh api "repos/$GH_REPO/environments" --jq '.environments[] | {name,protection_rules}'
   ```
3. Record each secret name, scope, consumer workflow, owner, rotation cadence, and whether it should be repository, environment, or organization scoped.

### Part B: Design environment protection

4. Choose the approved non-production deployment environment and apply the [shared approval setup](../../resources/environment-approval.md). Restrict it to the intended ref and independent reviewers. Reuse a verified environment rather than configuring another one to repeat the same setup.
5. Keep production environment settings as an explicit participant action; do not delegate broad production changes to setup automation.
6. Record what secrets move to each environment and which jobs are allowed to reference them.

### Part C: Configure environments and secrets

7. Configure protected environments in the repository UI or API.
8. Add only a credential the approved deployment needs using `gh secret set --env <environment>` or the UI. Prefer OIDC through Ch40 when available. Never add a production secret to a sample repository.
9. Remove or de-scope old repository secrets after workflow migration and approval.

### Part D: Update and validate workflows

10. Add `environment:` to the deployment job and use `needs:` to require the successful job that builds and tests the artifact. Download that run's tested artifact without rebuilding it. Run the customer's deployment command and smoke test. An `echo` step is only practice.

    If you need help adapting the existing workflow, use this prompt in its repository:

    ```text
    Inspect the existing CI, deployment command, and smoke test. Update the
    workflow to deploy only the artifact built and tested in the same run.
    Put environment: APPROVED_ENVIRONMENT on the deployment job and require
    the successful build with needs. Download the build's exact artifact ID;
    do not rebuild in the deployment job. Keep credentials in that environment
    and use the existing deployment command and smoke test. Preserve a route
    to deploy the retained known-good artifact through the same approval gate.
    Do not invent credentials, an application, or a deployment destination.
    Show the diff and identify missing commands or permissions before editing.
    ```

    Replace `APPROVED_ENVIRONMENT` first. Review the diff with the deployment owner and run the refusal, approval, and recovery checks below. A generated workflow is not completion evidence.
11. Run from a disallowed branch and confirm the deployment job cannot start. Run from the allowed branch and withhold approval. Verify that no deployment or step using a secret runs. Reject this run and keep its result.
12. Start a fresh allowed run. Have the independent reviewer approve it, then verify the deployed revision and smoke test. Capture the run and environment deployment record.
13. Redeploy the retained known-good artifact through the same approval gate and repeat the smoke test. Keep these recovery results for Ch49; do not repeat the deployment exercise there.

If the plan does not support required reviewers for this repository visibility, record the capability as blocked. A label or written approval does not replace the environment gate. See [completion evidence](../../../README.md#completion-evidence).

## Reference links

- [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- [Using environments for deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Actions Secrets REST API](https://docs.github.com/en/rest/actions/secrets)
- [Environments REST API](https://docs.github.com/en/rest/deployments/environments)
