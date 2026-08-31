# Activity S06: Security Campaigns (Advanced)

## Description

Define how the team will manage security debt after this session. Security campaigns group related alerts,
assign developers, set a deadline, and track remediation in a dashboard. The
operating cadence around a campaign covers triage, delivery, exception review,
measurement, and escalation.

Use your code and alert knowledge to define a campaign the team can finish. Base the scope on risk, business impact, alert volume, remediation effort, and ownership. Record the decision for the people who will carry the work forward.

**Security campaigns require a GitHub Team plan or higher and an organization-level Code Security license.** If you have access, create a campaign. Otherwise, write the equivalent campaign plan in the governance practice.

## Objectives

- Review the remaining open alerts across all categories from your earlier activities
- Complete the Operating Cadence section of `modules/ghas/resources/ghas-governance-practice.template.md`: triage and campaign review frequency, participants, measures, escalation, and leadership or risk reporting path
- Decide on a campaign scope: which vulnerability class would you tackle first if you were running this as a real remediation sprint? Justify the choice using risk, business impact, volume, effort, and ownership.
- If org access is available: open Security Overview at the org level, create a campaign, set a name, description, and due date, and add at least 5 relevant alerts to it
- If org access is unavailable: use the shared governance practice to record the equivalent scope, assignees, timeline, completion conditions, and tracking approach
- Define how fixed, in-progress, accepted-risk, and overdue findings are reviewed and escalated
- Confirm that agent-authored changes remain subject to the same human accountability, pull-request, and GHAS evidence as other changes

> [!IMPORTANT]
> Use your own application first
>
> - **Real application available:** Use it wherever this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice Shop setup and build the campaign around a real alert class from your Security Overview so the plan addresses security debt your team can reduce.
> - **No suitable application:** Use the S00 OWASP Juice Shop fallback to practice designing or creating a security campaign.
>

## Copilot Tips

- Paste your list of remaining alerts and ask: *"If I were running a 2-day security sprint, which of these would you prioritize and in what order? Explain your reasoning."*
- Ask: *"What completion conditions should a SQL injection remediation campaign use?"*
- Ask: *"Draft a campaign description I could use for a GitHub Security Campaign targeting injection vulnerabilities in a Node.js/Express application. Include ownership, evidence, and a review date."*

## Learning Resources

- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Fixing alerts in a security campaign](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/fixing-alerts-in-security-campaign)
- [Security campaigns GA announcement](https://github.blog/changelog/2025-04-07-security-campaigns-are-now-generally-available-to-help-address-security-debt-at-scale/)
- [About security overview](https://docs.github.com/en/code-security/security-overview/about-security-overview)
