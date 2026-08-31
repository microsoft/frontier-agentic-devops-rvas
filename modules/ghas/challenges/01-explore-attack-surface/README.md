# Activity S01: Explore the Attack Surface

## Description

Map the attack surface before fixing it. GHAS already runs on the org repository
provisioned in S00: CodeQL scans the default branch, Dependabot checks dependencies,
and secret scanning reviews commits. Open the Security tab to see the results.

Juice Shop is intentionally vulnerable. Its alerts describe exploitable flaws in real code, including SQL injection, XSS, and broken access control. Read each alert, open the affected file, and use Copilot to understand the unsafe code.

Turn the alerts into a security findings register with owners so the delivery team
can maintain it after the session.

> Before this activity: Make sure S00 is complete, the org repo exists, required participants have been added, GHAS features are enabled, and you've created your team branch. The Security tab is default-branch oriented. Your branch fixes will be validated later through PR CodeQL checks and code scanning annotations.

## Objectives

- Use your own application repository or service first; use the Juice Shop fallback only when no suitable delivery target is available
- Open the relevant GHAS alerts, including Security → Code scanning alerts, and review the open default-branch alerts
- Review at least 5 alerts in full, including the location, description, and code path that triggers each finding
- For each reviewed alert, open the affected file in your editor, ask Copilot Chat: *"What does this code do wrong, and how could an attacker exploit it?"*, and verify the explanation against the alert and code path
- Create a security findings register with named owners in `modules/ghas/resources/ghas-governance-practice.template.md`
- For every inventory item, record the alert category or class, affected repository, service, or component, business or security impact, remediation route, accountable owner or team, target date, current disposition (open, in progress, or accepted risk), and prioritization rationale
- Use the five alert reviews as evidence supporting the inventory and its prioritization
- Check Security → Dependabot alerts and record any critical or high-severity dependency vulnerabilities in the inventory

> [!IMPORTANT]
> Use your own application first
>
> - **Real application available:** Use it wherever this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the S00 Juice Shop setup and review your repository's Security tab so the results remain useful after the session.
> - **No suitable application:** Use the S00 OWASP Juice Shop fallback to practice inspecting alerts.
>

## Copilot Tips

- Open the flagged file, highlight the vulnerable code, and ask: *"Explain this vulnerability to me like I'm going to have to fix it"*
- Ask: *"What OWASP category does this fall under, and what's the standard fix pattern?"*
- Ask: *"If an attacker sent a crafted HTTP request to this endpoint, what could they achieve?"*

## Learning Resources

- [Managing code scanning alerts](https://docs.github.com/en/code-security/code-scanning/managing-code-scanning-alerts/managing-code-scanning-alerts-for-your-repository)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Viewing Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/viewing-and-updating-dependabot-alerts)
- [About CodeQL queries](https://codeql.github.com/docs/writing-codeql-queries/about-codeql-queries/)
