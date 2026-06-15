# Coach Guide: Challenge 05 — Use Cloud Coding Agents

### Expected Outcome

Teams write safe GitHub Agentic Workflows style specs, then review a generated or simulated pull request with human discipline.

### Strong Evidence

- Issue has context, constraints, acceptance criteria, and validation commands.
- Workflow specs exist for issue triage, CI Doctor, and plan command, or at least two of the three.
- Workflow specs include triggers, inputs, scoped permissions, denied actions, safe outputs, and human checkpoints.
- Pull request diff is inspected carefully.
- Review feedback is specific.
- Team decides merge, request changes, or reject based on evidence.

### Common Gaps

- Issue is too vague for asynchronous execution.
- Team trusts the pull request summary without reading the diff.
- Tests are missing or removed.
- Participants overgeneralize from a simulated artifact to a product guarantee.
- Workflow specs allow broad writes, expose secrets, or treat untrusted issue comments/logs as instructions.

### Coach Hint

Ask: Would you assign this issue to a new teammate without a meeting? If not, it is probably not agent-ready.
Ask: Would you let this workflow run on an untrusted issue comment? If not, what boundary is missing?
