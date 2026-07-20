# Activity S05 — Secure Secrets & Dependencies

## Description

Two different attack surfaces. Same urgency.

**Hardcoded secrets:** API keys, database passwords, JWT signing keys, and credentials committed to source code are one of the most common and most preventable security failures. Secret scanning alerts are shared at the repository level, while your branch is validated through push protection and pull request security signals. Your job is to remove the exposed value from the code path, determine whether it needs revocation or rotation, move replacement configuration out of source control, and make sure the application still works.

**Vulnerable dependencies:** Every package in `package.json` is a potential attack vector. Dependabot alerts and Dependabot security update pull requests are shared repo/default-branch signals. Your job is to review the high and critical severity alerts, understand what the vulnerability in each package actually is, and validate any dependency changes your team makes through your pull request.

Both issues need accountable response, not just a one-time edit. Record the response in `modules/ghas/resources/ghas-governance-practice.template.md`: who owns it, what was validated, whether risk is accepted, and when that exception expires.

## Objectives

- Review the shared **Security → Secret scanning alerts** for secrets found in the codebase history
- Find hardcoded secrets or credentials in the source code (check config files, `app.ts`, and route handlers)
- Replace hardcoded values with `process.env` references and document the required environment variables
- Review **Security → Dependabot alerts** filtered to critical and high severity
- For at least 2 Dependabot alerts, open the alert detail, read the CVE description, and understand what the vulnerability actually is
- Validate secret and dependency changes through your pull request checks, annotations, and push protection results
- Record the exposure response, dependency ownership, and any time-bound exception in the shared governance practice
- Apply the same expectation to human- and agent-authored changes: no bypass or exception is complete without an accountable human owner and evidence

> [!IMPORTANT]
> **Bring your own application (do this first)**
>
> This activity is most valuable when the secrets and dependency work *outlives the delivery session*. Use the real application repository you want to secure so secret scanning, push protection, Dependabot alerts, and dependency fixes improve a repo your team keeps.
>
> - **Have a candidate?** If you have an application repo in an organization you control with GHAS enabled, use it everywhere this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice-Shop-specific setup and review your own secret scanning alerts, high or critical Dependabot alerts, and configuration files instead.
> - **No suitable one?** Use the fallback from S00: OWASP Juice Shop as a safe practice target for learning the secret and dependency remediation workflow.
>
> Tell your coach which path you took — bringing your own is the goal; Juice Shop is the fallback.
>

## Success Criteria

- [ ] An exposed hardcoded secret is removed from the affected code path, with revocation or rotation assessed and recorded
- [ ] Replacement configuration uses environment variable references (`process.env.VARIABLE_NAME`) and the application still starts and authenticates correctly
- [ ] At least 2 high or critical Dependabot alerts reviewed and understood
- [ ] Pull request checks and security annotations reviewed for your branch changes
- [ ] Secret scanning alerts relevant to your changes addressed or explained
- [ ] The shared governance practice records the response owner, dependency remediation route, and any approved exception with an expiry date
- [ ] Human- and agent-authored changes use the same push-protection, pull-request, and accountable-owner expectations
- [ ] Coach conversation — if you searched your team's repos right now, what is the most likely hardcoded credential or critically vulnerable dependency you'd find, and how long do you think it has been sitting there unnoticed? Talk it through with your coach and connect it to a real project, task, or workflow you own.

**Push protection:** If a new secret is introduced in your branch, push protection should block it before it lands. Treat that block as part of the validation for this activity.

## Learning Resources

- [About secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning)
- [Viewing and updating Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Managing Dependabot pull requests](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/managing-pull-requests-for-dependency-updates)
