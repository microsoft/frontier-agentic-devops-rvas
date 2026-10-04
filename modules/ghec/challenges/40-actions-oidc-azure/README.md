# Ch40: Actions OIDC with Azure

**Session outcome:** An approved Actions job authenticates to an existing Azure identity with OIDC. A mismatched subject is denied, and a read-only resource check proves the scoped access.

## Prerequisites

- Repository admin rights in GitHub.
- An approved Azure identity with a scoped Reader role, plus its owner's approval for a federated credential. This exercise creates no cloud resources.
- `gh >= 2.x`, `git`, `jq`; Azure CLI is recommended for participant validation.
- No Azure credentials are accepted by setup scripts.

## Scenario

A deployment workflow stores an Azure client secret in GitHub. Test the replacement authentication with a read-only operation against an existing resource before changing deployment credentials.

> [!IMPORTANT]
> Use an existing approved test identity and resource. Without them, keep the reviewed trust design as an assessment and record the blocked token-exchange tests.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch40 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch40 -Org <org>
```

Setup creates `ghec-ch40-oidc-azure`, a `ghec-ch40-prod` environment when possible, and an OIDC workflow scaffold. It creates no Azure resources, no role assignments, and no secrets.

## Tasks

### Part A: Design the trust boundary

1. Choose the identity model: app registration, service principal, or managed identity.
2. Define the GitHub subject claim, for example `repo:<org>/<repo>:environment:ghec-ch40-prod`.
3. Record tenant ID, subscription, audience, repository, branch/environment restriction, Azure role, and approvers.

### Part B: Configure Azure explicitly

4. Select the existing identity and read-only test resource. Stop if none is approved; do not create a subscription, resource group, or service for this session.
5. Have the identity owner add the approved federated credential. For an app registration on GitHub.com, its JSON is:
   ```json
   {
     "name": "github-approved-environment",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:ORG/REPO:environment:ghec-ch40-prod",
     "audiences": ["api://AzureADTokenExchange"]
   }
   ```
   Replace `ORG/REPO` exactly. Use the customer's documented issuer for other GitHub hosts.
6. Confirm the identity's existing Reader role is scoped to the selected resource group. A federated credential establishes authentication; Azure RBAC controls resource access.

### Part C: Configure GitHub workflow

7. Set non-secret configuration variables such as `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` at the repository or environment level.
8. Grant `id-token: write` only to the job that needs Azure authentication.
9. Use `azure/login` with OIDC; do not configure a client secret.

Use this small workflow after replacing variables and approving the action version:

```yaml
name: OIDC access check
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  verify:
    runs-on: ubuntu-latest
    environment: ghec-ch40-prod
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - name: Read approved resource group
        env:
          RESOURCE_GROUP: ${{ vars.AZURE_RESOURCE_GROUP }}
        run: az group show --name "$RESOURCE_GROUP" --query id --output tsv
```

Protect `ghec-ch40-prod` with the Ch39 reviewer and branch restrictions. The environment subject does not include the branch. GitHub's environment rule enforces the branch restriction. This read-only check tests authentication and RBAC, not deployment.

### Part D: Validate and harden

10. Run from a denied branch and confirm the environment gate prevents login. Run from the allowed branch and obtain independent approval. Verify the resource-group ID.
11. On an approved test branch, use a separate test environment with no matching Azure federated credential. Supply the same non-secret IDs and run the workflow. Capture the token-exchange denial. Do not broaden Azure trust to make it pass.
12. Restore the approved workflow and remove the test environment. Remove old client secrets only after any real deployment using them has migrated and its owner approves. No Azure resource is created or deleted by this workflow.

## Reference links

- [Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [About security hardening with OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Automatic token authentication](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token)
- [Azure Login with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
