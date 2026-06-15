# Ch08 — Repository Rulesets & Custom Properties — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Facilitation notes
- **Goal in one line:** the student makes governance follow **metadata** instead of repo names — custom properties drive a property-targeted org ruleset that automatically governs any repo tagged for compliance, now or in the future.
- **Where students get stuck:**
  - **Property target vs name pattern.** The whole lesson is the **`repository_property`** condition. Students reflexively use a name pattern (`wth-ch08-prod-*`) — that's Ch05's mechanism and misses the point here. Insist on the property condition.
  - **Bulk property values API shape.** The `/orgs/<org>/properties/values` PATCH takes an array of repos and an array of property objects; the nested `-f` syntax is fiddly. The UI is a fine fallback for setting values.
  - **Layering = strictest wins.** When the org rule (1 approval) and the repo rule (2 approvals) both apply, 2 wins. Students expect one to "override"; both apply and the maximum constraint holds.
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
RID=$(gh api /orgs/$ORG/rulesets --jq '.[] | select(.name=="wth-ch08-prod-guardrail") | .id')
gh api /orgs/$ORG/rulesets/$RID --jq '.conditions'        # expect a repository_property condition, NOT repository_name
gh api /orgs/$ORG/rulesets/$RID --jq '.rules[].type'      # pull_request, required_status_checks, non_fast_forward, required_signatures

# Repo-level ruleset overlay on the strict repo
gh api /repos/$ORG/wth-ch08-prod-payments/rulesets --jq '.[] | {name, enforcement}'
```
- The single fastest mastery signal is the **`.conditions`** payload showing a `repository_property` include condition. If it shows `repository_name`, they solved it the Ch05 way — partial credit only.
- Confirm `wth-ch08-prod-identity` (a *different name*, same property) is covered — that proves property targeting, not naming.
- `rules[].type` should include `required_signatures` if they added the signed-commit rule.

## Common pitfalls
- **Used a name pattern instead of a property condition.** This is the #1 miss — re-target the ruleset on the `compliance = high` property.
- **Property values PATCH 422s** due to the nested array syntax — set values in the UI or carefully build the `properties[][property_name]`/`properties[][value]` pairs.
- **Signed-commit rule blocks pushes** and the student thinks it's broken — it's working; that's the gate. Show a signed push if they want green.
- **Token missing `admin:org`.** Property schema and org ruleset writes 403. Fix: `gh auth refresh -s admin:org,repo,read:org`.
- **Default property value not set**, so a future repo wouldn't inherit — remind them the "default for new repositories" toggle is what makes this scale.

## Teardown
```bash
wth teardown ch08 --org <org> --yes
./scripts/teardown.sh ch08 --org <org> --yes   # Bash
./scripts/teardown.ps1 ch08 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch08-*` artifacts (prefix-guarded): the four repos and the `wth-ch08-prod-guardrail` org ruleset (plus any `wth-ch08-*` repo rulesets, which die with their repos).
- **Manual cleanup (required):** the **custom property schema** (`compliance`, `prod`) is org-scoped and **not** `wth-ch08-*` prefixed; teardown leaves it. Delete the properties by hand (**Org Settings → Custom properties**, or `gh api -X DELETE /orgs/<org>/properties/schema/<name>`) if the org is a reusable sandbox.

## Time budget
- Setup + inventory: ~30 min
- Part A (define properties): ~30 min
- Part B (set values): ~45 min
- Part C (property-targeted org ruleset): ~1.25 hrs
- Part D (repo ruleset layering): ~45 min
- Part E (verify + document): ~30 min
- Stretch: ~45 min
- **Total facilitated:** ~4–5 hrs across sessions.
