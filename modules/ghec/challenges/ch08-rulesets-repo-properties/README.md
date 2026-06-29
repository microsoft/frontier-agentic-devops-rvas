# Ch08 — Repository Rulesets & Custom Properties

> By the end of this challenge you can govern many repositories at once: define **custom repository properties**, create **organization rulesets** that **target repos by property**, layer repo-level rules, and verify enforcement from the API — all from an org and an org-owner token.

| | |
|---|---|
| **Track** | Admin/Governance |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~4–5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch08 --org <org>` (least-privilege; for this challenge: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- This challenge is **independent** of Ch05 (which also touches rulesets). The focus here is **org-wide governance via custom properties**, not the PR pipeline.

## Scenario objectives
By completing this challenge you will:
- Define **custom repository properties** (single-select and true/false) at the organization.
- Set property **values** on individual repositories and set **defaults** for new repos.
- Create an **organization ruleset** whose **target** is a **property condition** (e.g., apply to every repo where `compliance = high`), not a name pattern.
- Combine **org rulesets** with **repository rulesets** and understand how they layer (strictest wins).
- Use **bypass actors** deliberately and document why.
- Verify property values and ruleset enforcement entirely from the **REST API**.

## Scenario
A GHEC customer has 80 repositories and a compliance team that needs "all production repos must require PRs, signed commits, and a passing check — automatically, forever, even on repos created next week." Naming conventions won't scale and people forget them. You'll attach a **`compliance` custom property** to repos, then write an **org ruleset targeted by that property** so governance follows the *metadata*, not the repo name. New repos that get tagged `compliance = high` inherit the rules with zero extra work. That's policy that scales.

## Bring your own outcome (do this first)
This challenge is most valuable when the result *outlives the hackathon*. Pick a real production or compliance-sensitive repository set that needs rulesets and properties and complete every task on **that** artifact. You leave with evidence, guardrails, or automation genuinely standing up on something you care about.

- **Have a candidate?** Use your real repos wherever this guide names `wth-ch08-prod-payments` or the sibling `wth-ch08-*` repos. Skip the Setup step below entirely.
- **No suitable one?** Use the fallback below: seeded prod/internal/sandbox repos for property-targeted guardrails.

> Tell your coach which path you took. "Bring your own" is the goal; the sample is the fallback.

## Setup (fallback sample)
Skip this if you brought your own repo set. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch08 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch08 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch08-*`, idempotent, prefix-guarded teardown):
- Four seeded repos — **`wth-ch08-prod-payments`**, **`wth-ch08-prod-identity`**, **`wth-ch08-internal-tools`**, and **`wth-ch08-sandbox`** — each with a populated `main` and a CI workflow that emits a `build` status check so required-check rules have something to bind to.
- **No custom properties and no rulesets yet** — you create them.
- A printed **inventory** of the four repos (from the API) so you can tag and target them.
- A printed **Next steps** block telling you where to start.


## Tasks
> Throughout, **`wth-ch08-prod-payments` is the fallback sample**. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Define custom properties
1. **Create a single-select property** `compliance` with allowed values `high`, `medium`, `low`. **Org Settings → Repository → Custom properties → New property** (or `gh api -X PUT /orgs/<org>/properties/schema/compliance` with the value definition).
2. **Create a true/false property** `prod` (default `false`) to flag production repos.
3. **Confirm the schema:** `gh api /orgs/<org>/properties/schema --jq '.[].property_name'` should list `compliance` and `prod`.

### Part B — Set property values on repos
4. **Tag the two prod repos:** set `compliance = high` and `prod = true` on `wth-ch08-prod-payments` and `wth-ch08-prod-identity` via **Settings → Custom properties** on each repo, or in bulk:
   ```bash
   gh api -X PATCH /orgs/<org>/properties/values \
     -f 'repository_names[]=wth-ch08-prod-payments' \
     -f 'repository_names[]=wth-ch08-prod-identity' \
     -f 'properties[][property_name]=compliance' -f 'properties[][value]=high'
   ```
