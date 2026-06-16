# Ch13 — Dependabot & Dependency Review

> By the end of this challenge you can enable the dependency graph and Dependabot, triage real vulnerable-dependency alerts on OWASP Juice Shop, take Dependabot security-update PRs, configure scheduled version updates, and block risky dependencies at PR time with dependency review — all org-scoped on a public repo.

| | |
|---|---|
| **Track** | Security |
| **Difficulty** | Intermediate *(per-track ramp)* |
| **Duration** | ~4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | juice-shop *(imported at pinned ref `v20.0.0`)* |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch13 --org <org>` (least-privilege; for this challenge: `repo` + `security_events`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `wth doctor` to verify).
- **GHAS note:** the dependency graph, Dependabot alerts/updates, and dependency review are **free on public repos**. Setup provisions the Juice Shop import as **public**. On private/internal repos, dependency review needs a paid Code Security license — `wth doctor` warns.

## Learning objectives
By completing this challenge you will:
- Enable the **dependency graph** and **Dependabot alerts** + **security updates** on a repository.
- Read the **dependency graph** and an **SBOM** export to understand what the app actually depends on.
- Triage **Dependabot alerts** by severity and review the linked GitHub Advisory for each.
- Accept (and understand) **Dependabot security-update PRs** that bump vulnerable packages.
- Configure **`dependabot.yml`** for scheduled **version updates** with grouping and limits.
- Add **dependency review** so a PR that introduces a vulnerable or disallowed-license dependency is blocked.

## Scenario
A GHEC customer's app drags a long tail of outdated, vulnerable npm packages — the kind of supply-chain risk that doesn't show up until a CVE makes the news. You'll give them an early-warning system: the dependency graph maps what they depend on, Dependabot opens PRs to fix known-vulnerable packages automatically, and dependency review stops a new risky dependency from sneaking in via a pull request. OWASP Juice Shop is purpose-built for this — its dependency tree is intentionally vulnerable (old Angular libraries, a deliberately risky `ftp` package, a `.dependabot/` directory), so there's genuine alert and PR material to work with.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `./scripts/`.

```bash
# Bash
wth setup ch13 --org <org>
# or directly:
./scripts/setup.sh ch13 --org <org>
```
```powershell
# PowerShell
wth setup ch13 --org <org>
# or directly:
./scripts/setup.ps1 ch13 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch13-*`, idempotent, prefix-guarded teardown):
- A **public** repo **`wth-ch13-juice-shop`** — OWASP Juice Shop imported at pinned ref **`v20.0.0`** (pulled from the official source, never vendored into this repo). Its npm dependency tree is intentionally vulnerable, giving Dependabot genuine alerts and security-update PRs to raise.
- A `feature/add-risky-dep` **branch** that adds a known-vulnerable dependency to `package.json`, ready to open as a PR so you can watch **dependency review** flag it.
- A printed **Next steps** block telling you where to start.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch13 --org <org> --yes` removes only `wth-ch13-*` artifacts (the imported repo).

## Tasks

### Part A — Dependency graph & SBOM
1. **Enable the dependency graph.** In `wth-ch13-juice-shop` → **Settings → Code security**, confirm **Dependency graph** is on (default on public repos), then open **Insights → Dependency graph → Dependencies** and explore the resolved tree.
2. **Export an SBOM.** From the dependency graph UI (Export SBOM) or the API, pull the SPDX SBOM and skim it:
   ```bash
   gh api repos/<org>/wth-ch13-juice-shop/dependency-graph/sbom --jq '.sbom.name, (.sbom.packages | length)'
   ```

