# Ch13 — Dependabot & Dependency Review — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — scan your real repos in your head: which project is most likely sitting on a critically vulnerable transitive dependency right now, and what would it take to make Dependabot auto-merge safe there? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer students who ran this on a **real artifact they own** over the `wth-ch13-juice-shop` sample. If they used the sample, confirm they can name the actual repo, team, project, or workflow they'll apply this to and any blockers. The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- Name the repo — what ecosystem (npm, pip, Maven, Go modules) and roughly how many dependencies does it have?
- What is the test-coverage or CI-gate situation in that repo — what would need to be true before auto-merge is trustworthy?
- What Dependabot config change (schedule, allow-list, grouping, auto-merge rule) would you commit this week?

## Facilitation notes
- **Goal in one line:** the student turns a vulnerable dependency tree into a managed supply chain — alerts triaged, security PRs merged, scheduled updates configured, and a PR-time gate that blocks new risky dependencies.
- **Where students get stuck:**
  - **Three different Dependabot things.** *Alerts* (notifications), *security updates* (auto-PRs for known vulns), and *version updates* (`dependabot.yml` scheduled bumps) are distinct. Students conflate them — make them name which is which.
  - **Dependency review ≠ Dependabot.** Dependency review is a **PR-time diff check** (the action), separate from Dependabot alerts. Both matter; they're not the same feature.
  - **Security PRs need security updates *enabled*.** If no PRs appear, they enabled alerts but not security updates.
  - **Required-check name.** The dependency-review check name (from the action/job) must match the required context.
  - **Alert → fixed timing.** After merging a security PR, the alert moves to `fixed` on the next graph refresh, not instantly.
- **How to unblock without giving the answer:** ask "which Dependabot feature opens a *PR*, and which just *notifies*?" and "where does dependency review run — on the alert list or on the PR diff?"
- **Org-scoped note:** runs with just an org + org-owner token. Public repo = free graph/Dependabot/review. `security_events` scope is needed for the Dependabot alerts API.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Dependency graph + SBOM (Part A) | 15 | Graph explored; SBOM exported via API/UI |
| Dependabot alerts triage (Part B) | 25 | Alerts enabled; backlog reviewed; ≥1 dismissed with a reason; advisory understood |
| Security-update PRs (Part C) | 20 | ≥1 security PR merged; corresponding alert moved to `fixed` |
| Scheduled version updates (Part D) | 15 | Valid `dependabot.yml` with schedule, limit, and a group; version PRs distinct from security PRs |
| Dependency review gating (Part E) | 25 | Dependency-review workflow required on main; seeded risky PR blocked |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>; REPO=wth-ch13-juice-shop   # swap REPO for the student's own repo if they brought one

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
- **Distinguish features:** confirm BOTH a security-update PR (`app/dependabot` author, fixes an alert) AND a `dependabot.yml` for version updates exist — they prove the student separated the two.
- **Gating:** the dependency-review context must be in `required_status_checks`, and the student should show the risky PR's merge blocked.

## Common pitfalls
- **Only enabling alerts** → no security PRs appear. Enable **security updates** too.
- **Confusing version updates with security updates** — `dependabot.yml` does NOT cause security PRs; that's the security-updates toggle.
- **Dependency-review action not failing** — it defaults to warn; set `fail-on-severity` to actually block.
- **`security_events` scope missing** → Dependabot alerts API 403. Fix: `gh auth refresh -s security_events`.
- **Private repo** → dependency review needs a license. Keep the repo public.

## Useful references for coaching

- [About the dependency graph](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph), [About Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch13 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch13 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch13-*` artifacts (prefix-guarded): the imported `wth-ch13-juice-shop` repo (which carries its dependency graph, alerts, Dependabot config, and workflows).
- **Manual cleanup (if any):** none. Deleting the repo removes its alerts, Dependabot PRs, and configuration.

## Time budget
- Setup + read: ~30 min
- Part A (graph + SBOM): ~30 min
- Part B (alert triage): ~1 hr
- Part C (security PRs): ~45 min
- Part D (version updates): ~30 min
- Part E (dependency review gating): ~45 min
- **Total facilitated:** ~4 hrs across sessions.
