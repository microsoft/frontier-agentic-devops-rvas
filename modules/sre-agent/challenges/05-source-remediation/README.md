# Activity 05: Connect source code and create remediation work

**Session outcome:** Your remediation issue or draft links incident evidence to suspected code and explains how to validate a fix. A human reviewer has recorded what to accept or investigate next. You can use the fallback source packet if the live connection is blocked.

## Scenario

Connect source code so Azure SRE Agent can link incident evidence to a likely fault.
Ask it to draft a fix or work item, then validate the evidence and have a human review it.
Use a source packet if a live connection is unavailable.

## Goals

- Connect a GitHub repository to Azure SRE Agent when available.
- Ask the agent to correlate symptoms with source-code areas.
- Create a GitHub issue or remediation summary with evidence.
- Optionally review an agent-proposed pull request.
- Require human review before accepting a change for production.

> [!TIP]
> **Use your own service.** You can replace the Grubify incident with one from your team's service.
> Use the repository that contains the suspected code. Follow the team's issue or pull request
> process, with evidence, stated uncertainty, validation, and human review.

## Connect source code

If your live lab supports GitHub connection, use an approved lab repository.
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

If GitHub connection is blocked, use the fallback packet with source snippets, file references, and a simulated issue or pull request.

## Ask for code-aware root cause analysis

Use Azure SRE Agent:

```text
Using the Grubify incident evidence and connected source code, identify the most likely source area. Include file and line references only where you have evidence. Create a remediation work item with symptom, evidence, likely cause, alternative hypothesis, and validation plan.
```

If the agent cannot create an issue directly, ask it to draft the issue body and create it manually.

## Remediation work item template

```md
## Customer-safe summary

## Operational evidence
- Alert:
- Logs:
- Trace/exception:
- User-visible symptom:

## Suspected source area
- File/line:
- Why this is a lead:

## Likely cause

## Alternative hypothesis

## Proposed remediation

## Human review gate
```

## Optional pull request review

If the agent or a coding assistant proposes a pull request:

1. Inspect the diff.
2. Confirm it only touches the suspected area.
3. Check tests or validation evidence.
4. Confirm no secrets or tenant details are added.
5. Approve, request changes, or reject the pull request.

**Do not merge a change because its summary sounds confident.**

## Deliverables

- Source-code connection evidence or fallback source packet.
- A root cause analysis note that cites source code.
- GitHub issue, draft issue, or reviewed pull request.
- Human review decision with evidence.