### Part B — Dependabot alerts
3. **Enable Dependabot alerts and security updates.** In **Settings → Code security**, turn on **Dependabot alerts** and **Dependabot security updates**.
4. **Triage the alert backlog.** Open **Security → Dependabot** and review the alerts. Sort by severity. Open one **critical/high** alert and read the linked **GitHub Advisory** (CVE, affected range, patched version).
5. **List alerts via API** and build a severity view:
   ```bash
   gh api repos/<org>/wth-ch13-juice-shop/dependabot/alerts --paginate \
     --jq '.[] | select(.state=="open") | {number, pkg: .dependency.package.name, severity: .security_advisory.severity}'
   ```
6. **Dismiss one alert with a reason** (e.g. a dev-only dependency you deem not exploitable) using the UI or API, and note the audit reason recorded.

### Part C — Security-update PRs
7. **Let Dependabot open security PRs.** With security updates enabled, Dependabot opens PRs that bump vulnerable packages to patched versions. List them:
   ```bash
   gh pr list --repo <org>/wth-ch13-juice-shop --author "app/dependabot" --json number,title,headRefName
   ```
8. **Review and merge one security PR.** Read the changelog/compatibility score Dependabot includes, then merge a low-risk bump. Confirm the corresponding Dependabot alert moves to **fixed** after the merge.

### Part D — Scheduled version updates
9. **Add `dependabot.yml`.** Create `.github/dependabot.yml` configuring the **npm** ecosystem for **weekly** version updates, with an **open-PR limit** and a **group** so related minor/patch bumps land together:
   ```yaml
   version: 2
   updates:
     - package-ecosystem: "npm"
       directory: "/"
       schedule:
         interval: "weekly"
       open-pull-requests-limit: 5
       groups:
         minor-and-patch:
           update-types: ["minor", "patch"]
   ```
10. **Trigger a check.** From the **Insights → Dependency graph → Dependabot** tab, trigger a check for updates (or wait for the schedule) and confirm version-update PRs appear distinct from the security-update PRs.

### Part E — Dependency review on PRs
11. **Add a dependency-review workflow.** Commit `.github/workflows/dependency-review.yml` using `actions/dependency-review-action`, configured to **fail** on a minimum severity (e.g. `high`) and optionally on disallowed licenses.
12. **Open the seeded risky PR.** Create a PR from `feature/add-risky-dep` into `main`. The dependency-review check should **flag the vulnerable dependency on the PR**.
13. **Make it a required check.** Mark the dependency-review check as **required** on `main` and confirm the risky PR is **blocked** until the dependency is removed or the alert is otherwise resolved.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] **Dependency graph** is on and you exported an **SBOM** (verifiable via the `dependency-graph/sbom` API).
- [ ] **Dependabot alerts** and **security updates** are enabled and the repo has **open alerts** with severities (verifiable via the `dependabot/alerts` API).
- [ ] You **triaged the backlog**: reviewed an advisory and **dismissed at least one alert** with a reason.
- [ ] At least one **Dependabot security-update PR** was merged and its alert moved to **fixed**.
- [ ] `.github/dependabot.yml` configures **scheduled npm version updates** with a limit and a group.
- [ ] A **dependency-review** workflow exists, is **required** on `main`, and **blocks** the seeded risky PR.
- [ ] Coach conversation — scan your real repos in your head: which project is most likely sitting on a critically vulnerable transitive dependency right now, and what would it take to make Dependabot auto-merge safe there? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Add a second `dependabot.yml` ecosystem (e.g. `github-actions`) and keep its PRs grouped separately.
- Configure **`dependency-review-action`** to also fail on a denied **license** and prove it blocks a GPL-only dependency.
- Auto-merge Dependabot **patch** updates that pass CI using a workflow + auto-merge (pairs with ch05).

## Reference links
- About the dependency graph — https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph
- About Dependabot alerts — https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts
- Configuring Dependabot security updates — https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/configuring-dependabot-security-updates
- Configuring Dependabot version updates — https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates
- About dependency review — https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review
- Exporting a software bill of materials for your repository — https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/exporting-a-software-bill-of-materials-for-your-repository
- Dependabot REST API — https://docs.github.com/en/rest/dependabot/alerts
