---
name: plan-command
description: Responds to `/plan` comments by decomposing an issue into bounded subtasks for human review.
triggers:
  - issue_comment.created.command:/plan
permissions:
  contents: read
  issues: write
tools:
  - github.issue.read
  - github.comments.read
  - github.code.search
safe_outputs:
  add-comment:
    max_length: 5000
  create-subissues:
    max_count: 5
    labels:
      - needs:human-review
      - type:task
post_stage:
  writes:
    - add-comment
    - create-subissues
compile_note: Run `gh aw compile` after frontmatter changes when using gh-aw. Do not hand-edit generated `.lock.yml` files.
---

# Plan Command

## Purpose

Turn a `/plan` request on a GitHub issue into a reviewable work breakdown. The agent proposes subtasks, acceptance criteria, risks, and validation commands without starting implementation.

## Peli's Factory Pattern

This is the planning cell agent. It prepares work for humans, cloud coding agents, or later automation by making scope and evidence explicit.

## Trigger

- A new issue comment starts with `/plan`.

Ignore `/plan` text inside code blocks, quoted comments, or issue bodies unless it is the actual triggering comment.

## Minimal Permissions

- `contents: read` to inspect relevant files and conventions.
- `issues: write` to add a plan comment or create bounded subissues.

Do not grant pull request, workflow, deployment, secret, package, or environment write permissions.

## Inputs

- Parent issue title and body.
- Triggering `/plan` comment.
- Existing issue comments.
- Relevant repository file paths.
- Existing linked issues, if any.

## Tools

- Read parent issue and comments.
- Search repository files for relevant context.
- Produce structured safe outputs only.

The agent runtime should not receive repository secrets or provider keys.

## Agent Instructions

You are planning work for a delivery session repository. Keep the plan small enough for review. Do not claim ownership for humans. Do not create implementation details that require private context. If the issue is too vague, ask clarifying questions instead of inventing requirements.

Prefer a plan comment when the work is small. Propose subissues only when the work naturally splits into independent reviewable units.

## Safe Outputs

Return a plan comment:

```yaml
add-comment: |
  ## Proposed Plan

  1. Confirm the affected path and current behavior.
  2. Make the smallest change that satisfies the acceptance criteria.
  3. Add or update tests for the behavior.
  4. Run validation and attach results to the pull request.

  ## Suggested Subtasks
  - [ ] Update the sample app behavior.
  - [ ] Add test coverage.
  - [ ] Update challenge notes if user-facing behavior changes.

  ## Risks
  - Scope may be too broad if deployment behavior is included.

  ## Validation
  - `npm test` from `modules/sre-agent/resources/sample-app`

  Human review required before implementation starts.
```

or create subissues:

```yaml
create-subissues:
  - title: "Plan task: add checkout route test coverage"
    labels:
      - type:task
      - needs:human-review
    body: |
      Parent issue: #123

      ## Goal
      Add test coverage for the checkout route behavior.

      ## Acceptance Criteria
      - Tests describe successful and failure responses.
      - Validation command is documented in the PR.

      ## Validation
      - `npm test` from `modules/sre-agent/resources/sample-app`
```

Rules:

- Create at most five subissues.
- Each subissue must include goal, acceptance criteria, and validation.
- Do not assign users.
- Do not close or relabel the parent issue unless that behavior is separately reviewed and allowed.
- Do not create branches or pull requests.

## Post-Stage Write Job

The post-stage validates markdown length, subissue count, labels, and required sections before writing. If validation fails, it adds no comment and creates a workflow warning.

## Threat Checks

- Prompt injection in issue comments.
- `/plan` commands from unauthorized contexts if the repository requires membership checks.
- Plans that request secrets, policy bypasses, or hidden private data.
- Subtasks that are too broad to review.
- Duplicate subissues.

## Human Review Gate

A human maintainer approves the plan before work is assigned to a cloud coding agent, local agent, or teammate.

## Fallback Without gh-aw

Use this file as a planning worksheet. A participant writes the proposed comment or subissues, then a second participant reviews the plan for scope and validation before it is posted.

## Validation Checklist

- Frontmatter includes `/plan` trigger, permissions, tools, and safe outputs.
- The plan separates investigation, implementation, tests, and docs.
- Subissues are small and independently reviewable.
- Human review is explicit before implementation.
- No secrets or private context are required.
