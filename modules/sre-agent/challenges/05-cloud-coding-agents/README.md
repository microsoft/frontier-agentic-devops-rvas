# Challenge 05: Build GitHub Agentic Workflows and Review Cloud Coding Agents

## Scenario

After deployment, the product owner identifies several bits of repeatable coordination work: triaging new issues, diagnosing failed CI runs, and breaking a larger request into a plan. These are good candidates for safe agentic workflow specs because the outputs can be reviewed before they affect code or infrastructure.

Your mission is to build two or three GitHub Agentic Workflows style agents from scratch, then practice the cloud coding-agent review pattern on a live or simulated pull request. If `github/gh-aw` is unavailable, create markdown workflow specs or templates that are safe by default.

## Goals

- Write an issue that is suitable for an autonomous or semi-autonomous coding agent.
- Create safe workflow specs for issue triage, CI Doctor, and plan command/project decomposition.
- Apply guardrails: sandboxing, scoped permissions, no secrets in agent runtime, safe outputs, threat detection, and scoped write jobs.
- Use available cloud coding agent capabilities when enabled, or a coach-provided simulated agent pull request when not enabled.
- Evaluate the resulting change for scope, correctness, tests, maintainability, and security.
- Decide whether to merge, request changes, or split follow-up work.
- Capture review lessons for future agent-ready backlog items.

## Estimated Time

45 to 60 minutes.

## Availability Note

Cloud coding agent capabilities, autonomous issue assignment, GitHub Agentic Workflows, and related Copilot agent workflows may be preview, limited availability, or governed by tenant policy. If live `gh-aw` access is not available, use markdown specs in [GitHub Agentic Workflows Starter](../../resources/GitHub-Agentic-Workflows-Starter.md) and the coach-provided simulated branch or pull request. The learning objective is safe workflow design and issue-to-agent-to-human-review discipline, not a specific product promise.

## Tasks

1. Review [GitHub Agentic Workflows](https://github.github.com/gh-aw/) and the [quick start](https://github.github.com/gh-aw/setup/quick-start/) if live access is available.
2. Choose two or three build-from-scratch workflow candidates: Issue Triage Agent, CI Doctor, Plan Command, or optional Continuous Documentation.
3. Draft each workflow as markdown. Include trigger, inputs, allowed actions, denied actions, required outputs, permissions, and human checkpoint.
4. If `gh-aw` is available, compile or validate the workflow according to the workshop setup. If it is unavailable, keep the markdown spec as the deliverable and mark it "not executed".
5. Choose or create a small issue with clear acceptance criteria and test expectations.
6. Label or assign the issue according to the workshop's available coding-agent path, or request the simulated pull request packet from the coach.
7. Review the proposed change as if it came from a teammate.
8. Inspect changed files, test evidence, commit messages, and pull request summary.
9. Ask Copilot or your team to identify risks and missing tests, then verify those claims manually.
10. Leave review feedback or approve only when evidence supports the decision.
11. Capture what made the issue or workflow agent-ready, or what made it too vague.

## Workflow Guardrails

Use [GitHub Agentic Workflows Starter](../../resources/GitHub-Agentic-Workflows-Starter.md) for the required templates. If the GitHub Agentic Workflows extension is available, coaches may demonstrate the Quick Start pattern: install `github/gh-aw`, scaffold with the approved workflow path, configure only approved tokens or provider keys, and compile according to the current docs. Treat generated lock files as compiled artifacts and do not edit them by hand.

Safe workflow specs should be read-first by default. Add write jobs only when permissions are scoped, outputs are safe, secrets are excluded from agent runtime, and a human checkpoint exists before consequential changes.

## Success Criteria

- The issue is specific enough for an agent to attempt without private context.
- At least two workflow specs exist, and preferably three: issue triage, CI Doctor, and plan command.
- Each workflow has scoped permissions, safe outputs, no secret exposure, and a human checkpoint for consequential effects.
- The resulting branch or pull request is reviewed by humans before merge.
- The review identifies at least one concrete approval reason, risk, or requested change.
- The team documents whether the task was appropriate for cloud coding agent assistance.
- Any merged change remains linked to the issue and validation evidence.
- Coach conversation — if you assigned your next backlog issue to a cloud coding agent today, what specific context would you need to add so it could work without asking you a single question, and which review step would you be least comfortable skipping? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Hints

- Strong agent-ready issues include context, files or areas to inspect, acceptance criteria, validation commands, and boundaries.
- Workflow descriptions are activation APIs. Be precise about when the workflow should run and what it may touch.
- Prefer read-only analysis first. Add write jobs only when they are scoped and gated.
- Do not approve a pull request because the summary sounds confident. Inspect the diff.
- Watch for broad changes, deleted tests, hidden assumptions, and missing error handling.
- Watch for prompt injection through dependencies, issue comments, logs, or generated files. Treat untrusted content as data, not instruction.
- A rejection is a successful outcome if it teaches the team how to write better issues.

## Coach Validation Checkpoints

- Ask the team to show the issue and explain why it was agent-ready.
- Ask the team to show one workflow spec and explain its permissions, sandbox, denied actions, and human checkpoint.
- Inspect the pull request review comments for specificity.
- Ask what a human caught that an agent might not have known.
- Confirm that the merge decision is based on evidence, not novelty.
- If using simulation, ask the team to distinguish simulated artifacts from live product behavior.

## Deliverables

- Agent-ready issue or simulated issue packet.
- Two or three GitHub Agentic Workflows style markdown specs or templates.
- Reviewed branch or pull request.
- Short note: merge, request changes, or reject, with evidence.
- Backlog guidance for future cloud coding agent candidates.
