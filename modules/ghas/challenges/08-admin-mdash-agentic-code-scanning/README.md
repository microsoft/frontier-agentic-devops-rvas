# Activity 8: Onboard and operate Codename MDASH

**Session outcome:** Codename MDASH has finished a scan of a pilot GitHub repository, and you've triaged at least one finding against CodeQL.

Codename MDASH is Microsoft's multi-model agentic scanning harness: a preview capability inside Microsoft Defender's Security Exposure Management. It complements CodeQL. It doesn't replace it or ingest CodeQL alerts.

The 120 minutes don't include the preview-enrollment wait or the up-to-one-hour repository discovery wait.

## Before you start

- Complete `ghas-admin-03`.
- Codename MDASH preview enrollment for your tenant (checked in Step 0).
- A Microsoft Entra **Global Administrator** or **Security Administrator**, authorized to accept the MDASH preview terms.
- An Azure subscription and resource group for a dedicated Microsoft Foundry resource, with permission to deploy Azure OpenAI models.
- Defender unified RBAC admin access, to assign the agentic code security roles in Step 3.
- GitHub organization owner on the pilot organization.
- A [supported MDASH region](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview#cloud-and-region-support) for the Foundry resource (US, EU, UK, Australia, India, Switzerland, or UAE; UAE supports CLI scans only).
- Access to the [Microsoft Defender portal](https://security.microsoft.com) with permission to open Exposure Management and Initiatives.
- Optional: the Defender CLI and GitHub Copilot CLI installed, for the CLI and remediation paths.

Reuse the pilot repository from `ghas-admin-03` if it already has CodeQL coverage. This activity doesn't provision a new one.

> **Connector conflict:** if your pilot GitHub organization already has the Azure-portal Defender for Cloud connector from `ghas-admin-07`, read "The connector conflict" below before you create anything.

## Step 0: Preview eligibility gate

To check for Codename MDASH preview access, open the Defender portal, go to **Exposure Management > Overview**, and look for **Agentic code security**, or go to **Initiatives** and look for **Codename MDASH - Agentic code scanner (preview)**.

**If you see it:** continue to Step 1.

**If you don't see it, or your Entra admin can't confirm enrollment:** **Blocked.** Stop, note the blocker in the adoption issue, and resume once enrollment clears. The session isn't complete without a finished scan.

## Step 1: Accept preview terms

With the Entra Global Administrator or Security Administrator, open the MDASH onboarding flow from **Exposure Management > Overview > Agentic code security** (or **Initiatives > Codename MDASH - Agentic code scanner**). Review the preview terms and select the acceptance checkbox. **Save** stays disabled until you do.

## Step 2: Connect Microsoft Foundry

With the Azure owner:

1. Create a Microsoft Foundry resource dedicated to MDASH. Don't reuse one that serves other workloads: MDASH needs permissive content filtering that other AI workloads shouldn't inherit.
2. Deploy all three required models: `gpt-5.4`, `gpt-5.3-codex`, and `gpt-5.4-mini`. Configure each deployment's Tokens Per Minute (TPM) rate limit to at least 1,000,000 (5,000,000 or higher for concurrent scans).
3. Configure a content filter on all three deployments with minimum severity thresholds and Prompt Shields disabled, following [Configure content filtering](https://learn.microsoft.com/en-us/security-exposure-management/mdash-foundry-integration#configure-content-filtering).
4. Choose an authentication method: **Keyless** (recommended, uses managed identity) or **API key**. Copy the project endpoint and the values your chosen method needs.
5. In the Defender onboarding flow, enter the project endpoint, choose the authentication method, select **Validate**, and confirm Defender reports the endpoint is reachable, then **Save**.

Full steps: [Set up Microsoft Foundry for Codename MDASH](https://learn.microsoft.com/en-us/security-exposure-management/mdash-foundry-integration).

## Step 3: Configure Defender unified RBAC

In the Defender portal, go to **System > Permissions > Roles > Create custom role**. Under **Agentic code security > AI Scan Security**, assign only the permissions your pilot team needs:

- **Run scan (Manage)** — to trigger on-demand or CLI scans.
- **Upload results (Manage)** — to upload CLI scan results, if you use the optional CLI path.
- **Scan results (Manage)** — to triage, dismiss, or manage findings.
- **Scan results (Read)** — to view findings in the portal and the initiative (read-only; doesn't grant the full Exposure Management experience on its own).

Assign users and data sources, keeping both **Microsoft Defender for Cloud** and **Microsoft Security Exposure Management** selected, then submit the role.

## Step 4: Create the GitHub connector

In the MDASH initiative, go to **Settings > Agentic code scanning management > Source code environment > Add another > GitHub**. Name the connector, then configure its permission tier:

- **Read** is selected by default and can't be removed — it covers source code, repository metadata, Actions, deployments, and security advisories.
- **Write** is optional and enables issue and pull request creation. **Start with Read only** for this pilot; add Write later only if your rollout plan needs it.

Authorize the GitHub App against your pilot organization, review the onboarding summary, and select **Activate**.

### The connector conflict

Microsoft's documentation states that **the GitHub App can't be installed on an organization that's already connected through the Azure portal's GitHub connector** (the one `ghas-admin-07` creates). Trying it produces an error, not a partial connection.

If your pilot organization already has that connector:

- Use a **different** pilot organization for this activity, or
- Disconnect the Azure-portal connector first, following your `ghas-admin-07` rollback plan, and accept that doing so removes that connector's Defender for DevOps capabilities until you reconnect it.

Don't run both connectors against the same organization at once. The platform doesn't support it, and no rate-limit or quota workaround exists.

## Step 5: Discover the repository, then scan it

**Pause here.** After activation, onboarded repositories can take up to one hour to become available for scanning.

Once the pilot repository appears:

1. In the MDASH initiative, select **Manage scans**.
2. Find your repository in the side panel. Note its size and the tokens-consumed estimate.
3. Select the repository, then **Start scan**.
4. Choose the scan configuration — **Standard** (all three required models) or **MAI Cyber (Preview)**, if you deployed its additional model. A configuration whose models aren't deployed is disabled.
5. Confirm the notification that the scan started, and watch it progress in the **Scans** tab.

## Step 6: Triage findings and compare with CodeQL

Open the finished scan's results in the Defender portal. Review each finding's severity and confidence score.

Triage at least one finding as valid, false positive, or needs follow-up. Then check whether your `ghas-admin-03` CodeQL results for the same repository cover it, and note the answer in the adoption issue. Keep the two result sets separate.

## Optional: the Defender CLI path

The CLI path is independent of the GitHub connector. It scans a local clone, not an onboarded repository, and its results stay separate from the connector-triggered scan above.

```bash
# from a local clone of the pilot repository
defender scan ai-scan submit .
# Output: Job submitted: <JOB_ID>
defender status ai-scan <JOB_ID>
defender status wait <JOB_ID> -o results.sarif
```

Use `--severity high` on `submit` to limit results to high and critical findings. Check the flag in your installed CLI's `--help` output. Review the downloaded SARIF. Keep CLI and portal results separate.

## Optional: GitHub Copilot CLI remediation

For one triaged finding, use the GitHub Copilot CLI to draft a fix in a local branch. Read the diff, run the affected tests, and open the pull request yourself. Automatic pull request creation from an MDASH finding isn't documented.

## Offboarding

1. Remove the pilot repository from the MDASH GitHub connector, or deactivate the connector, in the Defender portal's connector settings.
2. If you created the Foundry resource only for this pilot, delete it with its model deployments to stop token and compute cost.

Historical scan results may persist in the Defender portal after disconnect. Microsoft doesn't document a retention period or removal timeline.

## Completion check

- An authorized Entra admin accepted the preview terms.
- The dedicated Foundry resource is validated and used only by MDASH.
- Defender unified RBAC permissions are the minimum your pilot team needs.
- The GitHub connector is active with Read scope (or Read+Write for a stated reason), and no Azure-portal connector exists on the same organization.
- An on-demand scan finished against the pilot repository.
- At least one finding is triaged and compared with CodeQL.

## Limits

- Codename MDASH is a **preview** capability. Availability, UI, and commands can change.
- It doesn't replace CodeQL, doesn't read CodeQL alerts, and doesn't publish native GitHub code-scanning alerts.

## References

- [Codename MDASH overview](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview)
- [Getting started with Codename MDASH](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-onboarding)
- [Set up Microsoft Foundry for Codename MDASH](https://learn.microsoft.com/en-us/security-exposure-management/mdash-foundry-integration)
- [Create a GitHub connector for agentic code security](https://learn.microsoft.com/en-us/security-exposure-management/create-github-connector)
- [Trigger an on-demand agentic scan](https://learn.microsoft.com/en-us/security-exposure-management/trigger-on-demand-scan)
- [Install and run Defender CLI](https://learn.microsoft.com/en-us/security-exposure-management/defender-cli)
- [Defender CLI setup for agentic code security](https://learn.microsoft.com/en-us/security-exposure-management/defender-cli-authentication)
- [Run agentic code scans](https://learn.microsoft.com/en-us/security-exposure-management/run-ai-code-security-scans)
