# Ch10: Scoped usage budgets and alerts

This optional session doesn't set up enterprise cost centers.

**Session outcome:** You set the approved budget and check its alert and stop settings. You compare the usage export with the UI and record any reporting delay.

## Prerequisites
- Billing access to the organization and permission to change its test budget.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch10 --org <org>` (least privilege; here: `admin:org` + `repo`, plus the read access the billing usage endpoints need).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS or Codespaces needed. Look at enterprise cost centers but don't configure them. The hands-on work uses org-level billing, budgets, and usage.

## What you will deliver
- Open the org's billing and licensing views and compare included with metered usage for Actions, Packages, and Storage.
- Read existing usage, or run the approved short test workload and record any reporting delay.
- Set budgets and confirm their alert thresholds.
- Compare billing and usage data from the REST API with the UI.
- Build a cost report that attributes usage to repositories.
- Leave enterprise cost-center allocation out of this exercise.

## Scenario
A GHEC customer's Actions bill exceeded expectations, and finance needs to identify the repositories responsible. Generate a small amount of usage, set an org budget with alerts, and reconcile the API data with the billing UI. Write a cost report you can run on demand.

> [!IMPORTANT]
> Use a customer usage source and reporting repo if you have them: use them wherever this guide names `ghec-ch10-usage-generator` or `ghec-ch10-cost-report`, and skip Setup. Otherwise test with the seeded repos below, then apply the budget and report to the customer organisation.
>
> Record the target, the billing owner, and the next action.

## Sample test repository or environment
Skip if you have a usage source and reporting repository.

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
- A current usage snapshot of Actions minutes and storage from the API for comparison.

## Tasks

### Part A: Read the billing baseline
1. Open the org billing views (Org Settings → Billing & licensing → Usage). Locate Actions minutes, Packages/Storage, and any Codespaces lines. Note included allowances and metered overage.
2. Pull usage from the API, using the enhanced billing platform's usage endpoint, e.g. `gh api /organizations/<org>/settings/billing/usage --jq '[.usageItems[] | select(.product=="Actions")]'` (the endpoint is under `/organizations/<org>/...` and returns per-SKU `usageItems` with `quantity`, `unitType`, `pricePerUnit`, and `netAmount`). Record the Actions and Storage totals as your "before."
3. Read the licensing view (seats consumed) and separate seat costs from metered service costs.

### Part B: Generate controlled usage
4. Run the usage generator twice: `gh workflow run usage.yml --repo <org>/ghec-ch10-usage-generator` (or via the Actions tab → Run workflow). Each run is only seconds of compute.
5. Confirm the runs completed: `gh run list --repo <org>/ghec-ch10-usage-generator --json status,conclusion,createdAt`.
6. Read usage again and note the repository and SKU, if reported. Billing can lag, or show no charge within included allowances. Record what you see. Don't run extra workloads to force a charge.

### Part C: Budgets and alerts
7. Create a budget for the org (Org Settings → Billing & licensing → Budgets and alerts → New budget) scoped to Actions (or "all products"). Set a small monetary cap, sized for a sandbox.
8. Enable alerts so owners get a warning before the cap. On the enhanced billing platform, budget alerts go out automatically at fixed thresholds of 75%, 90%, and 100%. Confirm the alert recipients.
9. Write down the difference between a budget that only alerts and one with "stop usage when the budget is reached" enabled, which halts further metered usage. On the enhanced billing platform, the stop control is an option on the budget, not a separate "spending limit" feature. Decide which you'd use for a production org and why.

### Part D: Usage via the API and reconciliation
10. Pull detailed usage for the current period from the billing API and reconcile the total against the UI's Usage page. The numbers should agree, give or take reporting lag.
11. Attribute usage to repos: use `gh run list` and run timing across `ghec-ch10-*` repos (or the usage report export from the UI) to find which repo generated the Actions minutes you created.
12. Note the cost model: included minutes are free, and overage is billed per minute at a rate that depends on the runner OS and SKU (Linux is cheapest; Windows and macOS cost more). The billing usage API reports a `pricePerUnit` per SKU. Record in your report how the per-minute price differs by runner OS.

### Part E: Build the cost report
13. Export the usage fields the API gives you and compare one product total with the UI for the same period. Don't invent included-allowance fields the API lacks.
14. Set the approved budget scope and amount. Set its recipients and the stop-usage option, then save. Don't try to exhaust the budget.
15. Have the cost owner confirm what the budget does and how it affects dependent workflows. If this was practice, restore the old test budget.
16. If one exists, link the cost-center allocation decision. Don't configure cost centers or infer enterprise allocation from the organization budget.

## Reference links
- [Introduction to billing](https://docs.github.com/en/billing/get-started/introduction-to-billing)
- [Viewing your product usage](https://docs.github.com/en/billing/managing-billing-for-your-products/viewing-your-product-usage)
- [Budgets and alerts](https://docs.github.com/en/billing/concepts/budgets-and-alerts)
- [About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions)
- [Billing usage REST API](https://docs.github.com/en/rest/billing/usage)
- [Cost centers (awareness)](https://docs.github.com/en/billing/concepts/cost-centers)
