# Activity 05: Connect Source Code and Create Remediation Work

## Scenario

Azure evidence can explain what failed. Source-code context helps explain where the failure may live and how engineering work should be tracked. In this activity, connect or simulate source-code context so Azure SRE Agent can move from operational investigation to remediation work with evidence, validation, and human approval.

## Goals

- Connect a GitHub repository to Azure SRE Agent when available.
- Ask the agent to correlate symptoms with source-code areas.
- Create a GitHub issue or remediation summary with evidence.
- Optionally review an agent-proposed pull request.
- Keep human review visible before any change is treated as production-ready.

## Estimated Time

60 minutes.

> [!IMPORTANT]
> Bring your own service (do this first)
>
> This activity is most valuable when Azure SRE Agent connects operational evidence to the source repository your team will keep using after the session. If you have a candidate Azure workload in a subscription you control, use that service everywhere this guide references Grubify, and connect its own source repo so remediation work lands in the right engineering workflow.
>
> - Have a candidate? Use a real or recent incident for your service and the repository that owns the suspected code path. Ask the agent to create or draft remediation work against your normal issue or pull request process, with evidence, uncertainty, validation, and human review gates.
> - No suitable Azure service, incident, or source repo yet? Connect the Grubify repository or use the fallback source packet below as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; Grubify is the fallback.

## Connect Source Code

If your live lab supports GitHub connection, use a lab-safe GitHub repository approved by your coach. In GitHub Enterprise Managed User (EMU) environments, do not assume participants can fork public repositories into personal accounts. Your coach may provide an enterprise-owned repository instead.

The current starter lab expects the connected repository to be named `grubify` and uses the value of `GITHUB_USER` as the repository owner. Use one of these paths:

| Environment | What to use |
| --- | --- |
| Personal GitHub account allowed | Fork `https://github.com/dm-chelupati/grubify` to `<your-user>/grubify`. |
| EMU or enterprise-managed account | Use the coach-provided enterprise owner that contains `<owner>/grubify`. |
| GitHub blocked or repo name differs | Use the fallback source packet, or connect the repository manually in the Azure SRE Agent portal if your coach supports it. |

Enable Issues on the lab repository before connecting it. The source-code and issue-triage scenarios need issue read/write access.

From the starter lab directory, set the repository owner and rerun post-provision setup:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
azd env set GITHUB_USER <repo-owner>
bash scripts/post-provision.sh --retry
```

For example, if your coach provides `https://github.com/contoso-team-01/grubify`, run:

```bash
azd env set GITHUB_USER contoso-team-01
bash scripts/post-provision.sh --retry
```

When the OAuth URL appears, open it in a browser and authorize with the GitHub account that has access to the lab repository. Do not paste GitHub tokens into chat or notes.

You may also connect GitHub through the Azure SRE Agent portal. Use the least privilege option your coach approves.

If GitHub connection is blocked, use the fallback packet with source snippets, file references, and a simulated issue or pull request.

## Ask for Code-Aware RCA

Use Azure SRE Agent:

```text
Using the Grubify incident evidence and connected source code, identify the most likely source area. Include file and line references only where you have evidence. Create a remediation work item with symptom, evidence, likely cause, alternative hypothesis, and validation plan.
```

If the agent cannot create an issue directly, ask it to draft the issue body and create it manually.

## Remediation Work Item Template

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

## Validation plan

## Human review gate
```

## Optional Pull Request Review

If the agent or a coding assistant proposes a pull request:

1. Inspect the diff.
2. Confirm it only touches the suspected area.
3. Check tests or validation evidence.
4. Confirm no secrets or tenant details are added.
5. Decide: approve, request changes, or reject.

Do not merge because the summary sounds confident.

## Deliverables

- Source-code connection evidence or fallback source packet.
- Code-aware RCA note.
- GitHub issue, draft issue, or reviewed pull request.
- Human review decision with evidence.

## Success Criteria

- Source context is used to refine the investigation, not replace telemetry.
- File, line, commit, issue, or PR references are treated as leads until validated.
- Remediation work includes evidence, uncertainty, and validation.
- Human review is required before a fix is accepted.
