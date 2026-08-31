# Agent-Ready Issue Template

Use this template for cloud coding agent issues and simulated agent workflows.

Put enough context in the issue for an assistant to work without private chat. Keep the work small and easy to review.

## Title

`<Verb + small outcome + affected area>`

## Problem

Describe the user or operator problem in two to four sentences and explain why it matters.

## Context

- Relevant files or areas to inspect:
  - `<path or component>`
- Current behavior:
  - `<what happens now>`
- Desired behavior:
  - `<what should happen>`
- Constraints:
  - `<what should not change>`

## Acceptance Criteria

- [ ] `<observable outcome>`
- [ ] `<test or validation expectation>`
- [ ] `<documentation or review expectation if needed>`

## Validation Commands

```bash
<test command or manual validation step>
```

## Boundaries

The agent should not:

- Change unrelated files.
- Remove or weaken tests.
- Introduce new dependencies without explaining why.
- Modify secrets, credentials, or deployment targets.

## Human Checkpoints

- Architecture decision owner: `<person or role>`
- Review owner: `<person or role>`
- Escalation path if the agent output is risky: `<person or role>`
- Merge gate: `<test, approval, or manual validation required>`

## PROSE Constraints Check

- Progressive Disclosure: `<what context is provided now, and what is deferred>`
- Reduced Scope: `<what is intentionally out of scope>`
- Orchestrated Composition: `<whether this is one agent, writer/reviewer/tester, or another pattern>`
- Safety Boundaries: `<denied actions and protected areas>`
- Explicit Hierarchy: `<which instruction wins if guidance conflicts>`

## Review Focus

Review:

- Scope control.
- Correctness against acceptance criteria.
- Tests and edge cases.
- Security or reliability impact.
- Whether the change is understandable for future maintainers.
