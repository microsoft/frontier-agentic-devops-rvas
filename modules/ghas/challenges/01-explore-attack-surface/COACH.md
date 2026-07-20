# Explore the Attack Surface — Coach Guide

> Audience: facilitators and coaches. Pair with the delivery team member `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the customer practitioner to connect the exercise to work they actually own.

**Their question:** Coach conversation — if GHAS were scanning your real production repos today the way it scanned Juice Shop, which vulnerability class do you think would have the most open alerts, and how would you even find out? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Which specific repo or service in your work would have the most GHAS alerts today — name it, then describe what kind of code lives there and who owns it.
- For that repo, which alert category — code scanning, Dependabot, or secret scanning — do you think carries the highest real-world blast radius if an attacker found it first?
- What one concrete action could you take this week to start reducing the attack surface you just described?

## Facilitation objectives
- Reinforce how customer delivery team members navigate CodeQL, Dependabot, and secret scanning alerts in the shared repository.
- Help customer delivery team members turn alert details into an attack-surface map they can use in later fix activities.
- Encourage customer delivery team members to use Copilot Chat to explain exploitability without outsourcing all security reasoning.

## Common delivery team member blockers
- Customer delivery team members may confuse shared default-branch alerts with their personal branch work; remind them this activity is reconnaissance only and later PR checks validate fixes.
- Customer delivery team members often skim alert titles without opening full paths and traces; push them to inspect locations, flows, and surrounding code before summarizing.
- Dependabot can feel separate from code scanning; frame it as another part of the same attack surface inventory.

## Facilitation hints
- Have customer delivery team members group alerts by class and likely remediation effort before they choose a fix order.
- Ask them to explain one alert in plain language: what input is attacker-controlled, what sink is dangerous, and what impact follows.
- If they rely too heavily on Copilot, ask them to verify the explanation against the actual code path.
- Encourage notes they can reuse in S02-S06 so the reconnaissance work pays off later.

## Validation checklist
Verify each success criterion from the customer delivery team guide:
- [ ] At least 5 code scanning alerts reviewed with alert detail read
- [ ] Each reviewed alert has a Copilot-generated explanation of: what the vulnerability is, what an attacker could do with it, and where in the code it lives
- [ ] Alerts grouped by vulnerability class with a fix order documented
- [ ] Dependabot alerts reviewed — any critical/high severity ones noted

## Assessment rubric (100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Alert evidence | 25 | Reviewed enough code scanning, Dependabot, and secret scanning detail to explain real paths and severity. |
| Attack-surface map | 25 | Grouped findings by vulnerability class, affected component, and likely remediation order. |
| Copilot-assisted reasoning | 20 | Used Copilot to explain exploitability, then verified the explanation against alert traces and code. |
| Prioritization | 15 | Selected a fix order based on blast radius, exploitability, and effort rather than alert titles alone. |
| Grounding conversation | 15 | Connected the alert classes to a real team repo, ownership model, and next action. |
