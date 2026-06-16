# Challenge S-00: Explore the Attack Surface

## Description

Before you fix anything, you need to understand what you're dealing with. GHAS is already running on the shared org repository. CodeQL has scanned the default branch, Dependabot has checked every dependency, and secret scanning has reviewed every commit. The shared results are waiting for you in the Security tab.

Juice Shop is intentionally vulnerable. The alerts you'll see aren't theoretical — they're real exploitable flaws in real code. SQL injection that lets attackers bypass authentication. XSS that can hijack user sessions. Broken access control that exposes data it shouldn't. Your job in this challenge is to read those alerts, open the affected files, and use Copilot to understand exactly what the code is doing wrong.

This is your reconnaissance phase. Build a mental model of the vulnerability surface so the fix challenges that follow have real context.

> **Before this challenge:** Make sure your organizer has completed environment setup and that you've created your team branch (see [GHAS Module Setup](../../setup.md) for Juice Shop provisioning options: Codespaces, local Docker, or organizer-hosted). The Security tab is shared and default-branch oriented. Your branch fixes will be validated later through PR CodeQL checks and code scanning annotations.

## Objectives

- Navigate to **Security → Code scanning alerts** in the shared org repo and review the open default-branch alerts
- Open at least 5 alerts and read the full alert detail — location, description, and the code path that triggers it
- For each alert, open the affected file in your editor and ask Copilot Chat: *"What does this code do wrong, and how could an attacker exploit it?"*
- Group your alerts by vulnerability class (injection, XSS, access control, secrets, etc.) to plan your fix order
- Check **Security → Dependabot alerts** and note any critical or high-severity dependency vulnerabilities

## Success Criteria

- [ ] At least 5 code scanning alerts reviewed with alert detail read
- [ ] Each reviewed alert has a Copilot-generated explanation of: what the vulnerability is, what an attacker could do with it, and where in the code it lives
- [ ] Alerts grouped by vulnerability class with a fix order documented
- [ ] Dependabot alerts reviewed — any critical/high severity ones noted
- [ ] Coach conversation — if GHAS were scanning your real production repos today the way it scanned Juice Shop, which vulnerability class do you think would have the most open alerts, and how would you even find out? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Open the flagged file and highlight the vulnerable code snippet, then ask: *"Explain this vulnerability to me like I'm going to have to fix it"*
- Ask: *"What OWASP category does this fall under, and what's the standard fix pattern?"*
- Ask: *"If an attacker sent a crafted HTTP request to this endpoint, what could they achieve?"*

## Learning Resources

- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Viewing Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [About CodeQL queries](https://codeql.github.com/docs/writing-codeql-queries/about-codeql-queries/)
