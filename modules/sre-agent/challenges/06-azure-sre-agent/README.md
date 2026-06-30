# Challenge 06: Respond with Azure SRE Agent

## Scenario

Your team deployed Contoso Claims to Azure and captured both healthy and degraded evidence. Now investigate the degraded checkout signal, connect it to source context, and drive remediation back through GitHub.

## Goals

- Start from incident evidence, not a guessed fix.
- Build a To-Do style investigation plan.
- Correlate deployment evidence, runtime symptoms, and source files.
- Create a reviewed GitHub remediation path.
- Identify which repo instrumentation helped or was missing.

## Estimated Time

60 minutes.

## Choose Your Evidence Path

| Path | Use when | Starting point |
| --- | --- | --- |
| Live Azure SRE Agent | Your coach confirms access | Healthy and degraded Azure evidence from Challenge 04 |
| Azure without SRE Agent | The app is deployed but SRE Agent is unavailable | Azure endpoint, Actions logs, generated evidence notes |
| Local simulation | Azure access is blocked | Local incident packet and generated local evidence |

For local simulation, run one of:

```bash
modules/sre-agent/resources/scripts/simulate-checkout-incident.sh checkout_error
modules/sre-agent/resources/scripts/simulate-checkout-incident.sh checkout_latency
```

The script writes evidence under `modules/sre-agent/resources/runbooks/generated/`.

## Run

1. Open your Challenge 04 deployment notes.
2. Open the incident packet: `modules/sre-agent/resources/runbooks/challenge-06-incident-packet.md`.
3. Open the triage template: `modules/sre-agent/resources/runbooks/challenge-06-triage-template.md`.
4. Gather:
   - Healthy deployment evidence.
   - Degraded deployment or local simulation evidence.
   - GitHub Actions run URL.
   - Commit SHA.
   - Changed files or pull request link.
   - Any Azure logs, metrics, or SRE Agent output available.

## Investigate

Create a To-Do plan before proposing a fix:

```md
- [ ] Confirm affected endpoint and status code.
- [ ] Compare incident start time with deployment time.
- [ ] Compare healthy and degraded evidence.
- [ ] Inspect recent changes touching checkout, health, workflow, or environment variables.
- [ ] Identify likely cause and at least one alternative.
- [ ] Define validation needed before recovery is accepted.
```

If Azure SRE Agent is available, ask it to produce or refine this plan using source-code context. Treat file and line references as leads; validate them against the evidence.

## Build the Evidence Chain

Fill this table in your triage note:

| Evidence | What it shows | Link or file |
| --- | --- | --- |
| Healthy deployment | Baseline endpoint behavior | `<run/evidence>` |
| Degraded deployment | Failure mode and timestamp | `<run/evidence>` |
| Source context | Candidate file, line, commit, or PR | `<file/link>` |
| Validation | Test, health check, or log proving recovery | `<command/link>` |

## Remediate Through GitHub

Create a GitHub issue or pull request that includes:

- Customer-safe incident summary.
- Evidence links.
- Likely cause and confidence.
- Alternative hypothesis.
- Proposed remediation owner.
- Validation plan.
- Human review gate.

If an agent proposes a pull request, review it like a teammate's work. Do not merge because the summary sounds confident.

## Recover

Return the service to healthy mode:

- For Azure: run the deployment workflow again with `incident_mode` set to `healthy`.
- For local simulation: rerun the sample app without `INCIDENT_MODE`.

Capture recovery evidence:

```bash
curl --fail-with-body https://<your-container-app-fqdn>/healthz
curl --fail-with-body https://<your-container-app-fqdn>/api/checkout
```

or, for local:

```bash
cd modules/sre-agent/resources/sample-app
npm start
```

Then call `/healthz` and `/api/checkout` on the local port.

## Success Criteria

- Investigation starts from healthy and degraded evidence.
- To-Do plan separates completed checks from open questions.
- Likely cause references source, deployment, logs, or agent output only where evidence supports it.
- Remediation returns to GitHub as an issue or reviewed pull request.
- A human review decision is required before the fix is production-ready.
- Recovery evidence shows the service back in healthy mode.
- The team identifies one instrumentation artifact that helped, or one missing artifact to add.
- Coach conversation — in your last real incident, how long did it take to connect a production symptom to a specific commit or file, and which instrumentation artifact was missing or hardest to find?

## Deliverables

- Incident investigation note with evidence, timeline, hypotheses, and next actions.
- GitHub issue or reviewed pull request for remediation.
- Customer-safe incident summary.
- Recovery evidence.
- Instrumentation improvement note for repo instructions, prompts, workflow specs, alerts, or deployment records.
