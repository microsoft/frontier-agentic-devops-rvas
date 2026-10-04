# Ch10: Scoped usage budgets and alerts

This optional session configures one approved product budget. It does not configure enterprise cost centers.

**Session outcome:** You configure the approved budget and verify its alert and stop settings. You compare the usage export with the UI and record any reporting delay.

## Prerequisites
- Authorized billing access to the selected organization and permission to change its test budget.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch10 --org <org>` (least-privilege; for this activity: `admin:org` + `repo`, plus the read access the billing usage endpoints require).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS or Codespaces required. Inspect enterprise cost centers without configuring them. The hands-on work uses org-level billing, budgets, and usage.

## What you will deliver
- Open the org's billing and licensing views and compare included with metered usage for Actions, Packages, and Storage.
- Inspect existing usage, or run the approved short test workload and record any reporting delay.
- Set budgets and confirm their alert thresholds.
- Pull billing/usage data from the REST API and reconcile it against the UI.
- Build a cost report that attributes usage to repositories.
- Keep enterprise cost-center allocation outside this budget exercise.

## Scenario
A GHEC customer's Actions bill exceeded expectations, and finance needs to identify the repositories responsible. Generate a small amount of usage, configure an org budget with alerts, and reconcile the API data against the billing UI. Write an on-demand cost report.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate usage source and reporting repo, use them wherever this guide names `ghec-ch10-usage-generator` or `ghec-ch10-cost-report`, and skip Setup. Otherwise use the fallback seeded repos below, then move the validated budget and report to an approved customer organisation.
>
> Record the selected target, billing owner, and next action.

## Sample test repository or environment
Skip if you brought your own usage/cost artifact.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch10 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch10 --org <org>
```

Setup creates these resources (all names use the `ghec-ch10-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch10-usage-generator` containing a tiny, fast GitHub Actions workflow (`workflow_dispatch`-triggered, a few seconds of runtime) so you can generate a *small* amount of metered Actions usage on demand.
- A seeded repo `ghec-ch10-cost-report` to hold your reconciliation script and the final report.
- A printed current usage snapshot (Actions minutes / storage from the API) so you have a "before" reading.
- A printed Next steps block telling you where to start.

## Tasks

### Part A: Read the billing baseline
1. Open the org billing views (Org Settings → Billing & licensing → Usage). Locate Actions minutes, Packages/Storage, and any Codespaces lines. Note included allowances vs metered overage.
2. Pull usage from the API. Read the current usage snapshot from the enhanced billing platform's usage endpoint, e.g. `gh api /organizations/<org>/settings/billing/usage --jq '[.usageItems[] | select(.product=="Actions")]'` (note: this endpoint is under `/organizations/<org>/...`, and returns per-SKU `usageItems` with `quantity`, `unitType`, `pricePerUnit`, and `netAmount`). Record the Actions and Storage totals as your "before."
3. Read the licensing view (seats consumed) and note where seat cost vs metered service cost differ.

### Part B: Generate controlled usage
4. Run the usage generator twice: `gh workflow run usage.yml --repo <org>/ghec-ch10-usage-generator` (or via the Actions tab → Run workflow). Each run is only seconds of compute.
5. Confirm the runs completed: `gh run list --repo <org>/ghec-ch10-usage-generator --json status,conclusion,createdAt`.
6. Read usage again and identify the repository and SKU when reported. Billing may lag or show no charge within included allowances. Record what you see. Do not run extra workloads to force a charge.

### Part C: Budgets and alerts
7. Create a budget for the org (Org Settings → Billing & licensing → Budgets and alerts → New budget) scoped to Actions (or "all products"). Set a small monetary cap appropriate for a sandbox.
8. Enable alerts on the budget so owners are warned before the cap. On the enhanced billing platform, budget alerts are sent automatically at fixed thresholds of 75%, 90%, and 100%. Confirm the alert recipients.
9. Document the difference between a budget that only alerts (warn/track) and a budget with "stop usage when the budget is reached" enabled (which halts further metered usage). On the enhanced billing platform the stop control is an option on the budget itself, not a separate "spending limit" feature. Decide which you'd use for a production org and why.

### Part D: Usage via the API and reconciliation
10. Pull detailed usage for the current period from the billing API and reconcile the total against the UI's Usage page. The numbers should agree, allowing for lag.
11. Attribute usage to repos: using `gh run list`/run timing across `ghec-ch10-*` repos (or the usage report export from the UI), identify which repo generated the Actions minutes you created.
12. Note the cost model: included minutes are free; overage is billed per-minute at a rate that varies by runner OS/SKU (Linux is cheapest; Windows and macOS cost more per minute). The billing usage API reports a `pricePerUnit` per SKU. Record how the per-minute price differs by runner OS in your report.

### Part E: Build the cost report
13. Export the available usage fields and compare one product total with the UI for the same period. Do not invent included-allowance fields absent from the API.
14. Configure the approved budget scope and amount. Set its recipients and supported stop-usage option, then save the settings. Do not deliberately exhaust the budget.
15. Have the cost owner confirm the configured action and its effect on dependent workflows. Restore the old test budget if this was practice.
16. Link an existing cost-center allocation decision if relevant. Do not configure cost centers or infer enterprise allocation from the organization budget.

## Reference links
- [Introduction to billing](https://docs.github.com/en/billing/get-started/introduction-to-billing)
- [Viewing your product usage](https://docs.github.com/en/billing/managing-billing-for-your-products/viewing-your-product-usage)
- [Budgets and alerts](https://docs.github.com/en/billing/concepts/budgets-and-alerts)
- [About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions)
- [Billing usage REST API](https://docs.github.com/en/rest/billing/usage)
- [Cost centers (awareness)](https://docs.github.com/en/billing/concepts/cost-centers)
