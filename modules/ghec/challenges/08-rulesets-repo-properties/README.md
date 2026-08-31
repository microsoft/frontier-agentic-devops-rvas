# Ch08 — Repository Rulesets & Custom Properties

> Deliver metadata-driven governance across repositories with custom properties, organisation rulesets, repository overlays, and API-verifiable enforcement.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Intermediate *(per-track ramp)* |
| Duration | ~4–5 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Delivery target

- Delivery target: approved custom-property schema, repository classifications, and property-targeted organisation rulesets.
- Safety boundary: activate policy controls in the customer tenant when the organisation owner approves them; otherwise validate targeting and enforcement on the controlled sample and leave a rollout proposal.
- Evidence: retain property inventory, ruleset export, bypass rationale, and enforcement results.
- Owner: the platform governance owner accepts the schema and ruleset; repository owners receive their classifications.
- Next decision: authorise the initial classified repository cohort or decide on the documented rollout proposal.

## Prerequisites
- Recommended: Ch52 (Enterprise Landing Zone & Organization Strategy) completed first — its settings register is the preferred source for enterprise-level property/ruleset decisions (see the closing note); otherwise this activity's organization-level baseline stands on its own.
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch08 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- This activity is independent of Ch05 (which also touches rulesets). The focus here is org-wide governance via custom properties, not the PR pipeline.

## What you will deliver
- Define custom repository properties (single-select and true/false) at the organization.
- Set property values on individual repositories and set defaults for new repos.
- Create an organization ruleset whose target is a property condition (e.g., apply to every repo where `compliance = high`), not a name pattern.
- Combine org rulesets with repository rulesets and understand how they layer (strictest wins).
- Use bypass actors deliberately and document why.
- Verify property values and ruleset enforcement entirely from the REST API.

## Scenario
A GHEC customer has 80 repositories and a compliance team that needs "all production repos must require PRs, signed commits, and a passing check — automatically, forever, even on repos created next week." Naming conventions won't scale and people forget them. You'll attach a `compliance` custom property to repos, then write an org ruleset targeted by that property so governance follows the *metadata*, not the repo name. New repos that get tagged `compliance = high` inherit the rules with zero extra work. That's policy that scales.

> [!IMPORTANT]
> Use an approved customer target (do this first)
>
> Default to an authorised customer production or compliance-sensitive repository set that needs rulesets and properties. Do the work there and keep the evidence, guardrails, or automation.
>
> - Have a candidate? Use your real repos wherever this guide names `ghec-ch08-prod-payments` or the sibling `ghec-ch08-*` repos. Skip the Setup step below entirely.
> - No suitable one? Use the fallback below: seeded prod/internal/sandbox repos for property-targeted guardrails.
>
> Record the selected target, customer governance owner, risk decision, and next action and owner. Use the sample only for testing; move the validated policy to an approved customer organisation.

## Sample test repository or environment
Skip this if you brought your own repo set. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch08 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch08 --org <org>
```

Setup creates these resources (all names use the `ghec-ch08-*` prefix, and teardown is prefix-guarded):
- Four seeded repos — `ghec-ch08-prod-payments`, `ghec-ch08-prod-identity`, `ghec-ch08-internal-tools`, and `ghec-ch08-sandbox` — each with a populated `main` and a CI workflow that emits a `build` status check so required-check rules have something to bind to.
- No custom properties and no rulesets yet — you create them.
- A printed inventory of the four repos (from the API) so you can tag and target them.
- A printed Next steps block telling you where to start.

## Tasks
> Throughout, `ghec-ch08-prod-payments` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

### Part A — Define custom properties
1. Create a single-select property `compliance` with allowed values `high`, `medium`, `low`. Org Settings → Repository → Custom properties → New property (or `gh api -X PUT /orgs/<org>/properties/schema/compliance` with the value definition).
2. Create a true/false property `prod` (default `false`) to flag production repos.
3. Confirm the schema: `gh api /orgs/<org>/properties/schema --jq '.[].property_name'` should list `compliance` and `prod`.

### Part B — Set property values on repos
4. Tag the two prod repos: set `compliance = high` and `prod = true` on `ghec-ch08-prod-payments` and `ghec-ch08-prod-identity` via Settings → Custom properties on each repo, or in bulk:
   ```bash
   gh api -X PATCH /orgs/<org>/properties/values \
     -f 'repository_names[]=ghec-ch08-prod-payments' \
     -f 'repository_names[]=ghec-ch08-prod-identity' \
     -f 'properties[][property_name]=compliance' -f 'properties[][value]=high'
   ```
5. Tag the others lower: `ghec-ch08-internal-tools` → `compliance = medium`; `ghec-ch08-sandbox` → `compliance = low`, `prod = false`.
6. Verify values: `gh api /orgs/<org>/properties/values --jq '.[] | {repository_name, properties}'`.
7. Set a default for new repos (e.g., new repos default to `compliance = low`) so future repos inherit a baseline.

### Part C — Property-targeted organization ruleset
8. Create an org ruleset (Org Settings → Repository → Rulesets → New branch ruleset) named `ghec-ch08-prod-guardrail`. Set the target using a property condition: *include all repositories where `compliance` is `high`* (NOT a name pattern). Target the `main` branch.
9. Add rules: require a pull request (≥1 approval), require the `build` status check, block force pushes, and require signed commits.
10. Set enforcement to Active. Verify: `gh api /orgs/<org>/rulesets --jq '.[] | {name, enforcement, target}'` and then inspect the conditions: `gh api /orgs/<org>/rulesets/<id> --jq '.conditions'` (you should see a `repository_property` condition, not `repository_name`).

### Part D — Layer a repository ruleset
11. On `ghec-ch08-prod-payments` only, add a repository ruleset that's even stricter — e.g., require 2 approvals and require review from Code Owners. 
12. Observe layering: the repo now answers to both the org ruleset (property-targeted) and its own repo ruleset. The most restrictive combination applies (2 approvals from the repo rule beats the org's 1).
13. Prove the org rule reaches a repo by property, not name: confirm `ghec-ch08-prod-identity` (different name, same `compliance = high`) is also governed — attempt a direct push to its `main` and confirm rejection.

### Part E — Verify & demonstrate
14. Demonstrate enforcement: open a PR on `ghec-ch08-prod-payments` and show it cannot merge without 2 approvals + the `build` check + signed commits. Open a PR on `ghec-ch08-sandbox` (compliance `low`) and show it is not gated by the org ruleset.
15. Document the model: write `GOVERNANCE.md` in `ghec-ch08-internal-tools` describing the property schema, which repos carry which values, the org ruleset's property target, and the repo-level overlay.
16. Record the enterprise-level enforcement scope in `GOVERNANCE.md` (whether an enterprise account also defines properties/rulesets that apply across every org and can't be weakened by this org owner): cite Ch52's landing-zone settings register entry, or an authorized enterprise export/inspection; if neither exists, record `enterprise policy not available / not applicable`. Don't infer enterprise-wide enforcement from this one organization's ruleset — see the closing note.

## Reference links
- About custom properties — https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization
- Managing custom properties for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization
- About rulesets — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Creating rulesets for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization
- Managing rulesets for a repository — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository
- Organization custom properties REST API — https://docs.github.com/en/rest/orgs/custom-properties
- Repository rulesets REST API — https://docs.github.com/en/rest/repos/rules
