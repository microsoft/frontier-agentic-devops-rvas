# Coach Guide: Activity 05 — Connect Source Code and Create Remediation Work

## Expected Outcome

Teams connect or simulate source-code context and use Azure SRE Agent to turn operational evidence into a remediation issue with evidence, validation, and human approval, or a reviewed pull request.

## Coach Prep

Prepare one of:

- Live GitHub connector for the lab repository.
- A fork or import of the sample repo with issues enabled.
- A fallback source packet with file references and a simulated issue/PR.

For GitHub Enterprise Managed User (EMU) tenants, prefer a coach-provisioned enterprise repository over asking participants to fork public code during the workshop. The current starter lab expects the connected repository to be `<owner>/grubify`, so provide each team with an owner that has a repo named `grubify`, or use the fallback packet/manual portal connection if your enterprise uses team-specific repo names.

Least privilege is preferred. If OAuth or PAT setup becomes the workshop, switch to fallback.

## Strong Evidence

- Source references are tied back to telemetry.
- Issue or PR body includes symptom, evidence, likely cause, alternative, validation, and review gate.
- Participants inspect any proposed diff.
- No secrets or tenant-specific details appear in GitHub artifacts.

## Common Gaps

- Making GitHub the main product again.
- Asking an agent to create a PR before the investigation is grounded.
- Accepting file/line references without checking evidence.
- Publishing internal incident details in a public issue.

## Coach Hints

Ask:

- Is this enough evidence for a PR, or only enough for an issue?
- What should a human reviewer verify?
- What should Azure SRE Agent be allowed to do by default in your real org?

## Final Demo Pattern

Teams should show the source-aware RCA, the remediation issue or reviewed PR, and the human decision.