5. **Tag the others** lower: `wth-ch08-internal-tools` → `compliance = medium`; `wth-ch08-sandbox` → `compliance = low`, `prod = false`.
6. **Verify values:** `gh api /orgs/<org>/properties/values --jq '.[] | {repository_name, properties}'`.
7. **Set a default** for new repos (e.g., new repos default to `compliance = low`) so future repos inherit a baseline.

### Part C — Property-targeted organization ruleset
8. **Create an org ruleset** (**Org Settings → Repository → Rulesets → New branch ruleset**) named `wth-ch08-prod-guardrail`. Set the **target** using a **property condition**: *include all repositories where `compliance` is `high`* (NOT a name pattern). Target the `main` branch.
9. **Add rules:** require a pull request (≥1 approval), require the `build` **status check**, **block force pushes**, and **require signed commits**.
10. **Set enforcement to Active.** Verify: `gh api /orgs/<org>/rulesets --jq '.[] | {name, enforcement, target}'` and then inspect the conditions: `gh api /orgs/<org>/rulesets/<id> --jq '.conditions'` (you should see a `repository_property` condition, not `repository_name`).

### Part D — Layer a repository ruleset
11. **On `wth-ch08-prod-payments` only**, add a **repository ruleset** that's even stricter — e.g., require **2 approvals** and **require review from Code Owners**. 
12. **Observe layering:** the repo now answers to **both** the org ruleset (property-targeted) and its own repo ruleset. The **most restrictive** combination applies (2 approvals from the repo rule beats the org's 1).
13. **Prove the org rule reaches a repo by property, not name:** confirm `wth-ch08-prod-identity` (different name, same `compliance = high`) is also governed — attempt a direct push to its `main` and confirm rejection.

### Part E — Verify & demonstrate
14. **Demonstrate enforcement:** open a PR on `wth-ch08-prod-payments` and show it cannot merge without 2 approvals + the `build` check + signed commits. Open a PR on `wth-ch08-sandbox` (compliance `low`) and show it is **not** gated by the org ruleset.
15. **Document the model:** write `GOVERNANCE.md` in `wth-ch08-internal-tools` describing the property schema, which repos carry which values, the org ruleset's property target, and the repo-level overlay.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] Two **custom properties** exist (`compliance` single-select, `prod` true/false), verifiable via `gh api /orgs/<org>/properties/schema`.
- [ ] The four repos carry **deliberate property values** (two prod repos `compliance = high`), verifiable via `gh api /orgs/<org>/properties/values`.
- [ ] An **organization ruleset** is **Active** and targets repos by **property condition** (`repository_property`, not `repository_name`).
- [ ] The org ruleset governs **both** `high`-compliance repos (proven by a rejected direct push on the second repo).
- [ ] A **repository ruleset** on one prod repo layers a stricter rule (e.g., 2 approvals) on top of the org ruleset.
- [ ] A **`GOVERNANCE.md`** documents the schema, values, and ruleset targeting.
- [ ] Real-outcome check — if you brought your own repo set, rulesets and properties now protect production or compliance-sensitive work; if you used the sample, you can name the real repo group you will target next.
- [ ] Coach conversation — which of your repos is most likely to accept a direct push to main or merge without a review right now, and what ruleset targeting which repo property would close that gap at scale? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Add a property-targeted ruleset that applies **org-wide tag protection** (block deleting/force-updating release tags) only on `prod = true` repos.
- Write a script that lists every repo and its property values as a Markdown compliance report, generated from `gh api /orgs/<org>/properties/values`.
- Create a **second org ruleset** targeting `compliance = medium` with a lighter rule set, and show how a repo could match multiple property conditions.

> **At enterprise scale (awareness only):** An **enterprise account** can define properties and rulesets that apply across **every organization** at once, and can prevent org owners from weakening them. In this challenge you build the **org-level** property schema and property-targeted rulesets — the exact same mechanism, scoped to one org, and the day-to-day control surface for an org owner. No enterprise owner is required.

## Reference links
- About custom properties — https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization
- Managing custom properties for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization
- About rulesets — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Creating rulesets for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization
- Managing rulesets for a repository — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository
- Organization custom properties REST API — https://docs.github.com/en/rest/orgs/custom-properties
- Repository rulesets REST API — https://docs.github.com/en/rest/repos/rules
