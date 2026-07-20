# Explore the Attack Surface — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team member `README.md`.

## Required coach check-in

Required coach check-in: before completion, ask the customer practitioner to connect the exercise to work they actually own.

Their question: Coach conversation — which inventory item creates the most important
business or security risk for the real project, who is accountable for it, and what
should its next action and target date be?

Use these follow-ups to steer the conversation:
- Which specific repo or service in your work would have the most GHAS alerts today — name it, then describe what kind of code lives there and who owns it.
- For that repo, which alert category — code scanning, Dependabot, or secret scanning — would affect the most systems or data if an attacker found it first?
- Is remediation the right route, or is accepted risk appropriate? Who has authority to own that decision?
- What one concrete action could you take this week to start reducing the security debt you just described?

## Facilitation objectives
- Reinforce how customer delivery team members navigate CodeQL, Dependabot, and secret scanning alerts in the shared repository.
- Help customer delivery team members create a security findings register with named owners in `modules/ghas/resources/ghas-governance-practice.template.md`, using their application first and Juice Shop only as the fallback.
- Guide impact, remediation route, accountable ownership, target date, current disposition, and prioritization rationale—not vulnerability labels alone.
- Encourage customer delivery team members to use Copilot Chat to explain exploitability, then verify each explanation against the alert and actual code path.

## Common delivery team member blockers
- Customer delivery team members may confuse shared default-branch alerts with their personal branch work; remind them this activity is reconnaissance only and later PR checks validate fixes.
- Customer delivery team members often skim alert titles without opening full paths and traces; push them to inspect locations, flows, and surrounding code before summarizing.
- Dependabot can feel separate from code scanning; frame it as another part of the same attack surface inventory.

## Facilitation hints
- Have customer delivery team members review at least five alerts in full and use those reviews as evidence for inventory items.
- For every inventory item, require the alert category or class; affected repository, service, or component; business or security impact; remediation route; accountable owner or team; target date; current disposition; and prioritization rationale.
- Have customer delivery team members distinguish open, in progress, and accepted risk, then ask whether the owner and target date make the disposition operable.
- Ask them to explain one alert in plain language: what input is attacker-controlled, what sink is dangerous, and what impact follows.
- If they rely too heavily on Copilot, ask them to verify the explanation against the actual code path.
- Keep Dependabot findings in the same inventory; record any critical or high-severity dependency vulnerabilities.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] A real application repository or service is used first, or Juice Shop is recorded as the fallback practice target
- [ ] At least 5 alerts are reviewed with full alert detail read and used as evidence for the inventory
- [ ] Each reviewed alert has a Copilot explanation of the vulnerability, attacker outcome, and code location that a human verifies against the alert and code path
- [ ] The security findings register in `modules/ghas/resources/ghas-governance-practice.template.md` records alert category or class, affected repository, service, or component, business or security impact, remediation route, accountable owner or team, target date, current disposition, and prioritization rationale for each item
- [ ] Each inventory item has a current disposition of open, in progress, or accepted risk and a prioritization rationale
- [ ] Dependabot alerts are reviewed and any critical or high-severity dependency vulnerabilities are recorded in the inventory
- [ ] Coach conversation connects the inventory to a real project, accountable ownership, risk, and next action

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Alert evidence | 25 | Reviewed at least five alerts in full and used them as evidence for the inventory. |
| Operable inventory | 25 | Recorded all required fields, including impact, route, owner, date, disposition, and rationale. |
| Copilot-assisted reasoning | 20 | Used Copilot to explain exploitability, then verified the explanation against alert traces and code. |
| Prioritization and risk | 15 | Chose a disposition and priority based on business or security impact, ownership, and remediation route. |
| Coach check-in | 15 | Connected findings to a real team repo or service, accountable ownership, risk, and next action. |
