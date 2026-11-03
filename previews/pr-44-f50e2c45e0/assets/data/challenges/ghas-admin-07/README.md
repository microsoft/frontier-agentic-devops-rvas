# Activity 7: Connect GitHub security findings to production risk

**Session outcome:** A code scanning or Dependabot alert in a GitHub repository is traced to the running container workload it ships in. Defender for Cloud supplies that mapping; GitHub shows `has:deployment` and `runtime-risk:` context on the alert, and a campaign filtered on that context is live in the organization.

This activity needs real Azure and GitHub infrastructure that you provision outside this repository. Start setup, allow time for Microsoft's services to propagate the changes, and return one or two days later to finish. The 120 minutes of active work excludes that wait.

## What the integration does

Defender for Cloud correlates GitHub's existing code scanning and Dependabot alerts with container registries, AKS workloads, internet exposure, and sensitive-data handling. CodeQL and Dependabot still produce the findings. A human uses the runtime context to set priorities and create campaigns or GitHub issues; the integration does not publish them automatically.

## Before you start

Confirm every item below before provisioning anything. Any missing item blocks the activity.

- Complete `ghas-admin-03` and `ghas-admin-06`, or show equivalent live CodeQL enforcement and a published campaign.
- A **commercial** Azure subscription. The integration is not available in Azure Government, Azure operated by 21Vianet, or other sovereign clouds.
- Defender Cloud Security Posture Management (CSPM) enabled on that subscription, or permission to enable it.
- Azure Contributor (to create the connector and cloud resources) and Security Admin (to view Defender for Cloud findings) on the subscription.
- GitHub organization owner on the pilot organization, for connector creation and campaigns.
- GitHub Code Security enabled on the pilot repository, with existing code scanning and Dependabot alerts.
- An Azure Container Registry (ACR) and an AKS cluster, or permission to create them.
- A container image you can build and push from the pilot repository.

Name four owners before you provision anything:

| Role | Responsibility |
| --- | --- |
| Azure owner | Creates and owns the connector, ACR, and AKS cluster |
| GitHub owner | Creates the campaign and reviews connector scope |
| Security owner | Confirms runtime-risk evidence and approves campaign priorities |
| Rollback owner | Disconnects the connector and removes cloud resources if the pilot stops |

This integration correlates runtime risk with code. It does not add secret-scanning enrichment — Microsoft's current documentation doesn't describe that alert type for this feature. Artifact attestations are optional context; skip them unless a question needs that detail. CodeQL remains your baseline scanner throughout.

## Provision the external infrastructure

Do this part outside this repository, with the Azure owner.

1. **Enable Defender CSPM** on the subscription, if it isn't already. See [GitHub Advanced Security integration overview](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-overview) for the full prerequisite table.
2. **Create or select an ACR and an AKS cluster** in the same subscription. Use your organization's standard provisioning path (Azure portal, Bicep, or Terraform); this activity does not prescribe one.
3. **Build, push, and deploy a container image from the pilot GitHub repository.** Use a real Dockerfile from that repository, push the image to ACR, and run it on AKS. If you don't have a suitable workload, Microsoft publishes a [sandbox project](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy-sandbox) with a prebuilt vulnerable image and deployment manifests. Microsoft maintains it outside this curriculum; we do not ship or test it, and its availability can change. Prefer your own repository and workload.

**Pause here.** Confirm the image is running on AKS and the pilot repository has at least one open code scanning or Dependabot alert before you continue.

## Connect GitHub to Defender for Cloud

With the Azure owner and the GitHub owner together:

