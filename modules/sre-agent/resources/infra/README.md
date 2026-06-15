# Azure Infrastructure Placeholder

This folder provides a Bicep starting point for Challenge 04 deployment discussion and Challenge 06 SRE response context. It is intentionally conservative: coaches should validate region, naming, policies, identity, and networking before enabling deployment in a customer subscription.

## What It Models

- Azure Container Apps environment for the sample service.
- Log Analytics workspace for operational evidence.
- Container app resource with health probe shape.
- Tags that make workshop resources easy to find and clean up.

## Real Azure Access Required

Running this template against Azure requires an approved subscription, resource group, and identity with deployment permissions. The placeholder deployment workflow does not create Azure resources until coaches replace the final step with authenticated Azure CLI commands and protect the environment in GitHub.

Suggested command after configuration:

```bash
az deployment group create \
  --resource-group "$AZURE_RESOURCE_GROUP" \
  --template-file Resources/infra/main.bicep \
  --parameters appName=<unique-name> containerImage=<registry/image:tag>
```
