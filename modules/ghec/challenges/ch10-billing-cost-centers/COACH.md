# Ch10 — Billing, Cost Centers & Usage — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A sample or safe fallback is a controlled proving ground, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

**Required delivery assurance check:** before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

**Decision prompt:** look at your team's actual GitHub usage right now: where is spend invisible or unattributed, and who in your org should own cost accountability for Actions minutes, Codespaces, or storage but currently does not? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> **Customer implementation preference:** prioritize an authorized customer tenant or artifact over the `ghec-ch10-usage-generator` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Describe who currently reviews your GitHub bill and what detail they can see — down to repo or team level?
- Which repos or teams are the likely top consumers of Actions minutes or Codespaces in your org?
- What cost-center mapping or spending limit would you propose to your finance or platform team this week?

## Delivery assurance notes
- **Customer adoption outcome:** the customer implementation owner builds the org's cost-governance baseline — read usage, generate a little real metered usage, wire a budget with alerts, and reconcile the API against the UI in a repeatable report.
- **Implementation risks to verify:**
  - **Usage data lags.** Generated Actions minutes can take a while to show in billing. If the "after" reading hasn't moved, wait and re-check — it's not a failure.
  - **Budget alerts vs a budget that stops spend.** On the enhanced billing platform these are two settings on the **same** budget. Alerts only **warn/track** (emails are sent automatically at **75%, 90%, and 100%** of the budget); enabling **"stop usage when the budget is reached"** actually **halts** further metered usage. There is no separate "spending limit" feature — the stop control lives on the budget. Make sure they articulate the distinction in Part C.
  - **Billing endpoints + token access.** The billing usage endpoints need the org-owner/billing-manager context; a token without the right access returns 403. Org owners have billing access by default.
  - **Per-minute cost varies by OS/SKU.** Windows and macOS minutes cost more per minute than Linux (the usage API reports a `pricePerUnit` per SKU). Customer implementation owners often forget overage isn't a flat per-minute number across runners.
  - **The new billing platform UI** differs from the legacy one; menu paths may say "Usage" / "Budgets and alerts." Point them at the "viewing your product usage" doc.
- **Delivery lead prompts:** ask "what's the difference between getting *warned* at 90% and being *stopped* at 100%?" and "which runner OS would blow the budget fastest for the same minutes?" (→ macOS).
- **Org-scoped note:** runs with an org + org-owner token; org owners hold billing-manager rights. **Enterprise cost centers are awareness-only** — never required to pass.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Billing baseline read (Part A) | 15 | Before-snapshot from the billing API + UI; included vs metered understood |
| Controlled usage generated (Part B) | 20 | ≥2 Actions runs completed; usage delta observed (allowing for lag) |
| Budgets & alerts (Part C) | 25 | Budget created with alerts enabled (fires at 75/90/100%); budget-alert-vs-stop-usage distinction documented |
| API usage + reconciliation (Part D) | 20 | API total reconciles with UI; usage attributed to a repo; cost model (per-minute price by OS/SKU) explained |
| Cost report (Part E) | 20 | Committed report script produces a product/used/included/billable table; `COST-REPORT.md` with delta + recommendation |
| **Assurance coverage** | **100** | |

## Implementation verification evidence
Use these to verify the customer implementation evidence (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>

# Usage (enhanced billing platform) — the before/after numbers, per-SKU
# Note the path is /organizations/<org>/... and it returns usageItems[]
gh api /organizations/$ORG/settings/billing/usage \
  --jq '[.usageItems[] | select(.product=="Actions")]'

# Aggregate Actions minutes from the usage report
gh api /organizations/$ORG/settings/billing/usage \
  --jq '[.usageItems[] | select(.product=="Actions") | .quantity] | add'

# Prove runs were generated
gh run list --repo $ORG/ghec-ch10-usage-generator --json status,conclusion,createdAt --limit 10

# Confirm the generator workflow exists and is dispatchable
gh api /repos/$ORG/ghec-ch10-usage-generator/actions/workflows --jq '.workflows[].name'

# Confirm the report artifacts were committed
gh api /repos/$ORG/ghec-ch10-cost-report/contents/COST-REPORT.md --jq '.path'
```
- The fastest mastery signal is a **non-zero Actions `quantity`** in the usage report that increased after Part B, paired with `gh run list` showing the runs that caused it.
- Budgets aren't fully exposed via a stable public REST read in every plan — accept a **screenshot / UI walkthrough** of the budget + alert threshold as evidence, plus the written budget-vs-limit distinction.
- For reconciliation, have the customer implementation owner show the API total and the UI Usage total side by side (within lag tolerance).

## Common pitfalls
- **Expecting instant usage updates.** Billing data lags; re-check rather than re-running endlessly.
- **Confusing budget alerts with a stop-usage budget.** Dock points if they can't state which setting *stops* spend (the budget's "stop usage" option, not the alert).
- **Token/access 403 on billing endpoints.** Ensure the account has org-owner/billing-manager access; `gh auth refresh -s admin:org,repo`.
- **Forgetting per-OS pricing** when explaining cost — minutes alone don't equal dollars; `pricePerUnit` differs by SKU.
- **Generating too much usage.** The generator workflow is deliberately tiny; discourage looping it dozens of times.

## References for delivery leads

- [Introduction to billing](https://docs.github.com/en/billing/get-started/introduction-to-billing), [Viewing your product usage](https://docs.github.com/en/billing/managing-billing-for-your-products/viewing-your-product-usage).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch10 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch10 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch10-*` artifacts (prefix-guarded): `ghec-ch10-usage-generator` and `ghec-ch10-cost-report`.
- **Manual cleanup (required):** the **budget and any alert thresholds** the customer implementation owner created are org-level billing settings, **not** `ghec-ch10-*` prefixed, and are **not** reverted by teardown. Delete the budget by hand (**Org Settings → Billing & licensing → Budgets and alerts**) if the org is a reusable sandbox. The **metered usage already incurred is permanent** (it's real billing history) — expected and negligible for the few seconds generated here.

## Time budget
- Setup + baseline read: ~30 min
- Part B (generate usage): ~20 min
- Part C (budgets & alerts): ~45 min
- Part D (API + reconciliation): ~45 min
- Part E (cost report): ~45 min
- Stretch: ~45 min
- **Indicative implementation effort:** ~3–4 hrs across sessions.
