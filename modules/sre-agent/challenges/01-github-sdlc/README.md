# Challenge 01: Establish the GitHub SDLC

## Scenario

The inherited Contoso Claims service has change requests, but the team cannot reliably answer basic questions: What problem is being solved? Who reviewed it? Which checks ran? What evidence proves it is ready?

Your mission is to create a GitHub-native SDLC baseline that turns a rough work request into a visible issue, branch, pull request, review, and quality gate.

This is also your first agent-ready specification. Write the issue so an assistant could help without needing private context or hidden team assumptions.

## Goals

- Convert an ambiguous request into a clear GitHub issue.
- Create a branch and pull request that connect intent to implementation.
- Add or confirm lightweight repository quality gates.
- Practice human review before merge.
- Make the SDLC evidence easy for a coach or stakeholder to inspect.
- Add explicit scope, boundaries, and validation commands so the work can later be delegated or reviewed safely.

## Estimated Time

60 minutes.

## Tasks

1. Pick a small product improvement from the coach-provided backlog packet.
2. Rewrite the work as a [GitHub issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/creating-an-issue) with user impact, acceptance criteria, and test expectations.
3. Add an agent-ready section with relevant files, constraints, non-goals, validation commands, and human checkpoints. Use [Agent-Ready Issue Template](../../resources/Agent-Ready-Issue-Template.md) if helpful.
4. Create a branch linked to the issue.
5. Make a small, reviewable change. If the sample app is not available yet, use a documentation or configuration improvement that still exercises the workflow.
6. Open a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests) that [links back to the issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue) and explains the change.
7. Ensure at least one check, review, or manual validation result is visible on the pull request.
8. Merge only after the team can explain the evidence.

## Success Criteria

- The issue states the problem, expected outcome, and validation method.
- The issue includes boundaries that reduce scope and prevent unrelated changes.
- The branch and pull request are linked to the issue.
- The pull request has a useful description and visible review activity.
- At least one quality signal exists: test output, lint output, workflow run, checklist, or coach-approved manual validation.
- The team can trace the change from issue to merged result.
- Coach conversation — if you applied this GitHub SDLC baseline to the next real change request your team receives, which step (issue clarity, branch linking, review evidence, or quality gate) would be most likely to slip, and why? Talk it through with your coach and connect it to a real project, task, or workflow you own.

## Hints

- Good issues are small enough for a pull request and specific enough for a reviewer.
- If you would not hand the issue to a new teammate without a meeting, it is not ready for an agent.
- Use pull request templates or checklists if the repo already provides them, and treat [pull request review](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews) as evidence rather than ceremony.
- A failed check is not failure for the challenge. It is useful evidence if the team responds to it well.
- Keep the change narrow. You will build on this workflow in later challenges.

## Coach Validation Checkpoints

- Ask: Where is the intent captured?
- Ask: What would stop this change from merging if it were risky?
- Ask: What context did the issue externalize that used to live only in someone's head?
- Inspect whether the pull request links back to the issue.
- Verify that review comments or checks are meaningful, not just decorative.
- Confirm the team can explain what would happen differently for a larger production change.

## Deliverables

- One GitHub issue with acceptance criteria.
- Agent-ready specification section with scope, boundaries, validation commands, and human checkpoints.
- One branch and pull request linked to the issue.
- Visible review or validation evidence.
- A short team note describing the SDLC rule they want to keep after the hackathon.
