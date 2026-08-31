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
- Apply the same expectation to human- and agent-authored changes: no bypass or exception is complete without an accountable human owner and evidence

> [!TIP]
> Working with a real application? Review its own secret scanning and Dependabot alerts.

## Learning Resources

- [About secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning)
- [Viewing and updating Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Managing Dependabot pull requests](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/managing-pull-requests-for-dependency-updates)
