# Ch10 — Billing, Cost Centers & Usage

> By the end of this challenge you can read and govern an organization's spend — inspect **Actions/Packages/Storage usage**, set **budgets with alerts** (including budgets that stop spend), pull **billing usage from the API**, and produce a cost report — all from an org and an org-owner token.

| | |
|---|---|
| **Track** | Admin/Governance |
| **Difficulty** | Advanced *(per-track ramp)* |
| **Duration** | ~3–4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | none |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud, with **billing manager** access (org owners have it by default).
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch10 --org <org>` (least-privilege; for this challenge: `admin:org` + `repo`, plus the read access the **billing usage** endpoints require).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS or Codespaces required. **Enterprise cost centers** are awareness-only here (see callout) — the real, gradable work uses **org-level billing, budgets, and usage**.

## Scenario objectives
By completing this challenge you will:
- Navigate the org's **billing & licensing** views and read **included vs metered** usage for Actions, Packages, and Storage.
- Generate a **small, controlled amount of metered usage** (a few Actions runs) and watch it appear in usage.
- Set **budgets with alert thresholds** so spend can't surprise you.
- Pull **billing/usage data from the REST API** and reconcile it against the UI.
- Build a **cost report** that attributes usage to repositories.
- Understand where **enterprise cost centers** allocate spend across orgs (awareness) and why org-level budgets are the org-owner equivalent.

## Scenario
A GHEC customer just got a bigger-than-expected Actions bill and nobody can explain it. Finance wants guardrails: a budget with an alert before money is spent, a clear view of which repos burn the most minutes, and a report they can pull on demand. You'll stand up exactly that at the **organization** level — generate a little real usage, wire up a budget with alerts, and reconcile the API against the billing UI so the numbers are trustworthy. The output is the cost-governance baseline a real customer keeps.

> [!IMPORTANT]
> **Bring your own outcome (do this first)**
>
> This challenge is most valuable when the result *outlives the delivery session*. Pick a real org usage, budget, or cost-reporting artifact someone will rely on after the delivery session and complete every task on **that** artifact. You leave with evidence, guardrails, or automation genuinely standing up on something you care about.
>
> - **Have a candidate?** Use your real usage source and reporting repo wherever this guide names `ghec-ch10-usage-generator` or `ghec-ch10-cost-report`. Skip the Setup step below entirely.
> - **No suitable one?** Use the fallback below: a tiny usage-generator repo and cost-report repo for safe metered practice.
>
> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own usage/cost artifact. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch10 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch10 --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch10-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`ghec-ch10-usage-generator`** containing a tiny, fast **GitHub Actions workflow** (`workflow_dispatch`-triggered, a few seconds of runtime) so you can generate a *small* amount of metered Actions usage on demand.
- A seeded repo **`ghec-ch10-cost-report`** to hold your reconciliation script and the final report.
- A printed **current usage snapshot** (Actions minutes / storage from the API) so you have a "before" reading.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`ghec-ch10-usage-generator` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Read the billing baseline
1. **Open the org billing views** (**Org Settings → Billing & licensing → Usage**). Locate **Actions minutes**, **Packages/Storage**, and any **Codespaces** lines. Note included allowances vs metered overage.
2. **Pull usage from the API.** Read the current usage snapshot from the enhanced billing platform's usage endpoint, e.g. `gh api /organizations/<org>/settings/billing/usage --jq '[.usageItems[] | select(.product=="Actions")]'` (note: this endpoint is under `/organizations/<org>/...`, and returns per-SKU `usageItems` with `quantity`, `unitType`, `pricePerUnit`, and `netAmount`). Record the Actions and Storage totals as your "before."
3. **Read the licensing view** (seats consumed) and note where seat cost vs metered service cost differ.

### Part B — Generate a little controlled usage
4. **Run the usage generator** twice: `gh workflow run usage.yml --repo <org>/ghec-ch10-usage-generator` (or via the Actions tab → Run workflow). Each run is only seconds of compute.
5. **Confirm the runs completed:** `gh run list --repo <org>/ghec-ch10-usage-generator --json status,conclusion,createdAt`.
6. **Re-read usage** from Part A's API call and confirm Actions minutes **increased**. Usage data can lag — note that and re-check if needed.

### Part C — Budgets & alerts
7. **Create a budget** for the org (**Org Settings → Billing & licensing → Budgets and alerts → New budget**) scoped to **Actions** (or "all products"). Set a small monetary cap appropriate for a sandbox.
8. **Enable alerts** on the budget so owners are warned **before** the cap. On the enhanced billing platform, budget alerts are sent automatically when usage reaches **75%, 90%, and 100%** of the budget (these thresholds are fixed, not custom percentages) — confirm the alert recipients.
9. **Document the difference** between a budget that **only alerts** (warn/track) and a budget with **"stop usage when the budget is reached"** enabled (which halts further metered usage). On the enhanced billing platform the stop control is an option on the budget itself, not a separate "spending limit" feature. Decide which you'd use for a production org and why.

### Part D — Usage via the API & reconciliation
10. **Pull the detailed usage** for the current period from the billing API and reconcile the total against the UI's Usage page — the numbers should agree (allowing for lag).
11. **Attribute usage to repos:** using `gh run list`/run timing across `ghec-ch10-*` repos (or the usage report export from the UI), identify which repo generated the Actions minutes you created.
12. **Note the cost model:** included minutes are free; overage is billed per-minute at a rate that varies by runner OS/SKU (Linux is cheapest; Windows and macOS cost more per minute). The billing usage API reports a `pricePerUnit` per SKU — record how the per-minute price differs by runner OS in your report.

### Part E — Build the cost report
13. **Write a reconciliation script** (`cost-report.sh` or `.ps1`, committed to `ghec-ch10-cost-report`) that pulls the billing usage endpoints and prints a small table: product, used, included, billable.
14. **Run it** and save the output as `COST-REPORT.md`, including the before/after Actions-minutes delta you generated in Part B.
15. **Write a one-paragraph recommendation**: given the usage shape, what budget + alert thresholds would you set for this org, and would you add a hard spending limit?

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] A **before** usage snapshot was captured from the billing **API** (Actions minutes + storage).
- [ ] At least **two Actions runs** were generated and **usage increased** (verifiable via `gh run list` + the billing API delta).
- [ ] A **budget** is configured at the org with at least one **alert threshold** below the cap.
- [ ] You can **reconcile** the API usage total against the UI Usage page and explain the cost model (included vs metered; per-minute price varies by runner OS/SKU).
- [ ] A committed **cost-report script** runs and produces a product/used/included/billable table.
- [ ] A **`COST-REPORT.md`** exists with the before/after delta and a budget recommendation.
- [ ] Real-outcome check — if you brought your own usage data, a real budget or cost report now exists for someone to use; if you used the sample, you can name the org/team cost view you will build next.
- [ ] Coach conversation — look at your team's actual GitHub usage right now: where is spend invisible or unattributed, and who in your org should own cost accountability for Actions minutes, Codespaces, or storage but currently does not? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Schedule the cost-report script as a **GitHub Actions workflow** that runs monthly and uploads `COST-REPORT.md` as an artifact.
- Add **Packages/Storage** and **Codespaces** lines to the report so it covers every metered product, not just Actions.
- Model a **chargeback**: split the generated Actions minutes across two notional teams and show how you'd bill each — the org-level rehearsal for enterprise cost centers.

> **At enterprise scale (awareness only):** On the **enhanced billing platform**, **cost centers** allocate and bill usage to specific business units. Enterprise owners and billing managers can create cost centers spanning multiple organizations; **organization owners can also create cost centers for resources within their own org**. Cost centers and enterprise-wide budgets are awareness-only here and out of scope as a requirement. The org-level budgets, alerts, and usage reconciliation you build are the same discipline scoped to one org — exactly what an org owner controls day to day. No enterprise owner is required.

## Reference links
- Introduction to billing — https://docs.github.com/en/billing/get-started/introduction-to-billing
- Viewing your product usage — https://docs.github.com/en/billing/managing-billing-for-your-products/viewing-your-product-usage
- Budgets and alerts — https://docs.github.com/en/billing/concepts/budgets-and-alerts
- About billing for GitHub Actions — https://docs.github.com/en/billing/managing-billing-for-your-products/about-billing-for-github-actions
- Billing usage REST API — https://docs.github.com/en/rest/billing/usage
- Cost centers (awareness) — https://docs.github.com/en/billing/concepts/cost-centers
