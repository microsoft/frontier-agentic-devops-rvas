# Ch40: Actions OIDC with Azure

> Replace long-lived Azure deployment secrets with GitHub Actions OpenID Connect and an explicitly approved Azure federated credential.

| | |
|---|---|
| Track | Automation & AI |
| Difficulty | Advanced |
| Duration | 165 min |
| Minimum input | A GitHub repo + Azure permissions to configure a federated credential. |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Prerequisites

- Repository admin rights in GitHub.
- Azure permission to create or update the chosen identity and federated credential.
- `gh >= 2.x`, `git`, `jq`; Azure CLI is recommended for participant validation.
- No Azure credentials are accepted by setup scripts.

## Scenario

A deployment workflow stores an Azure client secret in GitHub. The customer wants short-lived cloud authentication tied to a specific repository, branch, tag, or environment. Design the OIDC subject, configure Azure manually, update the workflow, and prove that only the approved subject can deploy.

> [!IMPORTANT]
> Use an approved customer target first. If Azure production changes are not approved, complete the sample workflow and produce the Azure trust design as the customer deliverable.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch40 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch40 -Org <org>
```

Setup creates `ghec-ch40-oidc-azure`, a `ghec-ch40-prod` environment when possible, and an OIDC workflow scaffold. It creates no Azure resources, no role assignments, and no secrets.

## Tasks

### Part A — Design the trust boundary

1. Choose the identity model: app registration, service principal, or managed identity.
2. Define the GitHub subject claim, for example `repo:<org>/<repo>:environment:ghec-ch40-prod`.
3. Record tenant ID, subscription, audience, repository, branch/environment restriction, Azure role, and approvers.

### Part B — Configure Azure explicitly

4. Create or select the Azure identity.
5. Add a federated credential matching the approved GitHub subject and audience.
6. Assign the least Azure role needed for the validation action.

### Part C — Configure GitHub workflow

7. Set non-secret configuration variables such as `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` at the repository or environment level.
8. Grant `id-token: write` only to the job that needs Azure authentication.
9. Use `azure/login` with OIDC; do not configure a client secret.

### Part D — Validate and harden

10. Run the workflow from the approved branch or environment and capture the workflow URL.
11. Run or simulate an unauthorized branch/environment and verify Azure denies the token exchange.
12. Remove old Azure client secrets from GitHub after owner approval.

## Reference links

- Configuring OpenID Connect in Azure — https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure
- About security hardening with OpenID Connect — https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- Automatic token authentication — https://docs.github.com/en/actions/tutorials/authenticate-with-github_token
- Azure Login with OpenID Connect — https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
