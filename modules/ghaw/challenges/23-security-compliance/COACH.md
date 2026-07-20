---

## Facilitated application

Required facilitator check-in: before completion, ask the customer practitioner to connect the exercise to work they actually own.

Discuss: How does your team track vulnerabilities and SLA deadlines today, and where would deadline-aware agent-filed issues close a real gap versus create excessive findings that would undermine the process? Connect it to a project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask how their team tracks vulnerabilities and SLA deadlines today.
- Tease apart where deadline-aware agent issues close a real gap versus create excessive findings.
- Have them define the severity-to-SLA mapping they'll pilot on one repo next week.

## What This Activity Teaches

Policy in version-controlled configuration means encoding security service-level agreements and vulnerability response procedures directly into a workflow. Participants learn to turn a compliance spreadsheet into an automated agent that tracks deadlines, classifies by severity, and reports threshold breaches. The key insight is that this workflow does more than scan: it detects, classifies, tracks, and alerts. It does not remediate vulnerabilities or prevent exposure; a team must evaluate and act on its reports.


Official grounding: keep the workflow mechanics aligned with GitHub Actions syntax and token permissions, and keep vulnerability language aligned with GitHub's [Dependabot alerts](https://docs.github.com/en/code-security/dependabot/dependabot-alerts/about-dependabot-alerts) and [Advisory Database](https://docs.github.com/en/code-security/security-advisories/working-with-global-security-advisories-from-the-github-advisory-database/about-the-github-advisory-database) docs.

---

## Expected Solution Shape

```markdown
---
on:
  schedule:
    - cron: "0 8 * * *"
  workflow_dispatch: {}

permissions:
  issues: write
  security-events: read

safe-outputs:
  create-issue: {}

tools:
  github:
    toolsets: [security]

engine: copilot
---

# Security Compliance

Review open Dependabot alerts and security advisories for this repository.

SLA policy:
- Critical: must be remediated within 3 days of disclosure
- High: 14 days
- Medium: 30 days
- Low: 90 days

For each alert:
1. Determine severity and the date it was disclosed/opened
2. Calculate days remaining until SLA breach
3. If days remaining <= 2 (for critical) or <= 5 (for others): open an issue

Issue format:
- Title: "⚠️ SLA Approaching: [CVE-ID] — [package] ([severity])"
- Body: CVE ID, package name, severity, disclosure date, SLA deadline, days remaining, link to advisory
- Label: `security`, `sla-warning`

Do not open duplicate issues for the same CVE. If an open issue already exists for this CVE, skip it.
```

---

## Common Blockers

| Symptom | Fix |
|---------|-----|
| No Dependabot alerts to find | Have participant add a known vulnerable dep, or mock alerts in the prompt body |
| "security-events: read" permission denied | Ensure the repo has Dependabot alerts enabled (Settings > Security) |
| Duplicate issues opened every day | Add explicit dedup instruction: "If open issue exists for this CVE, skip" |
| Severity mapping is wrong | Clarify in body: "Severity levels match GitHub's: critical, high, medium, low" |
| Agent can't find `toolsets: [security]` | Confirm `gh aw` version supports security toolset — fallback to describing alerts in the prompt body |

---

## How to Verify It's Working

1. Add `lodash@4.17.4` (known CVE) or similar to `package.json` — push and wait for Dependabot to detect it
2. Trigger `workflow_dispatch`
3. Confirm an issue opens with CVE ID, severity, and days-remaining calculation
4. Trigger again — confirm no duplicate issue opens
5. Close the issue manually — confirm next run re-opens it if the advisory is unresolved

---

## Coaching Notes

The deeper lesson is policy codification. Ask: _"Where does your team's vulnerability SLA policy currently live?"_ Usually it's in a Notion doc, a spreadsheet, or someone's head. This workflow makes it executable and auditable.

Participants sometimes want to skip the issue and go straight to auto-PRs that bump the dependency. Redirect: the issue-creation-first pattern is intentional — Dependabot already handles auto-bumping, but SLA tracking and escalation are the gap this workflow fills.

Fast squads: extend the severity routing. Critical issues get `@security-team` mentioned in the body; low severity gets a comment on an existing issue rather than a new one.
