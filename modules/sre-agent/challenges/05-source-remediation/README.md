# Activity 05: Hand the incident to engineering

**Session outcome:** A real GitHub issue links the incident from Activity 04 to source evidence and a validation plan. An engineering owner has accepted the follow-up.

## Scenario

Connect source code so Azure SRE Agent can link incident evidence to a likely fault.
Ask it to draft a work item, then validate the evidence and publish the issue.
Drafts and fallback packets are practice only. They do not complete a customer
engineering handoff.

## Goals

- Connect the selected service's GitHub repository using approved access.
- Ask the agent to correlate symptoms with source-code areas.
- Create a real GitHub issue that links the incident to source evidence. Have an engineering owner accept the follow-up.
- Optionally review an agent-proposed pull request.
- Require human review before accepting a change for production.

> [!TIP]
> You can replace the Grubify incident with one from your team's service.
> Use the repository that contains the suspected code. Follow the team's issue or pull request
> process, with evidence, stated uncertainty, validation, and human review.

## Connect source code

For customer work, connect the repository for the selected service in the Azure
SRE Agent portal. Do not create a `grubify` repository for an existing service.
Use the Grubify starter-lab instructions below for sample practice.
In GitHub Enterprise Managed User (EMU) environments, participants may not be able to
fork public repositories into personal accounts. Use an enterprise-owned repository instead.

The current starter lab expects the connected repository to be named `grubify` and uses the value of `GITHUB_USER` as the repository owner. Use one of these paths:

| Environment | What to use |
| --- | --- |
| Personal GitHub account allowed | Fork `https://github.com/dm-chelupati/grubify` to `<your-user>/grubify`. |
| EMU or enterprise-managed account | Use the enterprise owner that contains `<owner>/grubify`. |
| GitHub blocked or repo name differs | Use the fallback source packet, or connect the repository manually in the Azure SRE Agent portal if supported. |

Enable Issues on the lab repository before connecting it. The source-code and issue-triage scenarios need issue read/write access.

From the starter lab directory, set the repository owner and rerun post-provision setup:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
azd env set GITHUB_USER <repo-owner>
bash scripts/post-provision.sh --retry
```

For example, for `https://github.com/contoso-team-01/grubify`, run:

```bash
azd env set GITHUB_USER contoso-team-01
bash scripts/post-provision.sh --retry
```

When the OAuth URL appears, open it in a browser and authorize with the GitHub account that has access to the lab repository. Do not paste GitHub tokens into chat or notes.

You can also connect GitHub through the Azure SRE Agent portal. Use the least-privilege option available for your environment.

If GitHub connection is blocked, record the blocker. You can still create the real
issue manually using approved incident and source evidence. Record that the
agent's connector did not work.

## Ask for code-aware root cause analysis

Use Azure SRE Agent, substituting the same incident and service:

```text
Using the Grubify incident evidence and connected source code, identify the most likely source area. Include file and line references only where you have evidence. Create a remediation work item with symptom, evidence, likely cause, alternative hypothesis, and validation plan.
```

If the agent cannot create an issue directly, ask it to draft the issue body and create it manually.

## Remediation work item template

```md
## Customer-safe summary

## Operational evidence
- Incident link:
- Alert:
- Logs:
- Trace/exception:
- User-visible symptom:

## Suspected source area
- Source link with the repository revision and file location:
- Why this is a lead:

## Likely cause

## Alternative hypothesis

## Proposed remediation

## Validation and recovery status

## Human review gate
- Engineering owner:
- Acceptance decision and next action:
```

## Optional pull request review

If the agent or a coding assistant proposes a pull request:

1. Inspect the diff.
2. Confirm it only touches the suspected area.
3. Check tests or validation evidence.
4. Confirm no secrets or tenant details are added.
5. Approve, request changes, or reject the pull request.

**Do not merge a change because its summary sounds confident.**

For implementation, continue to [GHEC 19](../../../ghec/challenges/19-copilot-coding-agent/README.md)
with **this same incident-linked issue** and its source evidence. Do not
substitute an unrelated bug. A PR is optional here. The engineering owner must
accept the follow-up.

## Deliverables

- Link the real GitHub issue to the Activity 04 incident and source evidence the reviewer can inspect.
- Record the validation plan and the engineering owner's acceptance, with a next action.
- State whether the connector worked and whether recovery was tested.

Without an accepted issue for a real incident, customer adoption remains incomplete.
