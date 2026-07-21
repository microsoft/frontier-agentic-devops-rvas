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

## Customer delivery target

- Customer objective: apply scalable, metadata-driven governance to the customer repository estate.
- Customer-tenant target: approved custom-property schema, repository classifications, and property-targeted organisation rulesets.
- Approval and safety boundary: activate policy controls in the customer tenant when the organisation owner approves them; otherwise validate targeting and enforcement on the controlled sample and leave a rollout proposal.
- Records to keep: retain property inventory, ruleset export, bypass rationale, and enforcement results.
- Adoption owner / handover: the platform governance owner accepts the schema and ruleset; repository owners receive their classifications.
- Next action and owner: authorise the initial classified repository cohort or decide on the documented rollout proposal.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch08 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- This activity is independent of Ch05 (which also touches rulesets). The focus here is org-wide governance via custom properties, not the PR pipeline.

## Customer delivery objectives
This delivery engagement establishes:
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
> Default to an authorised customer production or compliance-sensitive repository set that needs rulesets and properties. Complete the work on that artifact and retain the evidence, guardrails, or automation.
>
> - Have a candidate? Use your real repos wherever this guide names `ghec-ch08-prod-payments` or the sibling `ghec-ch08-*` repos. Skip the Setup step below entirely.
> - No suitable one? Use the fallback below: seeded prod/internal/sandbox repos for property-targeted guardrails.
>
> Record the selected target, customer governance owner, risk decision, and next action and owner. Use the sample only for testing; move the validated policy to an approved customer organisation.

## Sample test repository or environment (when tenant delivery is constrained)
Skip this if you brought your own repo set. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch08 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch08 --org <org>
```

What setup creates (all artifacts namespaced `ghec-ch08-*`, idempotent, prefix-guarded teardown):
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

### Part F — Governance register: Custom properties & rulesets

Capture the metadata-driven governance model in the register.

1. **Inspect property schema and ruleset targeting.** Pull the org's custom-properties schema: `gh api /orgs/<org>/properties/schema --jq '.[].property_name'`. For each property, pull the values set across repos: `gh api /orgs/<org>/properties/values --jq '.repository_properties'`. Verify that the org ruleset targets repos by property condition (not name pattern). Record the effective level (`org`), implementation path (`approved pilot`), and governance owner name.

2. **Document bypass rationale & enforcement.** List every bypass actor on the org ruleset (who can skip the rules and why) and any repository-ruleset overrides (e.g., higher approval count on production repos). For each, note the risk accepted and the compensating control (e.g., "admins can bypass, compensated by audit log review").

3. **Add governance-register rows.** Add three rows: (i) **Custom repository properties** (domain: `repo-governance`, effective level: `org`, implementation path: `approved pilot`, evidence: schema export + property-values export + `GOVERNANCE.md`), (ii) **Organization rulesets (property-targeted)** (domain: `repo-governance`, effective level: `org`, implementation path: `approved pilot`, evidence: ruleset export + PR enforcement proof + bypass audit), (iii) **Repository-layered rulesets** (domain: `repo-governance`, effective level: `repo`, implementation path: `approved pilot`, evidence: ruleset listing + PR showing stricter enforcement on a high-compliance repo). Identify owner (governance team) and leave Next Decision blank.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] Two custom properties exist (`compliance` single-select, `prod` true/false), verifiable via `gh api /orgs/<org>/properties/schema`.
- [ ] The four repos carry deliberate property values (two prod repos `compliance = high`), verifiable via `gh api /orgs/<org>/properties/values`.
- [ ] An organization ruleset is Active and targets repos by property condition (`repository_property`, not `repository_name`).
- [ ] The org ruleset governs both `high`-compliance repos (proven by a rejected direct push on the second repo).
- [ ] A repository ruleset on one prod repo layers a stricter rule (e.g., 2 approvals) on top of the org ruleset.
- [ ] A `GOVERNANCE.md` documents the schema, values, and ruleset targeting.
- [ ] **Governance register updated:** Added rows for custom repository properties (schema, property values set on repos) and organization rulesets (property-targeted rules, enforcement, bypass logs) with API snapshot links to `/orgs/<org>/properties/schema`, `/orgs/<org>/properties/values`, and `/orgs/<org>/rulesets`.
- [ ] Real-outcome check — if you brought your own repo set, rulesets and properties now protect production or compliance-sensitive work; if you used the sample, you can name the real repo group you will target next.
- [ ] Adoption handover — record the customer governance owner, priority repository risk, proposed property/ruleset control, and next approved action.

> Coaches verify these via the automated hints in `COACH.md`.

## Operational extensions
- Add a property-targeted ruleset that applies org-wide tag protection (block deleting/force-updating release tags) only on `prod = true` repos.
- Write a script that lists every repo and its property values as a Markdown compliance report, generated from `gh api /orgs/<org>/properties/values`.
- Create a second org ruleset targeting `compliance = medium` with a lighter rule set, and show how a repo could match multiple property conditions.

> At enterprise scale (awareness only): An enterprise account can define properties and rulesets that apply across every organization at once, and can prevent org owners from weakening them. In this activity you build the org-level property schema and property-targeted rulesets — the exact same mechanism, scoped to one org, and the day-to-day control surface for an org owner. No enterprise owner is required.

## Reference links
- About custom properties — https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization
- Managing custom properties for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization
- About rulesets — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Creating rulesets for repositories in your organization — https://docs.github.com/en/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization
- Managing rulesets for a repository — https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository
- Organization custom properties REST API — https://docs.github.com/en/rest/orgs/custom-properties
- Repository rulesets REST API — https://docs.github.com/en/rest/repos/rules
