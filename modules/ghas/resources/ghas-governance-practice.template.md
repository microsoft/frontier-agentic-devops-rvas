# GHAS Governance Practice

Use this template with a customer-owned repository or service whenever possible.
Use the Juice Shop fallback only for safe practice. Do not record credentials,
full alert payloads, customer data, or other sensitive information here.

## 1. GHAS Configuration and Ownership

| Field | Decision or evidence |
|---|---|
| Repository, service, or portfolio in scope | |
| Criticality and material business or customer impact | |
| GHAS capabilities enabled | Code scanning / Dependabot alerts / secret scanning / push protection |
| Missing capability, licensing, or access blocker | |
| Blocker owner and target date | |
| Repository or service owner | |
| Security partner or escalation contact | |
| Delivery team accountable for remediation | |

### Agentic delivery principles

- Agents receive only the repository and token permissions required for their
  assigned work.
- A human remains accountable for review and merge decisions.
- Agent-authored changes follow the same pull-request, GHAS, and test evidence
  expected of human-authored changes.
- Exceptions are recorded, time-bound, and approved by the accountable owner.

## 2. Security Findings Register

| Finding class / alert category | Repository, service, or component | Impact | Remediation route | Accountable owner or team | Target date | Disposition | Prioritization rationale |
|---|---|---|---|---|---|---|---|
| | | | | | | Open / In progress / Accepted risk | |

Use alert details and code review as evidence. Verify any Copilot explanation
against the alert trace and the affected code before recording a decision.

## 3. Prevention Patterns

Add one entry when remediation establishes a practice the team can reuse.

| Finding class / unsafe pattern | Approved safe pattern | Applies to | PR and review evidence | GHAS or test validation | Accountable owner | Human and agent change expectation |
|---|---|---|---|---|---|---|
| | | | | | | |

## 4. Secret and Dependency Response

| Item | Decision or evidence |
|---|---|
| Exposed secret: revoke or rotate action | |
| Exposure and impact assessment | |
| Replacement configuration and validation | |
| Dependency owner and update approach | |
| Exception or accepted risk | |
| Exception approver and expiry date | |

## 5. Operating Cadence

| Cadence | Participants | Decisions and evidence | Escalation or reporting path |
|---|---|---|---|
| Team triage | | | |
| Security campaign review | | | |
| Leadership or risk review | | | |

### Measures

- Open findings by severity, category, owner, and age
- Findings within and outside their target date or remediation commitment
- Fixed, accepted-risk, and overdue findings
- Coverage of in-scope repositories and enabled GHAS capabilities
- Recurrence of recorded prevention patterns
