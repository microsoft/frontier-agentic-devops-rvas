# Ch15 — Security Campaigns & Overview

> By the end of this challenge you can read the org-level security overview dashboards, roll GHAS out across repos with a security configuration, launch a security campaign that hands prioritized alerts to developers with a deadline, and track remediation to completion — using OWASP Juice Shop's real alert volume as the campaign target.

| | |
|---|---|
| **Track** | Security |
| **Difficulty** | Advanced *(per-track ramp)* |
| **Duration** | ~5 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | juice-shop *(imported at pinned ref `v20.0.0`)* |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch15 --org <org>` (least-privilege; for this challenge: `repo` + `admin:org` + `security_events`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `wth doctor` to verify).
- **GHAS note:** security overview, configurations, and campaigns operate on GHAS alert data. The Juice Shop import is provisioned **public** so CodeQL/Dependabot/secret scanning **alerts** run free. **However**, the security overview's advanced views (**Risk**, **Coverage**, **Campaigns**) **and security campaigns themselves require a GitHub Code Security or GitHub Secret Protection license at the organization level** — a public repo's free scanning does *not* unlock them. If your org has no GHAS product, you can still generate and triage alerts (Part A) but Parts B–E need a licensed org. `wth doctor` confirms availability.
- **Soft-link note (independence preserved):** this challenge does **not** depend on ch12/ch13 having run — setup creates its **own** `wth-ch15-juice-shop` and enables scanning so the alert corpus exists standalone.

## Learning objectives
By completing this challenge you will:
- Navigate the org **Security overview**: the risk and coverage views, and filter alerts across repos.
- Create an **organization security configuration** and apply it so GHAS features roll out consistently to repos.
- Read **coverage** (which repos have which features on) vs **risk** (where the open alerts are).
- Launch a **security campaign** targeting a slice of alerts, assign a manager, set a due date, and add guidance.
- Track campaign **progress** and remediation, and report on alert burn-down across the org.

## Scenario
A GHEC customer has GHAS switched on but no program around it — alerts pile up, nobody owns them, and leadership can't answer "are we getting safer?" You'll give them the management layer: a security overview that shows risk and coverage at a glance, a security configuration that applies GHAS uniformly, and a **security campaign** that turns a wall of alerts into a finite, owned, time-boxed remediation effort developers can actually act on. OWASP Juice Shop supplies the realistic alert volume — CodeQL findings, Dependabot alerts, and secret-scanning hits — that a campaign needs to be meaningful.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `./scripts/`.

```bash
# Bash
wth setup ch15 --org <org>
# or directly:
./scripts/setup.sh ch15 --org <org>
```
```powershell
# PowerShell
wth setup ch15 --org <org>
# or directly:
./scripts/setup.ps1 ch15 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch15-*`, idempotent, prefix-guarded teardown):
- A **public** repo **`wth-ch15-juice-shop`** — OWASP Juice Shop imported at pinned ref **`v20.0.0`** (pulled from the official source, never vendored into this repo).
- The repo is staged so that enabling GHAS produces a **rich alert corpus** across **CodeQL** (OWASP Top 10), **Dependabot** (vulnerable npm tree), and **secret scanning** — the raw material a campaign targets. (Setup may enable default CodeQL and Dependabot so alerts exist out of the gate; you'll confirm and extend.)
- A printed **Next steps** block pointing at the org **Security** tab (overview, configurations, campaigns).

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch15 --org <org> --yes` removes only `wth-ch15-*` artifacts (the imported repo). Org-level **security configurations / campaigns** you create are noted for manual cleanup in `COACH.md`.

## Tasks

