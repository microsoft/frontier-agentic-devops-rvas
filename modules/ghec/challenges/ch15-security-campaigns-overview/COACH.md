# Ch15 — Security Campaigns & Overview — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A sample or safe fallback is a controlled proving ground, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

**Required delivery assurance check:** before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

**Decision prompt:** if you ran a security campaign across your org's repos today targeting the most common CWE your stack is exposed to, which three repo owners would you expect to push back hardest on fixing their alerts, and what would make the campaign succeed anyway? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> **Customer implementation preference:** prioritize an authorized customer tenant or artifact over the `ghec-ch15-juice-shop` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Name the specific CWE category or alert type you'd target first in your org — where is the highest concentration of alerts?
- Who are the likely resisters — legacy repo owners, under-resourced teams, conflicting roadmaps?
- What is the campaign message, deadline, and escalation path you'd use to get at least 80% closure?

## Delivery assurance notes
- **Customer adoption outcome:** the customer implementation owner moves from "we have alerts" to "we run a security program" — reading risk/coverage, rolling out GHAS with a configuration, and driving a time-boxed, owned security campaign to measurable burn-down.
- **Implementation risks to verify:**
  - **Overview vs repo Security tab.** The org **Security overview** (risk + coverage across repos) is different from a single repo's Security tab. Make sure they're at **org** scope.
  - **Risk vs coverage.** Coverage = which features are *on*; risk = where the *alerts* are. Customer implementation owners conflate them. A repo can have full coverage and high risk.
  - **Campaign scope too big.** Targeting the entire backlog makes burn-down impossible in a session. Require them to scope to a finite slice (critical/high CodeQL, or critical Dependabot).
  - **No alerts yet.** Campaigns need an alert corpus. If scans haven't finished, there's nothing to target — start scans early.
  - **Configuration vs manual toggles.** A **security configuration** applies features at scale; doing it per-repo by hand does not provide durable customer rollout evidence.
- **Delivery lead prompts:** ask "what's the difference between a repo being *covered* and being *risky*?" and "how would a developer know *which* alerts to fix *by when*?" (→ a scoped campaign with an owner and a deadline).
- **Org-scoped note:** runs with just an org + org-owner token. Public Juice Shop import = free **scanning/alerts** (Part A). **But the security overview's Risk/Coverage/Campaigns views and security campaigns require a GitHub Code Security or GitHub Secret Protection license at the org level** — public-repo free scanning does not unlock them, so Parts B–E need a licensed org. `admin:org` is needed for configurations/campaigns; `security_events` for the alerts APIs. Independence preserved — setup creates its own `ghec-ch15-juice-shop`; it does not rely on ch12/ch13.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Alert corpus generated (Part A) | 15 | CodeQL + Dependabot (and ideally secret) alerts present on the repo |
| Security overview navigation (Part B) | 20 | Risk + Coverage views used; org-wide alert slice produced via API |
| Security configuration (Part C) | 20 | Org configuration created and applied; Coverage shows features enabled |
| Security campaign launch (Part D) | 25 | Campaign with name, manager, due date, guidance, scoped to a finite slice |
| Remediation burn-down + report (Part E) | 20 | Targeted alerts remediated; campaign open-count dropped; report issue filed with before/after |
| **Assurance coverage** | **100** | |

## Implementation verification evidence
Use these to verify the customer implementation evidence. Campaign and configuration UI state is best confirmed with a screenshot; the alert APIs prove the corpus and burn-down.
```bash
ORG=<org>; REPO=ghec-ch15-juice-shop   # swap REPO for the customer implementation owner's own repo if they brought one

# Repo exists and is public
gh repo view $ORG/$REPO --json name,visibility

# Multi-tool alert corpus present
gh api repos/$ORG/$REPO/code-scanning/alerts --jq 'length'
gh api repos/$ORG/$REPO/dependabot/alerts --jq 'length'

# Org-wide open CodeQL slice (the campaign candidate scope)
gh api orgs/$ORG/code-scanning/alerts --paginate \
  --jq '.[] | select(.state=="open") | {repo: .repository.name, rule: .rule.id, severity: .rule.security_severity_level}'

# Org-wide Dependabot view
gh api orgs/$ORG/dependabot/alerts --paginate \
  --jq '.[] | select(.state=="open") | {repo: .repository.name, severity: .security_advisory.severity}'

# Burn-down: count open critical/high before vs after remediation
gh api orgs/$ORG/code-scanning/alerts --paginate \
  --jq '[.[] | select(.state=="open" and (.rule.security_severity_level=="critical" or .rule.security_severity_level=="high"))] | length'

# Remediation report issue exists
gh issue list --repo $ORG/$REPO --search "remediation report" --json number,title
```
- **Burn-down truth source:** run the critical/high count before and after the customer implementation owner's remediation; it must drop. The report issue should cite matching numbers.
- **Configuration/campaign:** these are largely UI/org-settings constructs — confirm via screenshot that a configuration is *applied* (Coverage view) and a campaign exists with a manager + due date. The alert deltas back it up.
- **Independence:** confirm `ghec-ch15-juice-shop` exists on its own (not reusing ch12/ch13 repos).

## Common pitfalls
- **Working in a repo Security tab** instead of the org Security overview — campaigns/configurations live at org scope.
- **Campaign scoped to everything** → no visible progress. Scope tight.
- **Starting the campaign before scans finish** → empty target set. Generate alerts first.
- **`admin:org` / `security_events` scope missing** → configurations/campaigns/alerts APIs 403. Re-auth.
- **Private repo without a license** → no free scanning, sparse corpus. Keep it public.
- **No GHAS product on the org** → the overview's Risk/Coverage/Campaigns views and the **Campaigns** feature won't be available even though the repo is public. Parts B–E require a GitHub Code Security or GitHub Secret Protection license; without one, customer implementation owners can only complete Part A.

## References for delivery leads

- [About security overview](https://docs.github.com/en/code-security/security-overview/about-security-overview), [Viewing security insights](https://docs.github.com/en/code-security/security-overview/viewing-security-insights).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch15 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch15 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch15-*` artifacts (prefix-guarded): the imported `ghec-ch15-juice-shop` repo (which carries its alerts).
- **Manual cleanup (REQUIRED — org-level constructs aren't prefix-scoped):**
  - **Delete the security campaign** you created (Org → Security overview → Campaigns).
  - **Delete or unset the security configuration** (Org Settings → Code security → Configurations), especially if you set it as the **default for new repos**.

## Time budget
- Setup + generate alerts: ~45 min
- Part B (overview): ~45 min
- Part C (configuration): ~45 min
- Part D (campaign launch): ~1 hr
- Part E (remediation + report): ~1.25 hrs
- **Indicative implementation effort:** ~5 hrs across sessions.
