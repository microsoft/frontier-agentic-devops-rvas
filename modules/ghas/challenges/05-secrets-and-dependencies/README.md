# Activity S05: Secure Secrets & Dependencies

## Description

Hardcoded API keys, database passwords, JWT signing keys, and other credentials are
preventable security failures. Secret scanning alerts apply at the repository
level; push protection and pull request security signals validate your branch.
Remove the exposed value, decide whether to revoke or rotate it, move replacement
configuration out of source control, and confirm that the application still works.

Dependencies can also expose the application. Dependabot alerts and security update pull requests are shared repository and default-branch signals. Review high and critical alerts, understand each package vulnerability, and validate dependency changes through your pull request.

Both issues need an accountable response. Record the owner, validation, accepted risk, and exception expiry in `modules/ghas/resources/ghas-governance-practice.template.md`.

## Objectives

- Review the shared Security → Secret scanning alerts for secrets found in the codebase history
- Find hardcoded secrets or credentials in the source code (check config files, `app.ts`, and route handlers)
- Replace hardcoded values with `process.env` references and document the required environment variables
- Review Security → Dependabot alerts filtered to critical and high severity
- For at least 2 Dependabot alerts, open the alert detail, read the CVE description, and understand what the vulnerability actually is
- Validate secret and dependency changes through your pull request checks, annotations, and push protection results
- Record the exposure response, dependency ownership, and any time-bound exception in the shared governance practice
- Apply the same expectation to human- and agent-authored changes: no bypass or exception is complete without an accountable human owner and evidence

> [!IMPORTANT]
> Use your own application first
>
> - **Real application available:** Use it wherever this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice Shop setup and review your own secret scanning alerts, high or critical Dependabot alerts, and configuration files so the work improves a repository your team maintains.
> - **No suitable application:** Use the S00 OWASP Juice Shop fallback to practice the secret and dependency remediation workflow.
>
> Tell your coach which path you chose.
>

## Success Criteria

- [ ] An exposed hardcoded secret is removed from the affected code path, with revocation or rotation assessed and recorded
- [ ] Replacement configuration uses environment variable references (`process.env.VARIABLE_NAME`) and the application still starts and authenticates correctly
- [ ] At least 2 high or critical Dependabot alerts reviewed and understood
- [ ] Pull request checks and security annotations reviewed for your branch changes
- [ ] Secret scanning alerts relevant to your changes addressed or explained
- [ ] The shared governance practice records the response owner, dependency remediation route, and any approved exception with an expiry date
- [ ] Human- and agent-authored changes use the same push-protection, pull-request, and accountable-owner expectations
- [ ] Coach conversation: Identify the hardcoded credential or critically vulnerable dependency you are most likely to find in your team's repositories. Estimate how long it may have gone unnoticed, then discuss a real project, task, or workflow with your coach.

**Push protection:** If your branch introduces a new secret, push protection should block it before it lands. Treat the block as validation evidence.

## Learning Resources

- [About secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning)
- [Viewing and updating Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Managing Dependabot pull requests](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/managing-pull-requests-for-dependency-updates)
