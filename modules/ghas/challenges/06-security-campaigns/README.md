# Activity S06 — Security Campaigns (Advanced)

## Description

You've been fixing vulnerabilities one alert at a time. Now establish the practice that keeps security debt governed after this delivery session. Security campaigns can group related alerts across an entire codebase, assign them to developers, set a deadline, and track remediation progress in a dashboard. They are one implementation option within a broader operating cadence: triage, prioritization, delivery, exception review, measurement, and escalation.

As a delivery team member who has worked in the code and reviewed the alert inventory, you can help scope a campaign that is achievable and accountable. Use risk, business impact, alert volume, remediation effort, and ownership to make the decision visible to the people who must carry it forward.

**Important:** Security campaigns require a GitHub Team plan (or higher) with a Code Security license at the **organization** level. If you have access, create a real campaign. If not, design one on paper — the thinking is the same, and the written output is still valuable evidence that you understand the workflow.

## Objectives

- Review the remaining open alerts across all categories from your earlier activities
- Complete the **Operating Cadence** section of `modules/ghas/resources/ghas-governance-practice.template.md`: triage and campaign review frequency, participants, measures, escalation, and leadership or risk reporting path
- Decide on a campaign scope: which vulnerability class would you tackle first if you were running this as a real remediation sprint? Justify the choice using risk, business impact, volume, effort, and ownership.
- If org access is available: navigate to **Security Overview** at the org level, create a campaign, set a name, description, and due date, and add at least 5 relevant alerts to it
- If org access is unavailable: use the shared governance practice to record the equivalent scope, assignees, timeline, definition of done, and tracking approach
- Define how fixed, in-progress, accepted-risk, and overdue findings are reviewed and escalated
- Confirm that agent-authored changes remain subject to the same human accountability, pull-request, and GHAS evidence as other changes

> [!IMPORTANT]
> **Bring your own application (do this first)**
>
> This activity is most valuable when the campaign plan *outlives the delivery session*. Use the real application repository or organization you want to secure so the campaign scope, alert grouping, owners, and remediation plan map to security debt your team can actually reduce.
>
> - **Have a candidate?** If you have an application repo or org in an organization you control with GHAS enabled, use it everywhere this guide references Juice Shop or `ghec-ghas-00-juice-shop`. Skip the Juice-Shop-specific setup and build the campaign around a real alert class from your own Security Overview instead of the Juice Shop practice alerts.
> - **No suitable one?** Use the fallback from S00: OWASP Juice Shop as a safe practice target for designing or creating a security campaign.
>
> Tell your coach which path you took — bringing your own is the goal; Juice Shop is the fallback.
>

## Success Criteria

- [ ] Operating cadence documented: triage and campaign review frequency, participants, escalation, reporting path, and measures
- [ ] Campaign scope defined and justified with risk, business impact, volume, effort, and accountable ownership
- [ ] **Option A:** Security campaign created with name, due date, and at least 5 alerts scoped — progress tracked in the campaign view
- [ ] **Option B (no org access):** Shared governance practice records scope, assignees, timeline, definition of done, and tracking approach
- [ ] Accepted-risk and overdue findings have an accountable owner, rationale, and review or expiry date
- [ ] Human- and agent-authored changes have the same accountable-owner, pull-request, and GHAS validation expectations
- [ ] Coach conversation — if you had to pitch a security campaign for your own team's codebase today, which vulnerability class would you tackle first, how would you make the case to your engineering lead, and what would your definition of done actually be? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Paste your list of remaining alerts and ask: *"If I were running a 2-day security sprint, which of these would you prioritize and in what order? Explain your reasoning."*
- Ask: *"What's a good definition of done for a SQL injection remediation campaign?"*
- Ask: *"Draft a campaign description I could use for a GitHub Security Campaign targeting injection vulnerabilities in a Node.js/Express application. Include ownership, evidence, and a review date."*

## Learning Resources

- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Fixing alerts in a security campaign](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/fixing-alerts-in-security-campaign)
- [Security campaigns GA announcement](https://github.blog/changelog/2025-04-07-security-campaigns-are-now-generally-available-to-help-address-security-debt-at-scale/)
- [About security overview](https://docs.github.com/en/code-security/security-overview/about-security-overview)
