# Ch13 — Dependabot & Dependency Review — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

**Required delivery assurance check:** before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

**Decision prompt:** scan your real repos in your head: which project is most likely sitting on a critically vulnerable transitive dependency right now, and what would it take to make Dependabot auto-merge safe there? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> **Customer implementation preference:** prioritize an authorized customer tenant or artifact over the `ghec-ch13-juice-shop` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Name the repo — what ecosystem (npm, pip, Maven, Go modules) and roughly how many dependencies does it have?
- What is the test-coverage or CI-gate situation in that repo — what would need to be true before auto-merge is trustworthy?
- What Dependabot config change (schedule, allow-list, grouping, auto-merge rule) would you commit this week?

## Delivery assurance notes
- **Customer adoption outcome:** the customer implementation owner turns a vulnerable dependency tree into a managed supply chain — alerts triaged, security PRs merged, scheduled updates configured, and a PR-time gate that blocks new risky dependencies.
- **Implementation risks to verify:**
  - **Three different Dependabot things.** *Alerts* (notifications), *security updates* (auto-PRs for known vulns), and *version updates* (`dependabot.yml` scheduled bumps) are distinct. Customer implementation owners conflate them — make them name which is which.
  - **Dependency review ≠ Dependabot.** Dependency review is a **PR-time diff check** (the action), separate from Dependabot alerts. Both matter; they're not the same feature.
  - **Security PRs need security updates *enabled*.** If no PRs appear, they enabled alerts but not security updates.
  - **Required-check name.** The dependency-review check name (from the action/job) must match the required context.
  - **Alert → fixed timing.** After merging a security PR, the alert moves to `fixed` on the next graph refresh, not instantly.
- **Delivery lead prompts:** ask "which Dependabot feature opens a *PR*, and which just *notifies*?" and "where does dependency review run — on the alert list or on the PR diff?"
- **Org-scoped note:** runs with just an org + org-owner token. Public repo = free graph/Dependabot/review. `security_events` scope is needed for the Dependabot alerts API.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Dependency graph + SBOM (Part A) | 15 | Graph explored; SBOM exported via API/UI |
| Dependabot alerts triage (Part B) | 25 | Alerts enabled; backlog reviewed; ≥1 dismissed with a reason; advisory understood |
| Security-update PRs (Part C) | 20 | ≥1 security PR merged; corresponding alert moved to `fixed` |
| Scheduled version updates (Part D) | 15 | Valid `dependabot.yml` with schedule, limit, and a group; version PRs distinct from security PRs |
| Dependency review gating (Part E) | 25 | Dependency-review workflow required on main; seeded risky PR blocked |
| **Assurance coverage** | **100** | |

## Implementation verification evidence
Use these to verify the customer implementation evidence (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>; REPO=ghec-ch13-juice-shop   # swap REPO for the customer implementation owner's own repo if they brought one

# Repo exists and is public
gh repo view $ORG/$REPO --json name,visibility

# SBOM export works (SPDX)
gh api repos/$ORG/$REPO/dependency-graph/sbom --jq '.sbom.name, (.sbom.packages | length)'

# Dependabot alerts: open set with package + severity (expect critical/high present)
gh api repos/$ORG/$REPO/dependabot/alerts --paginate \
  --jq '.[] | select(.state=="open") | {number, pkg: .dependency.package.name, severity: .security_advisory.severity}'

# Dismissed alerts (triage evidence)
gh api repos/$ORG/$REPO/dependabot/alerts --paginate \
  --jq '.[] | select(.state=="dismissed") | {number, reason: .dismissed_reason}'

# Fixed alerts (proves a security PR was merged)
gh api repos/$ORG/$REPO/dependabot/alerts --paginate --jq '.[] | select(.state=="fixed") | .number'

# Dependabot-authored PRs
gh pr list --repo $ORG/$REPO --author "app/dependabot" --state all --json number,title,state

# dependabot.yml present and valid-ish
gh api repos/$ORG/$REPO/contents/.github/dependabot.yml -H "Accept: application/vnd.github.raw" \
  | grep -E "package-ecosystem|schedule|open-pull-requests-limit|groups"

# Required checks on main (expect the dependency-review context)
gh api repos/$ORG/$REPO/branches/main/protection/required_status_checks --jq '.contexts'
```
- **Distinguish features:** confirm BOTH a security-update PR (`app/dependabot` author, fixes an alert) AND a `dependabot.yml` for version updates exist — they prove the customer implementation owner separated the two.
- **Gating:** the dependency-review context must be in `required_status_checks`, and the customer implementation owner should show the risky PR's merge blocked.

## Common pitfalls
- **Only enabling alerts** → no security PRs appear. Enable **security updates** too.
- **Confusing version updates with security updates** — `dependabot.yml` does NOT cause security PRs; that's the security-updates toggle.
- **Dependency-review action not failing** — it defaults to warn; set `fail-on-severity` to actually block.
- **`security_events` scope missing** → Dependabot alerts API 403. Fix: `gh auth refresh -s security_events`.
- **Private repo** → dependency review needs a license. Keep the repo public.

## References for delivery leads

- [About the dependency graph](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph), [About Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch13 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch13 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch13-*` artifacts (prefix-guarded): the imported `ghec-ch13-juice-shop` repo (which carries its dependency graph, alerts, Dependabot config, and workflows).
- **Manual cleanup (if any):** none. Deleting the repo removes its alerts, Dependabot PRs, and configuration.

## Time budget
- Setup + read: ~30 min
- Part A (graph + SBOM): ~30 min
- Part B (alert triage): ~1 hr
- Part C (security PRs): ~45 min
- Part D (version updates): ~30 min
- Part E (dependency review gating): ~45 min
- **Indicative implementation effort:** ~4 hrs across sessions.
