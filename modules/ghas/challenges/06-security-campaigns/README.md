# Activity S06 — Security Campaigns (Advanced)

## Description

You've been fixing vulnerabilities one alert at a time. Now zoom out. Security campaigns let you group related alerts across an entire codebase, assign them to developers, set a deadline, and track remediation progress in a dashboard. It's the difference between a developer heroically fixing one SQL injection versus a team systematically eliminating the entire class of injection vulnerabilities in a coordinated sprint.

As the developer who just spent the last few activities in the code, you're in the best position to scope a campaign: you know which vulnerability classes are most prevalent, which are highest risk, and roughly how much effort each fix takes. Use that knowledge to design a campaign that's actually achievable.

**Important:** Security campaigns require a GitHub Team plan (or higher) with a Code Security license at the **organization** level. If you have access, create a real campaign. If not, design one on paper — the thinking is the same, and the written output is still valuable evidence that you understand the workflow.

## Objectives

- Review the remaining open alerts across all categories from your earlier activities
- Decide on a campaign scope: which vulnerability class would you tackle first if you were running this as a real remediation sprint? Justify your choice.
- If org access is available: navigate to **Security Overview** at the org level, create a campaign, set a name, description, and due date, and add at least 5 relevant alerts to it
- If org access is unavailable: write a campaign plan document covering: scope (which alert types), assignees (which team roles), timeline, definition of done, and how you'd track progress
- Track or document progress: which alerts are fixed, which are in progress, which are deferred and why

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

- [ ] Campaign scope defined and justified with rationale (risk, volume, effort)
- [ ] **Option A:** Security campaign created with name, due date, and at least 5 alerts scoped — progress tracked in the campaign view
- [ ] **Option B (no org access):** Written campaign plan covering scope, assignees, timeline, and definition of done
- [ ] Reflection written: what would you prioritize in a real production codebase, and why?
- [ ] Coach conversation — if you had to pitch a security campaign for your own team's codebase today, which vulnerability class would you tackle first, how would you make the case to your engineering lead, and what would your definition of done actually be? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Copilot Tips

- Paste your list of remaining alerts and ask: *"If I were running a 2-day security sprint, which of these would you prioritize and in what order? Explain your reasoning."*
- Ask: *"What's a good definition of done for a SQL injection remediation campaign?"*
- Ask: *"Draft a campaign description I could use for a GitHub Security Campaign targeting injection vulnerabilities in a Node.js/Express application."*

## Learning Resources

- [About security campaigns](https://docs.github.com/en/code-security/concepts/security-at-scale/about-security-campaigns)
- [Fixing alerts in a security campaign](https://docs.github.com/en/code-security/how-tos/manage-security-alerts/remediate-alerts-at-scale/fixing-alerts-in-security-campaign)
- [Security campaigns GA announcement](https://github.blog/changelog/2025-04-07-security-campaigns-are-now-generally-available-to-help-address-security-debt-at-scale/)
- [About security overview](https://docs.github.com/en/code-security/security-overview/about-security-overview)
