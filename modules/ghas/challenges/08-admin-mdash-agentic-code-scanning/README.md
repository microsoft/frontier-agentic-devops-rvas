# Activity 8: Onboard and operate Codename MDASH

**Session outcome:** Codename MDASH is onboarded against a pilot GitHub repository, has run at least one scan, and its findings are triaged and compared against CodeQL. If preview access isn't available, the Blocked/Assessment-only path produces the same completion evidence from an inline readiness review instead of a live scan.

Codename MDASH is Microsoft's multi-model agentic scanning harness: a preview capability inside Microsoft Defender's Security Exposure Management. It is separate from CodeQL and from the rest of GitHub Advanced Security. It complements CodeQL; it does not replace it, and it does not consume or ingest CodeQL alerts.

Live path: 120 minutes. Assessment-only path: 60 minutes. Neither figure includes preview-enrollment wait time, which this activity cannot predict or control.

## Before you start

Confirm every item below. If you lack preview enrollment, you can still complete the activity through Step 0 and the assessment path.

- Complete `ghas-admin-03`.
- Codename MDASH preview enrollment for your tenant (checked in Step 0).
- A Microsoft Entra **Global Administrator** or **Security Administrator**, authorized to accept the MDASH preview terms.
- An Azure subscription and resource group for a dedicated Microsoft Foundry resource.
- Permission to deploy Azure OpenAI models in that Foundry resource.
- Defender unified RBAC admin access, to assign the agentic code security roles in Step 2.
- GitHub organization owner on the pilot organization.
- A [supported MDASH region](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview#cloud-and-region-support) for the Foundry resource (US, EU, UK, Australia, India, Switzerland, or UAE; UAE supports CLI scans only).
- Access to the [Microsoft Defender portal](https://security.microsoft.com) with permission to open Exposure Management and Initiatives.
- Optional: the Defender CLI and GitHub Copilot CLI installed, for the CLI and remediation paths.

Reuse the pilot repository from `ghas-admin-03` if it already has CodeQL coverage — this activity does not provision a new one.

> **Connector conflict:** if your pilot GitHub organization already has the Azure-portal Defender for Cloud connector from `ghas-admin-07`, read "The connector conflict" below before you create anything in this activity.

## Step 0: Preview eligibility gate

Check whether your tenant has Codename MDASH preview access: open the Defender portal, go to **Exposure Management > Overview**, and look for **Agentic code security**, or go to **Initiatives** and look for **Codename MDASH - Agentic code scanner (preview)**.

**If you see it:** continue to Step 1.

**If you don't see it, or your Entra admin can't confirm enrollment:** stop the live path and complete the assessment-only path below. This is a valid, complete way to finish this activity.

### Blocked / assessment-only path

Work through this table with your security lead. You do not need Defender portal access.

| Readiness item | Status | Evidence or next step |
| --- | --- | --- |
| Preview enrollment request submitted | | Name the date and the Microsoft contact or enrollment form used |
| Entra Global Administrator or Security Administrator identified | | Name the person who would accept preview terms |
| Azure subscription and resource group available for a dedicated Foundry resource | | Name the subscription |
| Model deployment permission confirmed | | Name who can deploy `gpt-5.4`, `gpt-5.3-codex`, `gpt-5.4-mini` |
| Defender unified RBAC admin identified | | Name who would assign the AI Scan Security roles |
| GitHub organization owner identified | | Name the person and organization |
| Supported region selected | | Record the chosen region |
| Pilot repository identified | | Reuse the `ghas-admin-03` repository or name another with CodeQL coverage |
| Connector conflict checked | | Confirm whether `ghas-admin-07`'s connector exists on this organization |

Answer every row and name an owner for enrollment follow-up to complete the assessment-only path. Revisit the live path once enrollment clears.

## Step 1: Accept preview terms

With the Entra Global Administrator or Security Administrator, open the MDASH onboarding flow from **Exposure Management > Overview > Agentic code security** (or **Initiatives > Codename MDASH - Agentic code scanner**). Review the preview terms, select the acceptance checkbox, and confirm you cannot select **Save** until you do.

## Step 2: Connect Microsoft Foundry

With the Azure owner:

1. Create a Microsoft Foundry resource dedicated to MDASH — do not reuse a Foundry resource serving other workloads, since MDASH requires permissive content filtering that other AI workloads should not inherit.
2. Deploy all three required models: `gpt-5.4`, `gpt-5.3-codex`, and `gpt-5.4-mini`. Configure each deployment's Tokens Per Minute (TPM) rate limit to at least 1,000,000 (5,000,000 or higher if you want concurrent scans).
3. Configure a content filter on all three deployments with minimum severity thresholds and Prompt Shields disabled, following [Configure content filtering](https://learn.microsoft.com/en-us/security-exposure-management/mdash-foundry-integration#configure-content-filtering).
4. Choose an authentication method: **Keyless** (recommended, uses managed identity) or **API key**. Copy the project endpoint and the values your chosen method needs.
5. In the Defender onboarding flow, enter the project endpoint, choose the authentication method, select **Validate**, and confirm Defender reports the endpoint is reachable before you **Save**.

Full steps: [Set up Microsoft Foundry for Codename MDASH](https://learn.microsoft.com/en-us/security-exposure-management/mdash-foundry-integration).

## Step 3: Configure Defender unified RBAC

In the Defender portal, go to **System > Permissions > Roles > Create custom role**. Under **Agentic code security > AI Scan Security**, assign the minimum permissions your pilot team needs:

- **Run scan (Manage)** — to trigger on-demand or CLI scans.
- **Upload results (Manage)** — to upload CLI scan results, if you use the optional CLI path.
- **Scan results (Manage)** — to triage, dismiss, or manage findings.
- **Scan results (Read)** — to view findings in the portal and the initiative (read-only; does not grant the full Exposure Management experience on its own).

Assign users and data sources, keeping both **Microsoft Defender for Cloud** and **Microsoft Security Exposure Management** selected, then submit the role.

## Step 4: Create the GitHub connector

In the MDASH initiative, go to **Settings > Agentic code scanning management > Source code environment > Add another > GitHub**. Name the connector, then configure its permission tier:

- **Read** is selected by default and can't be removed — it covers source code, repository metadata, Actions, deployments, and security advisories.
- **Write** is optional and enables issue and pull request creation. **Start with Read only** for this pilot; add Write later only if your rollout plan calls for it.

Authorize the GitHub App against your pilot organization, review the onboarding summary, and select **Activate**.

### The connector conflict

Microsoft's documentation states that **the GitHub App can't be installed on an organization that's already connected through the Azure portal's GitHub connector** (the one `ghas-admin-07` creates). Attempting it produces an error, not a partial connection.

If your pilot organization already has that connector:

- Use a **different** pilot organization for this activity, or
- Disconnect the Azure-portal connector first, following your `ghas-admin-07` rollback plan, and accept that doing so removes that connector's Defender for DevOps capabilities until you reconnect it.

Do not run both connectors against the same organization at once. The platform does not support it; this is not a rate limit or quota issue you can work around.

## Step 5: Discover the repository, then scan it

**Pause here.** After activation, onboarded repositories become available for scanning within up to one hour.

Once the pilot repository appears:

1. In the MDASH initiative, select **Manage scans**.
2. Find your repository in the side panel. Note its size and the tokens-consumed estimate.
3. Select the repository, then **Start scan**.
4. Choose the scan configuration for this run — **Standard** (all three required models) or **MAI Cyber (Preview)**, if you deployed its additional model. A configuration whose models aren't deployed is disabled.
5. Confirm the notification that the scan started, and watch it progress in the **Scans** tab.

## Step 6: Triage findings and compare with CodeQL

Open the finished scan's results in the Defender portal. For each finding, record its severity and confidence score.

Pick at least one finding (or one coverage area, such as a language CodeQL doesn't support) and compare it against your `ghas-admin-03` CodeQL results for the same repository:

| Item | CodeQL | MDASH | Notes |
| --- | --- | --- | --- |
| | | | |

Do not describe MDASH as reading or consuming CodeQL's alert feed — current Microsoft documentation doesn't support that claim. The two results sets stay separate; you're comparing them side by side, not merging them.

## Optional: the Defender CLI path

The CLI path is independent of the GitHub connector — it scans a local clone, not an onboarded repository, and its own results stay separate from the connector-triggered scan above.

```bash
# from a local clone of the pilot repository
defender scan ai-scan submit .
# Output: Job submitted: <JOB_ID>
defender status ai-scan <JOB_ID>
defender status wait <JOB_ID> -o results.sarif
```

Use `--severity high` on `submit` to restrict results to high and critical findings only. Review the downloaded SARIF. Check the Defender portal for an HTML view of the same results if your CLI version offers one. Verify the exact flag in your installed CLI's `--help` output rather than assuming it matches another version. Keep the CLI's output file separate from any portal-triggered scan results so you don't conflate the two runs when reporting.

## Optional: GitHub Copilot CLI remediation

For one triaged finding, use the GitHub Copilot CLI to draft a fix in a local branch. Read the diff, run the affected tests, and open a pull request yourself through the normal review path. Current Microsoft and GitHub documentation does not describe automatic pull request creation from an MDASH finding — treat every fix as something a human drafts, tests, and submits.

## Data handling and ownership

Record before you finish:

- **Token and cost owner:** who monitors Foundry token consumption and TPM usage for the dedicated MDASH resource.
- **Scanned-repository approval:** who approved this specific repository for MDASH scanning.
- **Region:** the region you selected for the Foundry resource and its effect on data residency.
- **Retention caveat:** Microsoft's current documentation does not state an exact retention period for MDASH scan history after a repository or connector is removed. Don't promise participants or stakeholders a specific retention window you can't verify.

## Offboarding

When you're done with the pilot:

1. Remove the pilot repository from the MDASH GitHub connector, or deactivate the connector entirely, from the Defender portal's connector settings.
2. If the Foundry resource was created only for this pilot, stop or delete it along with its model deployments to avoid ongoing token and compute cost.
3. Record that historical scan results may persist in the Defender portal for some time after disconnect — don't claim removal is instant or complete, since Microsoft doesn't document an exact timeline.

## Completion check

**Live path:**
- Preview terms were accepted by an authorized Entra admin.
- The dedicated Foundry resource is connected, validated, and scoped to MDASH only.
- Defender unified RBAC permissions are assigned at the minimum level your pilot team needs.
- The GitHub connector is active with Read-only scope (or Read+Write, with a stated reason), and the connector-conflict check is recorded.
- At least one on-demand scan completed against the pilot repository.
- Findings are triaged by severity and confidence, with a side-by-side comparison against at least one CodeQL result or coverage area.
- Token/cost owner, repository approval, region, and retention caveat are recorded.
- Offboarding steps are recorded, whether or not you exercised them.

**Assessment-only path:**
- Every row in the Step 0 readiness table has a status and a named owner or next step.
- The connector-conflict check against `ghas-admin-07` is recorded even without live access.

## Explicit limits

- Codename MDASH is a **preview** capability. Availability, UI, and commands can change.
- It complements static analysis; it does not replace CodeQL, and CodeQL remains your baseline scanner.
- It does not consume or read CodeQL's alert feed.
- It does not automatically publish findings as native GitHub code-scanning alerts.
- Automatic pull request creation from a finding is not a documented capability — any fix PR in this activity is human-drafted and human-reviewed.

## References

- [Codename MDASH overview](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-overview)
- [Getting started with Codename MDASH](https://learn.microsoft.com/en-us/security-exposure-management/ai-code-security-onboarding)
- [Set up Microsoft Foundry for Codename MDASH](https://learn.microsoft.com/en-us/security-exposure-management/mdash-foundry-integration)
- [Create a GitHub connector for agentic code security](https://learn.microsoft.com/en-us/security-exposure-management/create-github-connector)
- [Trigger an on-demand agentic scan](https://learn.microsoft.com/en-us/security-exposure-management/trigger-on-demand-scan)
- [Install and run Defender CLI](https://learn.microsoft.com/en-us/security-exposure-management/defender-cli)
- [Defender CLI setup for agentic code security](https://learn.microsoft.com/en-us/security-exposure-management/defender-cli-authentication)
- [Run agentic code scans](https://learn.microsoft.com/en-us/security-exposure-management/run-ai-code-security-scans)
