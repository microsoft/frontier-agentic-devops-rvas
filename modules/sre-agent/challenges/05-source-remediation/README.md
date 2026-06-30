# Challenge 05: Connect Source Code and Create Remediation Work

## Scenario

Azure evidence can explain what failed. Source-code context helps explain where the failure may live and how engineering work should be tracked. In this challenge, connect or simulate source-code context so Azure SRE Agent can move from operational investigation to governed remediation.

## Goals

- Connect a GitHub repository to Azure SRE Agent when available.
- Ask the agent to correlate symptoms with source-code areas.
- Create a GitHub issue or remediation summary with evidence.
- Optionally review an agent-proposed pull request.
- Keep human review visible before any change is treated as production-ready.

## Estimated Time

60 minutes.

## Connect Source Code

If your live lab supports GitHub connection, follow the starter lab's GitHub setup:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
bash scripts/setup-github.sh
```

You may also connect GitHub through the Azure SRE Agent portal. Use the least privilege option your coach approves. For the lab, a fork of the sample repository is preferred.

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
