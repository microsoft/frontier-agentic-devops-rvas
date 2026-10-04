# GHAS decision gaps

**Use existing GitHub work first.** Fill in this optional template only for
missing decisions. Link to records you already have instead of copying them.

Do not record credentials, customer data, or full alert payloads.

| Missing decision | Owner and decision or evidence link |
| --- | --- |
| Repository or service in scope | |
| Required control or access blocker, with retest date | |
| Remediation ownership or escalation | |
| Approved safe pattern worth reusing | |
| Real credential response and evidence that the old credential no longer works | |
| Dependency fix PR with test results and final alert state | |

## Exceptions, only when needed

Use the customer's approved risk system. Link the alert and record why the team
needs an exception and who approved it. Include the compensating control, expiry,
and return path. Do not create an exception just to complete a lab.

## Review expectations

Give agents only the permissions they need. Human reviewers remain accountable
for merges. Agent-authored changes must pass the same tests and security checks
as other changes.
