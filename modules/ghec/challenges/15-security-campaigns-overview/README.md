# Ch15 — Security Campaigns & Overview

> Deliver an organisation security configuration and an owned campaign that turns prioritised findings into tracked remediation.

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch15 --org <org>` (least-privilege; for this activity: `repo` + `admin:org` + `security_events`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- GHAS note: security overview, configurations, and campaigns operate on GHAS alert data. The Juice Shop import is provisioned public so CodeQL/Dependabot/secret scanning alerts run free. However, the security overview's advanced views (Risk, Coverage, Campaigns) and security campaigns themselves require a GitHub Code Security or GitHub Secret Protection license at the organization level — a public repo's free scanning does *not* unlock them. If your org has no GHAS product, you can still generate and triage alerts (Part A) but Parts B–E need a licensed org. `modules/ghec/resources/provisioning/scripts/setup.sh doctor` confirms availability.
- Standalone setup note: this activity does not depend on ch12/ch13 having run — setup creates its own `ghec-ch15-juice-shop` and enables scanning so the alert corpus exists standalone.

## What you will deliver
- Open the organization Security overview, review risk and coverage, and filter alerts across repositories.
- Create an organization security configuration and apply it so GHAS features roll out consistently to repos.
- Read coverage (which repos have which features on) vs risk (where the open alerts are).
- Launch a security campaign targeting a slice of alerts, assign a manager, set a due date, and add guidance.
- Track campaign progress and remediation, and report on alert burn-down across the org.

## Scenario
A GHEC customer has GHAS switched on but no program around it — alerts pile up, nobody owns them, and leadership can't answer "are we getting safer?" You'll give them the management layer: a security overview showing risk and coverage at a glance, a security configuration that applies GHAS uniformly, and a security campaign that turns a wall of alerts into a finite, owned, time-boxed remediation effort. OWASP Juice Shop supplies the realistic alert volume — CodeQL, Dependabot, and secret-scanning hits — that a campaign needs to be meaningful.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate application repository or campaign candidate, use it everywhere this guide says `ghec-ch15-juice-shop` and skip Setup. Otherwise use the fallback OWASP Juice Shop import below, which carries security findings suitable for controlled campaign validation.
>
> Record the selected target, security programme owner, and next action.

## Sample test repository or environment
Skip if you brought your own repo/campaign target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch15 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch15 --org <org>
```

Setup creates these resources (all names use the `ghec-ch15-*` prefix, and teardown is prefix-guarded):
- A public repo `ghec-ch15-juice-shop` — OWASP Juice Shop imported at pinned ref `v20.0.0` (pulled from the official source, never vendored).
- The repo is staged so that enabling GHAS produces a rich alert corpus across CodeQL (OWASP Top 10), Dependabot (vulnerable npm tree), and secret scanning — the raw material a campaign targets. (Setup may enable default CodeQL and Dependabot so alerts exist out of the gate.)
- A printed Next steps block pointing at the org Security tab (overview, configurations, campaigns).

## Tasks

### Part A — Generate the alert corpus
1. Open `ghec-ch15-juice-shop` → Security. Ensure code scanning (CodeQL), Dependabot, and secret scanning are enabled (enable any that aren't). Wait for the initial scans to complete so the org has a real alert volume to manage.
2. Spot-check via API that multiple alert types are present:
   ```bash
   gh api repos/<org>/ghec-ch15-juice-shop/code-scanning/alerts --jq 'length'
   gh api repos/<org>/ghec-ch15-juice-shop/dependabot/alerts --jq 'length'
   ```

### Part B — Security overview
3. Go to the org's Security tab → Overview. Explore the Risk view (open alerts by type/severity across repos) and the Coverage view (which repos have which features enabled).
4. Filter the overview to `ghec-ch15-juice-shop` and by critical/high severity. Note the alert counts per tool — this is your campaign's candidate scope.
5. Pull an org-wide alert view via API for a CodeQL slice you can reason about:
   ```bash
   gh api orgs/<org>/code-scanning/alerts --paginate \
     --jq '.[] | select(.state=="open") | {repo: .repository.name, rule: .rule.id, severity: .rule.security_severity_level}'
   ```

### Part C — Security configuration
6. In Org Settings → Code security → Configurations, create a configuration that enables the GHAS features you want as a baseline (code scanning default setup, Dependabot alerts + security updates, secret scanning + push protection).
7. Apply the configuration to `ghec-ch15-juice-shop` (and optionally set it as the default for newly created repos). Confirm in the Coverage view that the repo now reports the features as enabled.

### Part D — Launch a security campaign
8. From the Security overview → Campaigns, create a campaign targeting a meaningful, finite slice — e.g. all critical/high CodeQL alerts (or critical Dependabot alerts) in `ghec-ch15-juice-shop`. Keep the scope achievable, not the entire backlog.
9. Set the campaign metadata: a clear name, a manager (yourself), a due date, and a description with remediation guidance and links (Autofix for CodeQL, version bumps for Dependabot).
10. Confirm developers see actionable work. Open the campaign and verify the targeted alerts are grouped under it with the guidance attached — this is what a developer would pick up.

### Part E — Track remediation & report
11. Fix or dismiss several targeted alerts (apply Autofix on a CodeQL alert, merge a Dependabot security PR, resolve a secret alert) so the campaign shows real burn-down.
12. Re-open the campaign and the overview; confirm the open-alert count for the campaign has dropped. Capture before/after numbers.
13. In an issue on `ghec-ch15-juice-shop`, summarize: starting alert count by type, the campaign scope and deadline, what was remediated, and the residual risk — the report leadership asked for at the start.

## Reference links
- About security overview — https://docs.github.com/en/code-security/security-overview/about-security-overview
- Viewing security insights — https://docs.github.com/en/code-security/security-overview/viewing-security-insights
- About security campaigns — https://docs.github.com/en/code-security/securing-your-organization/fixing-security-alerts-at-scale/about-security-campaigns
- Creating and managing security campaigns — https://docs.github.com/en/code-security/securing-your-organization/fixing-security-alerts-at-scale/creating-managing-security-campaigns
- About enabling security features with a configuration — https://docs.github.com/en/code-security/securing-your-organization/enabling-security-features-in-your-organization/creating-a-custom-security-configuration
- Applying a security configuration to repositories — https://docs.github.com/en/code-security/securing-your-organization/enabling-security-features-in-your-organization/applying-a-custom-security-configuration
- Security campaigns REST API — https://docs.github.com/en/rest/campaigns/campaigns
