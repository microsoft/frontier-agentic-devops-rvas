# Activity S06: Security campaigns (advanced)

**Session outcome:** Your remediation campaign has owners and a deadline, with an agreed triage and review cadence. With organization access, it contains at least five alerts. Otherwise, your shared governance record defines the scope and tracking plan.

## Description

Define how the team will manage security debt after this session. Use security
campaigns to group related alerts, assign developers, set a deadline, and track
remediation in a dashboard. Define when the team will triage findings, review
delivery and exceptions, measure progress, and escalate delays.

Choose a campaign the team can finish. Base the scope on risk, business impact, alert volume, remediation effort, and ownership. Record the decision for the people who will do the work.

**Security campaigns require a GitHub Team plan or higher and an organization-level Code Security license.** If you have access, create a campaign. Otherwise, write the equivalent campaign plan in the governance practice.

## Objectives

- Review the remaining open alerts across all categories from your earlier activities
- Complete the Operating cadence section of `modules/ghas/resources/ghas-governance-practice.template.md`. Record triage and campaign review frequency, participants, measures, escalation, and the leadership or risk reporting path.
- Choose the vulnerability class to tackle first in a remediation sprint. Justify the choice using risk, business impact, volume, effort, and ownership.
- If you have org access, open Security Overview at the org level. Create a campaign with a name, description, and due date, then add at least 5 relevant alerts.
- If you do not have org access, record the equivalent scope, assignees, timeline, completion conditions, and tracking approach in the shared governance practice.
- Define how fixed, in-progress, accepted-risk, and overdue findings are reviewed and escalated
- Confirm that agent-authored changes remain subject to the same human accountability, pull-request, and GHAS evidence as other changes

> [!TIP]
> Working with a real application? Build the campaign around an alert class from its Security Overview.

## Copilot tips

- Paste your list of remaining alerts and ask: *"If I were running a 2-day security sprint, which of these would you prioritize and in what order? Explain your reasoning."*
- Ask: *"What completion conditions should a SQL injection remediation campaign use?"*
- Ask: *"Draft a campaign description I could use for a GitHub Security Campaign targeting injection vulnerabilities in a Node.js/Express application. Include ownership, evidence, and a review date."*

## Learning resources

- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Fixing alerts in a security campaign](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/fixing-alerts-in-security-campaign)
- [Security campaigns GA announcement](https://github.blog/changelog/2025-04-07-security-campaigns-are-now-generally-available-to-help-address-security-debt-at-scale/)
- [About security overview](https://docs.github.com/en/code-security/security-overview/about-security-overview)
