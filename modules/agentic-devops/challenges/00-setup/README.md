# Challenge 00: Setup and Team Launch

## Scenario

Your product team has inherited a customer-facing service called Contoso Claims. The service works, but the engineering system around it is uneven: backlog items are vague, pull requests are inconsistent, automation is incomplete, and operational evidence is scattered.

Today your team will modernize how this service moves from idea to production signal. You will use GitHub as the system of record, GitHub Copilot and agent workflows as engineering accelerators, Azure as the deployment target, and Azure SRE Agent practices to close the loop from incident evidence back to a reviewed fix.

The first lesson is simple: do not ask agents to infer your team's operating model from scattered chat. Before autonomy increases, make enough team knowledge explicit that a new teammate or agent can find it in the repo.

## Goals

- Confirm access to the workshop repository and development environment.
- Understand the inherited service story and the one-day challenge arc.
- Establish team roles, working agreements, and a visible GitHub workspace.
- Choose human accountability roles: architect, reviewer, escalation handler, and operator.
- Start the repo instrumentation set with a context artifact for rules, decisions, and safety boundaries.
- Run a basic local or Codespaces preflight so coaches can identify blockers early.
- Record setup exceptions before the core challenges begin.

## Estimated Time

30 minutes.

## Prerequisites

- GitHub account with access to the workshop repository.
- GitHub Copilot access where approved by the customer environment.
- Codespaces, dev container, or local development environment approved for the event.
- Access to GitHub Issues, Pull Requests, Actions, and repository settings needed by the workshop.
- Azure access or a coach-provided deployment fallback for later challenges.

## Tasks

1. Join your team workspace and confirm everyone can open the repository.
2. Choose a working environment: Codespaces is preferred, but local setup is acceptable if the coach has validated it.
3. Review the service README, known issues, and sample backlog packet provided by the coach.
4. Create or identify your team board, issue list, or project view for the day.
5. Create a short team context note using [Agentic SDLC Starter Kit](../../resources/Agentic-SDLC-Starter-Kit.md). Include human roles, merge authority, safety boundaries, and where decisions will be recorded.
6. Run the preflight command or baseline check provided in the repository.
7. Capture setup risks as GitHub issues or coach notes rather than holding them in chat.

## Success Criteria

- Every participant can read the repository and participate in GitHub issues or pull requests.
- At least one team member can run the service or baseline checks.
- The team has a shared understanding of the service scenario and one-day arc.
- The team can identify who is architect, reviewer, escalation handler, and operator for the day.
- A starter context note exists in a durable location such as an issue, pull request, project note, or repo file.
- Access gaps are documented with an agreed fallback path.
- The team can explain which parts of the day are hands-on and which may become coach-led simulation if access is blocked.

## Hints

- If Copilot is not enabled for everyone, pair participants so each team still practices prompt-review-validation loops.
- If Azure access is not ready, keep moving. Coaches can provide deployment logs, incident packets, and SRE response artifacts later.
- Do not spend the entire morning perfecting local setup. The goal is enough access to learn the workflow.
- Use issues to capture blockers. If a setup problem is real, it is part of the operational story.
- Keep the starter context small. Progressive disclosure beats one giant instruction file.
- Treat setup governance as a working draft. You will improve it as agents reveal missing assumptions.

## Coach Validation Checkpoints

- Ask each team to show the repository open in their chosen environment.
- Confirm at least one successful baseline run, test run, or documented fallback per team.
- Check that each team has a visible place for issues and decisions.
- Ask who owns architecture, review, escalation, and operations decisions.
- Inspect whether the starter context states at least one safety boundary and one review rule.
- Decide whether any team needs a coach-provided baseline branch before Challenge 01.

## Deliverables

- Team working agreement or short note in the repository issue/project area.
- Starter context artifact with roles, boundaries, and decision location.
- Setup blocker issue for each unresolved access problem.
- Confirmed environment path: Codespaces, dev container, local, or coach fallback.
