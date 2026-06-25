# Challenge S05 — Secure Secrets & Dependencies

## Description

Two different attack surfaces. Same urgency.

**Hardcoded secrets:** API keys, database passwords, JWT signing keys, and credentials committed to source code are one of the most common and most preventable security failures. Secret scanning alerts are shared at the repository level, while your branch is validated through push protection and pull request security signals. Your job is to remove hardcoded secrets from your branch, move them to environment variables, and make sure the application still works.

**Vulnerable dependencies:** Every package in `package.json` is a potential attack vector. Dependabot alerts and Dependabot security update pull requests are shared repo/default-branch signals. Your job is to review the high and critical severity alerts, understand what the vulnerability in each package actually is, and validate any dependency changes your team makes through your pull request.

Both issues have the same root cause: trusting something external without vetting it. Treating secrets as code. Treating dependencies as permanent. This challenge is about building the habit of not doing that.

## Objectives

- Review the shared **Security → Secret scanning alerts** for secrets found in the codebase history
- Find hardcoded secrets or credentials in the source code (check config files, `app.ts`, and route handlers)
- Replace hardcoded values with `process.env` references and document the required environment variables
- Review **Security → Dependabot alerts** filtered to critical and high severity
- For at least 2 Dependabot alerts, open the alert detail, read the CVE description, and understand what the vulnerability actually is
- Validate secret and dependency changes through your pull request checks, annotations, and push protection results

## Success Criteria

- [ ] No hardcoded secrets, passwords, or credentials remain in source code files
- [ ] Secrets replaced with environment variable references (`process.env.VARIABLE_NAME`)
- [ ] At least 2 high or critical Dependabot alerts reviewed and understood
- [ ] Pull request checks and security annotations reviewed for your branch changes
- [ ] Secret scanning alerts relevant to your changes addressed or explained
- [ ] Application still starts and authenticates correctly after secrets migration
- [ ] Coach conversation — if you searched your team's repos right now, what is the most likely hardcoded credential or critically vulnerable dependency you'd find, and how long do you think it has been sitting there unnoticed? Talk it through with your coach and connect it to a real project, task, or workflow you own.

**Push protection:** If a new secret is introduced in your branch, push protection should block it before it lands. Treat that block as part of the validation for this challenge.

## Learning Resources

- [About secret scanning](https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning)
- [Viewing and updating Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Managing Dependabot pull requests](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/managing-pull-requests-for-dependency-updates)