### Part A — Generate the alert corpus
1. **Confirm alerts exist.** Open `wth-ch15-juice-shop` → **Security**. Ensure **code scanning (CodeQL)**, **Dependabot**, and **secret scanning** are enabled (enable any that aren't). Wait for the initial scans to complete so the org has a real alert volume to manage.
2. **Spot-check via API** that multiple alert types are present:
   ```bash
   gh api repos/<org>/wth-ch15-juice-shop/code-scanning/alerts --jq 'length'
   gh api repos/<org>/wth-ch15-juice-shop/dependabot/alerts --jq 'length'
   ```

### Part B — Security overview
3. **Open the org Security overview.** Go to the org's **Security** tab → **Overview**. Explore the **Risk** view (open alerts by type/severity across repos) and the **Coverage** view (which repos have which features enabled).
4. **Filter and read the data.** Filter the overview to `wth-ch15-juice-shop` and by **critical/high** severity. Note the alert counts per tool — this is your campaign's candidate scope.
5. **Pull an org-wide alert view via API** for a CodeQL slice you can reason about:
   ```bash
   gh api orgs/<org>/code-scanning/alerts --paginate \
     --jq '.[] | select(.state=="open") | {repo: .repository.name, rule: .rule.id, severity: .rule.security_severity_level}'
   ```

### Part C — Security configuration
6. **Create an org security configuration.** In **Org Settings → Code security → Configurations**, create a configuration that enables the GHAS features you want as a baseline (code scanning default setup, Dependabot alerts + security updates, secret scanning + push protection).
7. **Apply it.** Apply the configuration to `wth-ch15-juice-shop` (and optionally set it as the **default for newly created repos**). Confirm in the **Coverage** view that the repo now reports the features as enabled.

### Part D — Launch a security campaign
8. **Scope the campaign.** From the **Security overview → Campaigns**, create a campaign targeting a meaningful, finite slice — e.g. **all critical/high CodeQL alerts** (or critical Dependabot alerts) in `wth-ch15-juice-shop`. Keep the scope achievable, not the entire backlog.
9. **Set the campaign metadata:** a clear **name**, a **manager** (yourself), a **due date**, and a **description** with remediation guidance and links (Autofix for CodeQL, version bumps for Dependabot).
10. **Confirm developers see actionable work.** Open the campaign and verify the targeted alerts are grouped under it with the guidance attached — this is what a developer would pick up.

### Part E — Track remediation & report
11. **Remediate part of the campaign.** Fix or dismiss several targeted alerts (apply Autofix on a CodeQL alert, merge a Dependabot security PR, resolve a secret alert) so the campaign shows real **burn-down**.
12. **Track progress.** Re-open the campaign and the overview; confirm the open-alert count for the campaign has dropped. Capture before/after numbers.
13. **Write a remediation report.** In an issue on `wth-ch15-juice-shop`, summarize: starting alert count by type, the campaign scope and deadline, what was remediated, and the residual risk — the report leadership asked for at the start.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] `wth-ch15-juice-shop` has a **multi-tool alert corpus** (CodeQL **and** Dependabot alerts present, verifiable via the alerts APIs).
- [ ] You used the org **Security overview** Risk and Coverage views and produced an **org-wide alert slice** via the API.
- [ ] An **org security configuration** exists and is **applied** to the repo (features show enabled in Coverage).
- [ ] A **security campaign** exists with a name, a **manager**, a **due date**, and **guidance**, scoped to a finite alert slice.
- [ ] The campaign shows **remediation burn-down** (open count dropped after you fixed/dismissed targeted alerts).
- [ ] A **remediation report** issue exists with before/after numbers.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Apply the security configuration as the **org default** and create a second repo to prove new repos inherit it.
- Build a small **burn-down chart** by scripting the org alerts API on two dates and diffing open counts.
- Add a **second campaign** for secret-scanning alerts with a tighter deadline and compare manager workflows.

## Reference links
- About security overview — https://docs.github.com/en/code-security/security-overview/about-security-overview
- Viewing security insights — https://docs.github.com/en/code-security/security-overview/viewing-security-insights
- About security campaigns — https://docs.github.com/en/code-security/securing-your-organization/fixing-security-alerts-at-scale/about-security-campaigns
- Creating and managing security campaigns — https://docs.github.com/en/code-security/securing-your-organization/fixing-security-alerts-at-scale/creating-managing-security-campaigns
- About enabling security features with a configuration — https://docs.github.com/en/code-security/securing-your-organization/enabling-security-features-in-your-organization/creating-a-custom-security-configuration
- Applying a security configuration to repositories — https://docs.github.com/en/code-security/securing-your-organization/enabling-security-features-in-your-organization/applying-a-custom-security-configuration
- Security campaigns REST API — https://docs.github.com/en/rest/campaigns/campaigns
