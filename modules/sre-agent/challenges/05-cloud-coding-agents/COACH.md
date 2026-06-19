# Coach Guide: Challenge 05 — Use Cloud Coding Agents

### Expected Outcome

Teams write safe GitHub Agentic Workflows style specs, then review a generated or simulated pull request with human discipline.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — if you assigned your next backlog issue to a cloud coding agent today, what specific context would you need to add so it could work without asking you a single question, and which review step would you be least comfortable skipping? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to pick an actual open issue from their real backlog and walk through what is missing from it for autonomous execution — files, constraints, validation commands, non-goals.
- Ask what the worst realistic diff looks like if the agent misunderstands the scope: which files could it touch, what tests could it delete, and would their current PR review catch it?
- Ask them to define one concrete improvement to their next real issue template or review checklist that would make agent-assisted work safer by next week.

### Strong Evidence

- Issue has context, constraints, acceptance criteria, and validation commands.
- Workflow specs exist for issue triage, CI Doctor, and plan command, or at least two of the three.
- Workflow specs include triggers, inputs, [scoped permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication), denied actions, safe outputs, and human checkpoints.
- Pull request diff is inspected carefully.
- Review feedback is specific.
- Team decides merge, request changes, or reject based on evidence.

### Common Gaps

- Issue is too vague for asynchronous execution.
- Team trusts the pull request summary without doing a normal [pull request review](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews).
- Tests are missing or removed.
- Participants overgeneralize from a simulated artifact to a product guarantee.
- Workflow specs allow broad writes, expose secrets, or treat untrusted issue comments/logs as instructions.

### Coach Hint

Ask: Would you assign this issue to a new teammate without a meeting? If not, it is probably not agent-ready.
Ask: Would you let this workflow run on an untrusted issue comment? If not, what boundary is missing?
