# Activity 7: Connect GitHub security findings to production risk

**Session outcome:** You trace a code scanning or Dependabot alert to the running AKS container workload it ships in. Defender for Cloud supplies the mapping, and GitHub shows `has:deployment` and `runtime-risk:` context on the alert.

This activity needs real Azure and GitHub infrastructure that you provision outside this repository. Start the setup, then return after the mapping finishes. The 105 minutes of active work excludes the multi-day waits.

## What the integration does

Defender for Cloud correlates GitHub's existing code scanning and Dependabot alerts with container registries, AKS workloads, internet exposure, and sensitive-data handling. CodeQL and Dependabot still produce the findings. It doesn't enrich secret-scanning alerts. To turn runtime risk into a campaign, use `ghas-admin-06`.

## Before you start

A missing item blocks the activity. If you can't get one, stop, note the blocker in the adoption issue, and don't mark the session complete.

- Complete `ghas-admin-03` and `ghas-admin-06`, or show equivalent live CodeQL enforcement.
- A **commercial** Azure subscription. The integration isn't available in Azure Government, Azure operated by 21Vianet, or other sovereign clouds.
- Defender Cloud Security Posture Management (CSPM) enabled on that subscription, or permission to enable it.
- Azure Contributor (to create the connector and cloud resources) and Security Admin (to view Defender for Cloud findings).
- GitHub organization owner on the pilot organization.
- GitHub Code Security enabled on the pilot repository, with existing code scanning and Dependabot alerts.
- An Azure Container Registry (ACR) and an AKS cluster, or permission to create them.
- A container image you can build and push from the pilot repository.

If anyone but you owns Azure or the connector, name them now. They also own disconnecting it if the pilot stops.

## Provision the external infrastructure

Do this part outside this repository, with the Azure owner.

1. **Enable Defender CSPM** on the subscription, if it isn't already. See [GitHub Advanced Security integration overview](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-overview) for the full prerequisite table.
2. **Create or select an ACR and an AKS cluster** in the same subscription. Use your organization's standard provisioning path (Azure portal, Bicep, or Terraform).
3. **Build, push, and deploy a container image from the pilot GitHub repository.** Use a real Dockerfile from that repository, push the image to ACR, and run it on AKS. If you don't have a suitable workload, Microsoft publishes a [sandbox project](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy-sandbox) with a prebuilt vulnerable image and deployment manifests. Microsoft maintains it outside this curriculum. We don't ship or test it, and its availability can change. Prefer your own repository and workload.

**Pause here.** Confirm the image is running on AKS and the pilot repository has at least one open code scanning or Dependabot alert before continuing.

## Connect GitHub to Defender for Cloud

With the Azure owner and the GitHub owner together:

1. In the [Azure portal](https://portal.azure.com/), go to **Microsoft Defender for Cloud > Environment settings > Add environment > GitHub**.
2. Name the connector, then select the subscription, resource group, and region.
3. Authorize the connector against your pilot GitHub organization and scope it to the pilot repository (or a small pilot set). Don't onboard all of the organization's repositories.
4. Confirm **Advanced security status** shows **On** for the pilot repository.
5. Turn on agentless scanning for the connector so Defender can discover the repository, registry, and cluster without agents.

Reference: [Connect your GitHub organizations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/quickstart-onboard-github) and [Deploy the GitHub Advanced Security integration](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy).

### Keep the two Defender capabilities separate

Defender for Cloud's agentless scanning discovers your repository, registry, and cluster to build the code-to-runtime map. It finds artifacts. It doesn't look for vulnerabilities in your source. The agentless-scanning toggle in the deployment guide controls this discovery, not runtime-risk correlation. Say so when you report what you enabled.

## Wait for the mapping

Don't poll in a loop. Plan around these windows. None counts toward the session duration.

1. **Repository discovery.** After you activate the connector, discovery can take up to an hour. Confirm the pilot repository appears in the connector's onboarded list.
2. **Full code-to-runtime mapping.** Microsoft's guidance allows up to 24 hours for the registry and cluster scans to finish and link the repository, image, and workload. **Stop here and schedule a return.**
3. **Criticality propagation.** After you mark a resource critical (below), allow up to 12 hours for the signal to reach GitHub's `runtime-risk:` filters.

## Validate the mapping

Once the 24-hour window has passed, open **Microsoft Defender for Cloud > Cloud Security Explorer** (or its current equivalent if Microsoft has renamed it) and run a query for GitHub repositories that push to container images. Then:

1. In Azure Container Registry, confirm Defender scanned the pushed image.
2. Extend the query to include vulnerabilities on that image.
3. Confirm the image is running on the AKS cluster and that Defender scanned the cluster.
4. Search the Defender inventory for your container by name.

If the query returns nothing, check that the image was pushed and deployed, and that the connector has the permissions in [User roles and permissions](https://learn.microsoft.com/en-us/azure/defender-for-cloud/permissions). Rule out a configuration problem before you conclude the feature doesn't work.

## Mark resource criticality and confirm the GitHub-side signal

1. In Defender for Cloud, go to **Settings > Resource criticality** (or mark the container critical directly from the inventory page, if you haven't configured criticality elsewhere).
2. Mark the AKS workload running your pilot image as critical.
3. **Wait up to 12 hours**, then open the pilot repository's code scanning or Dependabot alerts in GitHub and filter with:
   - `has:deployment` — confirms GitHub knows the alert's code shipped in a deployed artifact.
   - `runtime-risk:` — confirms the specific risk factor (internet exposure, sensitive data, critical resource, or lateral movement) that Defender for Cloud supplied.
4. Confirm at least one alert matches both filters.

If no alert shows `runtime-risk:` context after the wait, check that the image deployed to AKS actually corresponds to a commit with open alerts — a clean rebuild between the vulnerable commit and your deployed image won't match.

## Troubleshooting and stop conditions

- **No repositories appear after an hour:** check the GitHub App installation and organization authorization; re-run the connector wizard if needed.
- **Cloud Security Explorer returns nothing after 24 hours:** confirm the image was actually pushed to the connected ACR and the pod is running on the connected AKS cluster, not a different registry or cluster.
- **No `runtime-risk:` filter after 12 hours:** confirm the workload was marked critical, and that the deployed image traces back to a commit with open alerts.
- **Stop the pilot** if the connector can't authorize against the organization, if Azure role assignments can't be obtained, or if the 24-hour mapping window passes with no Cloud Security Explorer results after two retries. Note the blocker in the adoption issue. The session isn't complete.

## Offboarding

If the pilot stops, disconnect the GitHub connector from **Environment settings** in the Azure portal and remove the ACR/AKS resources if you created them only for this activity. Disconnecting stops new correlation. It doesn't erase alerts already in GitHub. Microsoft doesn't document a retention period for Defender-side scan artifacts after disconnect.

## Completion check

- The connector is active and scoped to the pilot repository, not the whole organization.
- Cloud Security Explorer shows the repository, image, and AKS workload linked.
- At least one alert in the pilot repository shows `has:deployment` and a `runtime-risk:` value.

## References

- [GitHub Advanced Security integration with Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-overview)
- [Deploy the GitHub Advanced Security integration](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy)
- [Deploy the integration (sandbox project)](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy-sandbox)
- [Connect your GitHub organizations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/quickstart-onboard-github)
- [About GitHub agentless scanning](https://learn.microsoft.com/en-us/azure/defender-for-cloud/agentless-code-scanning)
- [Prioritizing Dependabot and code scanning alerts using production context](https://docs.github.com/en/code-security/tutorials/secure-your-organization/prioritize-alerts-in-production-code)
- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Creating and managing security campaigns](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns)