1. In the [Azure portal](https://portal.azure.com/), go to **Microsoft Defender for Cloud > Environment settings > Add environment > GitHub**.
2. Name the connector, then select the subscription, resource group, and region.
3. Authorize the connector against your pilot GitHub organization and scope it to the pilot repository (or a small pilot set). Do not onboard all of the organization's repositories for this activity.
4. Confirm **Advanced security status** shows **On** for the pilot repository.
5. Turn on agentless scanning for the connector so Defender can discover the repository, registry, and cluster without agents.

Reference: [Connect your GitHub organizations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/quickstart-onboard-github) and [Deploy the GitHub Advanced Security integration](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy).

### Keep the two Defender capabilities separate

Defender for Cloud's agentless scanning discovers your repository, registry, and cluster to build the code-to-runtime map. It finds artifacts; it does not look for vulnerabilities in your source. The agentless-scanning toggle in the deployment guide controls this discovery, not runtime-risk correlation. Explain that distinction when reporting what you enabled.

## Pause-and-return checkpoints

Mapping is not instant. Plan your session around these windows, and capture a timestamp as evidence at each one — don't poll in a loop.

1. **Repository discovery.** After you activate the connector, GitHub repository discovery can take up to an hour. Confirm the pilot repository appears in the connector's onboarded list before moving on.
2. **Full code-to-runtime mapping.** Microsoft's guidance allows up to 24 hours for the registry and cluster scans to complete and for the repository, image, and workload to link together. **Stop this session here and schedule a return.**
3. **Criticality propagation.** After you mark a resource critical (next section), allow up to 12 hours for that signal to reach GitHub's `runtime-risk:` filters.

Record each step's completion time alongside a passing validation query.

## Validate the mapping

Once the 24-hour window has passed, open **Microsoft Defender for Cloud > Cloud Security Explorer** (or its current equivalent if Microsoft has renamed it) and run a query for GitHub repositories that push to container images. Then:

1. In Azure Container Registry, confirm Defender scanned the pushed image.
2. Extend the query to include vulnerabilities on that image.
3. Confirm the image is running on the AKS cluster and that Defender scanned the cluster.
4. Search the Defender inventory for your container by name.

If the query returns nothing, check that the image was pushed and deployed, and that the connector has the permissions in [User roles and permissions](https://learn.microsoft.com/en-us/azure/defender-for-cloud/permissions). Check the configuration before concluding that the feature doesn't work.

## Mark resource criticality and confirm the GitHub-side signal

1. In Defender for Cloud, go to **Settings > Resource criticality** (or mark the container critical directly from the inventory page, if you haven't configured criticality elsewhere).
2. Mark the AKS workload running your pilot image as critical.
3. **Wait up to 12 hours**, then open the pilot repository's code scanning or Dependabot alerts in GitHub and filter with:
   - `has:deployment` — confirms GitHub knows the alert's code shipped in a deployed artifact.
   - `runtime-risk:` — confirms the specific risk factor (internet exposure, sensitive data, critical resource, or lateral movement) that Defender for Cloud supplied.
4. Record a screenshot or `gh api` output showing at least one alert with both filters matching, and the timestamp you captured it.

If no alert shows `runtime-risk:` context after the wait, check that the image deployed to AKS actually corresponds to a commit with open alerts — a clean rebuild between the vulnerable commit and your deployed image will not show a match.

## Publish the campaign

A human creates and publishes the campaign in GitHub. Defender for Cloud does not do this step for you.

1. In the pilot organization, go to **Security > Campaigns > Create campaign > From code scanning filters**.
2. Apply the **Runtime Risks** filter alongside your normal severity and repository filters.
3. Assign a campaign manager, set a due date, and add remediation guidance, following the same pattern as `ghas-admin-06`.
4. Publish the campaign and copy its URL and number into your tracking issue.

Reference: [Creating and managing security campaigns](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns).

## Create one GitHub issue from a Defender recommendation

In Defender for Cloud, open a security recommendation tied to your pilot workload and select its **View on GitHub** link, then generate a GitHub issue assignment from the recommendation. Assign the issue to the repository owner you named earlier and confirm the issue carries runtime context (not just the bare CVE). Track the issue's status in both Defender for Cloud and GitHub — Microsoft's current documentation shows both sides reflecting the same status in real time.

## Troubleshooting and stop conditions

- **No repositories appear after an hour:** check the GitHub App installation and organization authorization; re-run the connector wizard if needed.
- **Cloud Security Explorer returns nothing after 24 hours:** confirm the image was actually pushed to the connected ACR and the pod is running on the connected AKS cluster, not a different registry or cluster.
- **No `runtime-risk:` filter after 12 hours:** confirm the workload was marked critical, and that the deployed image traces back to a commit with open alerts.
- **Stop the pilot** if the connector can't authorize against the organization, if Azure role assignments can't be obtained, or if the 24-hour mapping window passes with no Cloud Security Explorer results after two retries. Hand the stop decision and the resource cleanup to the rollback owner.

## Offboarding

When you're done with the pilot, the rollback owner should disconnect the GitHub connector from **Environment settings** in the Azure portal and remove the ACR/AKS resources if they were created only for this activity. Disconnecting the connector stops new correlation. It does not erase alerts or campaign history already recorded in GitHub. Microsoft does not document an exact retention period for Defender-side scan artifacts after disconnect. Confirm cleanup with the Azure owner before closing the tracking issue.

## Completion check

- Four owners are named: Azure, GitHub, security, and rollback.
- The connector is active and scoped to the pilot repository or a small pilot set, not the whole organization.
- Cloud Security Explorer (or its current equivalent) shows the repository, image, and AKS workload linked, with a timestamp.
- At least one alert in the pilot repository shows `has:deployment` and a `runtime-risk:` value, with a timestamp taken after the 12-hour propagation window.
- A published campaign exists, scoped with the Runtime Risks filter, with its URL and number recorded.
- One GitHub issue was created from a Defender recommendation (if your tenant's current flow supports that action), with an assigned owner and status visible in both systems.
- The rollback plan and its owner are recorded, whether or not you exercised it.

## References

- [GitHub Advanced Security integration with Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-overview)
- [Deploy the GitHub Advanced Security integration](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy)
- [Deploy the integration (sandbox project)](https://learn.microsoft.com/en-us/azure/defender-for-cloud/github-advanced-security-deploy-sandbox)
- [Connect your GitHub organizations](https://learn.microsoft.com/en-us/azure/defender-for-cloud/quickstart-onboard-github)
- [About GitHub agentless scanning](https://learn.microsoft.com/en-us/azure/defender-for-cloud/agentless-code-scanning)
- [Prioritizing Dependabot and code scanning alerts using production context](https://docs.github.com/en/code-security/tutorials/secure-your-organization/prioritize-alerts-in-production-code)
- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Creating and managing security campaigns](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/creating-managing-security-campaigns)
