# Ch39: Actions secrets and environments

**Session outcome:** The deployment job runs only from an allowed ref after independent environment approval. Rejected runs deploy nothing, and restoring the prior artifact passes its smoke test.

## Prerequisites

- A repository where you have admin rights.
- Approved GitHub CLI authentication for that repository.
- `gh >= 2.x`, `git`, `jq`.
- Never pass secret values to setup scripts or store them in notes or logs.
- An independent environment reviewer.

## Scenario

A deployment workflow uses repository-level secrets, so any job that can reference those names can try to use production credentials. Test protected environments on a non-production target before you move production credentials.

Reuse the Ch04 repository and tested artifact. Pick an existing non-production deployment target and its smoke test. Don't create another application or a production credential. Ch49 covers release publication.

> [!IMPORTANT]
> Use the approved non-production deployment target. If none exists, stop and ask the deployment owner for one. A workflow that only prints a message can't prove deployment or recovery. Leave production controls unchanged.

Set the selected repository before starting:

```bash
export GH_REPO="YOUR-ORG/YOUR-CH04-REPOSITORY"
gh auth status
```

## Tasks

### Part A: List secrets and environments (names only)

1. List secret names and environment protection:
   ```bash
   gh secret list --repo "$GH_REPO"
   gh api "repos/$GH_REPO/environments" --jq '.environments[] | {name,protection_rules}'
   ```
2. Note which workflow uses each secret and which should move to an environment.

### Part B: Protect the environment

3. Pick the approved non-production environment and apply the [shared approval setup](../../resources/environment-approval.md). Restrict it to the intended ref and independent reviewers. Reuse a verified environment instead of configuring another one.
4. Add only the credential the deployment needs, with `gh secret set --env <environment>` or the UI. Prefer OIDC through Ch40 when available. Never add a production secret to a sample repository.
5. Once the workflow works, remove the old repository secret or narrow its scope.
6. Only an explicitly authorized participant changes production environment settings. Don't delegate that to setup automation.

### Part C: Update and test the workflow

7. Add `environment:` to the deployment job and use `needs:` to require the successful job that builds and tests the artifact. Download that run's tested artifact without rebuilding it. Run the customer's deployment command and smoke test. An `echo` step is only practice.

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

    Replace `APPROVED_ENVIRONMENT` first. Review the diff with the deployment owner, then run the checks below.
8. Run from a disallowed branch and confirm the deployment job can't start.
9. Run from the allowed branch and withhold approval. No deployment or step using a secret may run. Reject the run.
10. Start a fresh allowed run. Have the independent reviewer approve it, then verify the deployed revision and smoke test.
11. Redeploy the retained known-good artifact through the same approval gate and repeat the smoke test. Ch49 reuses this recovery run, so don't repeat it there.

**Blocked:** if the plan doesn't support required reviewers for this repository's visibility, note the blocker in the adoption issue and stop. A label or written approval doesn't replace the environment gate, and the session isn't complete.

## Reference links

- [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions)
- [Using environments for deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Actions Secrets REST API](https://docs.github.com/en/rest/actions/secrets)
- [Environments REST API](https://docs.github.com/en/rest/deployments/environments)
