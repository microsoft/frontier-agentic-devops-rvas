# Explore the Attack Surface — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Facilitation objectives
- Reinforce how students navigate CodeQL, Dependabot, and secret scanning alerts in the shared repository.
- Help students turn alert details into an attack-surface map they can use in later fix challenges.
- Encourage students to use Copilot Chat to explain exploitability without outsourcing all security reasoning.

## Common student blockers
- Students may confuse shared default-branch alerts with their personal branch work; remind them this challenge is reconnaissance only and later PR checks validate fixes.
- Students often skim alert titles without opening full paths and traces; push them to inspect locations, flows, and surrounding code before summarizing.
- Dependabot can feel separate from code scanning; frame it as another part of the same attack surface inventory.

## Facilitation hints
- Have students group alerts by class and likely remediation effort before they choose a fix order.
- Ask them to explain one alert in plain language: what input is attacker-controlled, what sink is dangerous, and what impact follows.
- If they rely too heavily on Copilot, ask them to verify the explanation against the actual code path.
- Encourage notes they can reuse in S01-S05 so the reconnaissance work pays off later.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] At least 5 code scanning alerts reviewed with alert detail read
- [ ] Each reviewed alert has a Copilot-generated explanation of: what the vulnerability is, what an attacker could do with it, and where in the code it lives
- [ ] Alerts grouped by vulnerability class with a fix order documented
- [ ] Dependabot alerts reviewed — any critical/high severity ones noted

## Source
Derived from [microsoft/frontier-ghas-hackathon](https://github.com/microsoft/frontier-ghas-hackathon), MIT license.
