# Activity S01 — Explore the Attack Surface

## Description

Before you fix anything, you need to understand what you're dealing with. GHAS is already running on the org repository provisioned in S00. CodeQL has scanned the default branch, Dependabot has checked every dependency, and secret scanning has reviewed every commit. The results are waiting for you in the Security tab.

Juice Shop is intentionally vulnerable. The alerts you'll see aren't theoretical — they're real exploitable flaws in real code. SQL injection that lets attackers bypass authentication. XSS that can hijack user sessions. Broken access control that exposes data it shouldn't. Your job in this activity is to read those alerts, open the affected files, and use Copilot to understand exactly what the code is doing wrong.

This is your reconnaissance phase. Turn the alerts into an owned security-debt
inventory that the delivery team can operate after the session, rather than a
temporary mental model.

> **Before this activity:** Make sure S00 is complete, the org repo exists, required participants have been added, GHAS features are enabled, and you've created your team branch. The Security tab is default-branch oriented. Your branch fixes will be validated later through PR CodeQL checks and code scanning annotations.

## Objectives

- Use your own application repository or service first; use the Juice Shop fallback only when no suitable delivery target is available
- Navigate to the relevant GHAS alerts, including **Security → Code scanning alerts**, and review the open default-branch alerts
- Review at least 5 alerts in full — location, description, and the code path that triggers each finding
- For each reviewed alert, open the affected file in your editor, ask Copilot Chat: *"What does this code do wrong, and how could an attacker exploit it?"*, and verify the explanation against the alert and code path
- Create an owned security-debt inventory in `modules/ghas/resources/ghas-governance-practice.template.md`
- For every inventory item, record the alert category or class, affected repository, service, or component, business or security impact, remediation route, accountable owner or team, target date, current disposition (open, in progress, or accepted risk), and prioritization rationale
- Use the five alert reviews as evidence supporting the inventory and its prioritization
- Check **Security → Dependabot alerts** and record any critical or high-severity dependency vulnerabilities in the inventory

> [!IMPORTANT]
> **Bring your own application (do this first)**
>
> This activity is most valuable when the attack-surface picture *outlives the delivery session*. Use a real application repository you want to secure so the CodeQL, Dependabot, and secret scanning results you review become evidence your team can keep acting on after today.
>
> - **Have a candidate?** If you have an application repo in an organization you control with GHAS enabled, use it everywhere this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice-Shop-specific setup from S00 and review the Security tab for your own repo instead.
> - **No suitable one?** Use the fallback from S00: OWASP Juice Shop as a safe practice target for learning how to inspect alerts.
>
> Tell your coach which path you took — bringing your own is the goal; Juice Shop is the fallback.
>

## Success Criteria

- [ ] A real application repository or service is used first, or Juice Shop is recorded as the fallback practice target
- [ ] At least 5 alerts are reviewed with full alert detail read and used as evidence for the inventory
- [ ] Each reviewed alert has a Copilot explanation of the vulnerability, attacker outcome, and code location that a human verifies against the alert and code path
- [ ] The security-debt inventory in `modules/ghas/resources/ghas-governance-practice.template.md` records alert category or class, affected repository, service, or component, business or security impact, remediation route, accountable owner or team, target date, current disposition, and prioritization rationale for each item
- [ ] Each inventory item has a current disposition of open, in progress, or accepted risk and a prioritization rationale
- [ ] Dependabot alerts are reviewed and any critical or high-severity dependency vulnerabilities are recorded in the inventory
- [ ] Coach conversation connects the inventory to a real project, accountable ownership, risk, and next action

## Copilot Tips

- Open the flagged file and highlight the vulnerable code snippet, then ask: *"Explain this vulnerability to me like I'm going to have to fix it"*
- Ask: *"What OWASP category does this fall under, and what's the standard fix pattern?"*
- Ask: *"If an attacker sent a crafted HTTP request to this endpoint, what could they achieve?"*

## Learning Resources

- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Viewing Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [About CodeQL queries](https://codeql.github.com/docs/writing-codeql-queries/about-codeql-queries/)
