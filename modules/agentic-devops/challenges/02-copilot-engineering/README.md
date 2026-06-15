# Challenge 02: Build with GitHub Copilot

## Scenario

Now that the team has a basic SDLC path, the product owner asks for a small behavior improvement in Contoso Claims. The code is unfamiliar. You need to understand the relevant files, propose a focused change, add validation, and prepare it for review.

Copilot can help, but the team remains accountable for correctness, security, test evidence, and merge decisions.

Use this challenge to practice PROSE: Progressive Disclosure, Reduced Scope, Orchestrated Composition, Safety Boundaries, and Explicit Hierarchy. The goal is not a perfect prompt. The goal is to make your intent and constraints easier for Copilot and reviewers to follow.

## Goals

- Use Copilot Chat or agentic coding features to understand unfamiliar code.
- Prompt with repository context, acceptance criteria, and constraints.
- Apply PROSE when asking Copilot for comprehension, planning, implementation, tests, and review.
- Implement a focused product or quality improvement.
- Generate or improve tests with human review.
- Document how the team validated AI-assisted output.
- Externalize one repository convention or domain rule discovered during review.

## Estimated Time

60 minutes.

## Tasks

1. Choose a work item that builds naturally on Challenge 01.
2. Ask Copilot to explain the relevant code path or files before making changes.
3. Use progressive disclosure: first ask for comprehension, then a short plan, then focused edits. Do not paste the entire repo or all prior chat.
4. Use reduced scope and explicit hierarchy: restate the issue, non-goals, relevant files, and which instruction wins if guidance conflicts.
5. Implement the change in a branch and keep commits small.
6. Ask Copilot for test ideas, edge cases, and review risks.
7. Add or update tests, scripts, or manual validation steps.
8. During review, identify one convention Copilot needed but the repo did not state. Add it to your starter context artifact, issue, pull request template, or decision note.
9. Open or update the pull request with a section that describes AI assistance and human validation.

## Success Criteria

- The team can point to the prompt context used to guide Copilot.
- Prompts show PROSE discipline: scoped context, clear hierarchy, safety boundaries, and staged composition.
- The resulting change maps to the issue acceptance criteria.
- Tests or validation steps cover the intended behavior and at least one edge case.
- The pull request makes clear what Copilot helped with and what humans verified.
- Reviewers can understand the change without trusting AI output blindly.
- One convention or domain rule has been externalized for future agent use.

## Hints

- Start with comprehension prompts before implementation prompts.
- Ask Copilot to produce options, then choose one. Do not let the first answer become the design by default.
- Ask for negative tests or failure modes, not only happy-path tests.
- If Copilot suggests broad refactoring, narrow the change back to the issue.
- If Copilot ignores an instruction, debug the instruction path: did the artifact resolve, materialize, bind, and activate?
- Save useful prompts in the pull request or team notes if they improved the outcome.

## Coach Validation Checkpoints

- Ask the team to show one prompt that improved their understanding.
- Ask which PROSE constraint improved the prompt most.
- Ask what Copilot got wrong, omitted, or over-assumed.
- Check that a discovered convention was written somewhere durable.
- Check that the validation evidence was run or reviewed by a human.
- Inspect whether the pull request is still small enough to review well.
- Confirm the team can name a policy or guardrail they would use in their real environment.

## Deliverables

- Pull request with Copilot-assisted implementation or test improvement.
- Validation evidence: passing tests, check output, or documented manual verification.
- Pull request note describing AI assistance and human accountability.
- Updated context, convention, or decision note capturing one lesson Copilot needed.
