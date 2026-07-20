# Ch08 — Repository Rulesets & Custom Properties — Coach Guide

> Audience: facilitators and graders. Pair with the delivery team member `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the customer practitioner to connect the exercise to work they actually own.

**Their question:** Coach conversation — which of your repos is most likely to accept a direct push to main or merge without a review right now, and what ruleset targeting which repo property would close that gap at scale? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer customer delivery team members who ran this on a **real artifact they own** over the `ghec-ch08-prod-payments` sample. If they used the sample, confirm they can name the actual repo, team, project, or workflow they'll apply this to and any blockers. The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- Pick the riskiest repo in your org — what's protecting its default branch today?
- If rulesets with repo property targeting existed in your org yesterday, which incident or near-miss would they have prevented?
- What is the smallest ruleset you could define and the property you'd attach it to, to cover your highest-risk repos first?

## Facilitation notes
- **Goal in one line:** the delivery team member makes governance follow **metadata** instead of repo names — custom properties drive a property-targeted org ruleset that automatically governs any repo tagged for compliance, now or in the future.
- **Where customer delivery team members get stuck:**
  - **Property target vs name pattern.** The whole lesson is the **`repository_property`** condition. Customer delivery team members reflexively use a name pattern (`ghec-ch08-prod-*`) — that's Ch05's mechanism and misses the point here. Insist on the property condition.
  - **Bulk property values API shape.** The `/orgs/<org>/properties/values` PATCH takes an array of repos and an array of property objects; the nested `-f` syntax is fiddly. The UI is a fine fallback for setting values.
  - **Layering = strictest wins.** When the org rule (1 approval) and the repo rule (2 approvals) both apply, 2 wins. Customer delivery team members expect one to "override"; both apply and the maximum constraint holds.
  - **Signed-commit rule needs signing set up.** If they require signed commits but push unsigned, the rejection is *correct* — demonstrate the gate, then optionally show a signed push.
- **How to unblock without giving the answer:** ask "what makes a repo created next week automatically inherit these rules without anyone editing the ruleset?" (→ the property condition + a default value) and "if two rulesets disagree on approval count, which number applies?" (→ the larger).
- **Org-scoped note:** runs with an org + org-owner token. `admin:org` is required to define properties and org rulesets. No enterprise owner needed.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Custom properties defined (Part A) | 20 | `compliance` single-select + `prod` true/false in the org schema |
| Property values set (Part B) | 20 | Four repos tagged deliberately; prod repos `compliance = high`; a default for new repos |
| Property-targeted org ruleset (Part C) | 30 | Active org ruleset with a `repository_property` condition; PR + status check + force-push block + signed commits |
| Repo ruleset layering (Part D) | 15 | One prod repo adds a stricter rule; layering (strictest wins) explained; second repo governed by property proven |
| Verify & document (Part E) | 15 | Enforcement demonstrated on a high repo and absent on a low repo; `GOVERNANCE.md` written |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>

# Property schema (expect compliance + prod)
gh api /orgs/$ORG/properties/schema --jq '.[] | {property_name, value_type}'

# Property values per repo
gh api /orgs/$ORG/properties/values --jq '.[] | {repository_name, properties}'

# Org rulesets + the all-important condition type
gh api /orgs/$ORG/rulesets --jq '.[] | {name, enforcement, target}'
RID=$(gh api /orgs/$ORG/rulesets --jq '.[] | select(.name=="ghec-ch08-prod-guardrail") | .id')
gh api /orgs/$ORG/rulesets/$RID --jq '.conditions'        # expect a repository_property condition, NOT repository_name
gh api /orgs/$ORG/rulesets/$RID --jq '.rules[].type'      # pull_request, required_status_checks, non_fast_forward, required_signatures

# Repo-level ruleset overlay on the strict repo
gh api /repos/$ORG/ghec-ch08-prod-payments/rulesets --jq '.[] | {name, enforcement}'
```
- The single fastest mastery signal is the **`.conditions`** payload showing a `repository_property` include condition. If it shows `repository_name`, they solved it the Ch05 way — partial credit only.
- Confirm `ghec-ch08-prod-identity` (a *different name*, same property) is covered — that proves property targeting, not naming.
- `rules[].type` should include `required_signatures` if they added the signed-commit rule.

## Common pitfalls
- **Used a name pattern instead of a property condition.** This is the #1 miss — re-target the ruleset on the `compliance = high` property.
- **Property values PATCH 422s** due to the nested array syntax — set values in the UI or carefully build the `properties[][property_name]`/`properties[][value]` pairs.
- **Signed-commit rule blocks pushes** and the delivery team member thinks it's broken — it's working; that's the gate. Show a signed push if they want green.
- **Token missing `admin:org`.** Property schema and org ruleset writes 403. Fix: `gh auth refresh -s admin:org,repo,read:org`.
- **Default property value not set**, so a future repo wouldn't inherit — remind them the "default for new repositories" toggle is what makes this scale.

## Useful references for coaching

- [About custom properties](https://docs.github.com/en/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization), [About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch08 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch08 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch08-*` artifacts (prefix-guarded): the four repos and the `ghec-ch08-prod-guardrail` org ruleset (plus any `ghec-ch08-*` repo rulesets, which die with their repos).
- **Manual cleanup (required):** the **custom property schema** (`compliance`, `prod`) is org-scoped and **not** `ghec-ch08-*` prefixed; teardown leaves it. Delete the properties by hand (**Org Settings → Custom properties**, or `gh api -X DELETE /orgs/<org>/properties/schema/<name>`) if the org is a reusable sandbox.

## Time budget
- Setup + inventory: ~30 min
- Part A (define properties): ~30 min
- Part B (set values): ~45 min
- Part C (property-targeted org ruleset): ~1.25 hrs
- Part D (repo ruleset layering): ~45 min
- Part E (verify + document): ~30 min
- Stretch: ~45 min
- **Total facilitated:** ~4–5 hrs across sessions.
