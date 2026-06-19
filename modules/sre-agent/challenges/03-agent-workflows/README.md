# Challenge 03: Coordinate Agent Workflows

## Scenario

The team is moving faster, but coordination is getting harder. Issues, pull requests, review comments, generated suggestions, and deployment tasks are spread across tools and conversations.

Your mission is to introduce an agentic workflow pattern that keeps intent, ownership, and evidence visible while AI assistance helps move work forward. Before asking agents for more autonomy, instrument the repo with a small starter set of primitives.

## Goals

- Break a larger request into reviewable work items.
- Route work between humans, Copilot, and agent-assisted tasks without losing ownership.
- Capture decisions and follow-ups where the team can find them.
- Create starter instructions, one agent persona, one reusable skill or prompt, and one memory or decision note.
- Practice review feedback loops with clear handoffs.
- Decide which tasks are appropriate for agent assistance and which require direct human ownership.
- Use Resolve, Materialize, Bind, Activate to debug context artifacts that do not load or influence the agent.

## Estimated Time

45 minutes.

## Tasks

1. Select a request that is too large for one pull request.
2. Decompose it into issues or checklist items with owners and validation expectations.
3. Create or update starter instrumentation using [Agentic SDLC Starter Kit](../../resources/Agentic-SDLC-Starter-Kit.md): instructions, one agent persona, one reusable prompt or skill, and one memory or decision note.
4. Use Copilot or an agent workflow to draft a plan, summarize a pull request, or respond to [review feedback](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews).
5. Assign a human owner for each decision and merge gate.
6. Update the pull request or issue thread with what changed because of review feedback.
7. If an instruction, persona, prompt, or memory note seems ignored, debug it with Resolve, Materialize, Bind, Activate.
8. Create a short handoff note for the next challenge: what is ready to deploy, what is risky, what still needs evidence, and which gates must remain human-owned.

## Success Criteria

- Work is decomposed into small, visible units.
- Each unit has an owner, acceptance criteria, and validation expectation.
- Starter repo instrumentation exists as versioned or issue-linked artifacts.
- Agent-assisted output is attached to the workflow where reviewers can inspect it.
- Review feedback produces an observable change, clarification, or follow-up issue.
- The team can explain which parts were delegated to AI assistance and which remained human decisions.
- The team can explain how primitives are loaded and how they would troubleshoot a missing instruction.
- Coach conversation — looking at your team's current backlog, which coordination task (triage, planning, or review summarization) would you trust a workflow agent to attempt first, and what human checkpoint would you need before any output could affect code or infrastructure? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Hints

- Agents are most useful when the issue is specific, scoped, and has clear acceptance criteria.
- Preserve context in GitHub artifacts such as [issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues) and pull requests instead of private chat whenever possible.
- Ask for summaries after work has happened, but verify those summaries against files and checks.
- Markdown that steers agents is code. Keep it small, reviewed, and specific; if you turn it into a workflow, validate it against [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions).
- One agent is enough for small work. Use writer/reviewer/tester or audit/execute/validate patterns only when the work needs separation.
- If the workflow feels too heavy, remove ceremony before removing review evidence.

## Coach Validation Checkpoints

- Ask: Who owns the next decision if the agent output is questionable?
- Ask: Where would a new teammate find the current state without asking the room?
- Ask: Which instruction, persona, skill or prompt, and decision note did the team create?
- Inspect issue decomposition and pull request updates.
- Confirm that review feedback changed the work or created an explicit decision.
- Check that the handoff note is specific enough to support deployment planning.
- Ask the team to run one load-lifecycle debug: Resolve, Materialize, Bind, Activate.

## Deliverables

- Decomposed issue set or pull request checklist.
- Starter instrumentation set: instructions, agent persona, reusable prompt or skill, and memory/decision note.
- Visible agent-assisted summary, plan, or review-response artifact.
- Handoff note for deployment readiness.
