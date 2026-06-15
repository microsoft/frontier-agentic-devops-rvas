# Agentic Workflow Review Rubric

Use this rubric to review Peli's Factory / GitHub Agentic Workflows-inspired specs before compiling them with `gh aw compile`, simulating them in a workshop, or enabling them in a repository.

Score each area from 0 to 2.

| Score | Meaning |
| --- | --- |
| 0 | Missing or unsafe. |
| 1 | Present but incomplete, broad, or unclear. |
| 2 | Clear, scoped, and reviewable. |

## Safety Rubric

| Area | 0 | 1 | 2 |
| --- | --- | --- | --- |
| Trigger scope | Broad or ambiguous trigger. | Trigger is named but lacks event detail. | Trigger is specific and tied to the workflow purpose. |
| Permissions | Broad write permissions or unspecified permissions. | Some permissions are scoped, but extras remain. | Minimal permissions with read-first design and narrow write scope. |
| Secret handling | Secrets exposed to agent runtime or referenced in prompts. | Secrets are mentioned but boundaries are unclear. | No secrets in agent runtime; secrets are limited to trusted setup or provider configuration. |
| Tool scope | Tools can modify unrelated repository state. | Tools are named but not constrained. | Tools match the task and separate investigation from writes. |
| Safe outputs | Free-form output controls writes directly. | Output shape exists but lacks limits. | Structured outputs include schema, allowlists, counts, and length limits. |
| Post-stage validation | Agent writes directly to GitHub. | Validation is described but not enforceable. | A scoped write job validates safe output before posting. |
| Prompt injection defense | Untrusted issue/log/comment text is trusted. | Warnings exist but are generic. | Threat checks name the untrusted surfaces and rejected behaviors. |
| Human review gate | Agent makes final merge or routing decisions. | Human review is implied. | Human ownership is explicit before implementation, merge, or policy change. |

## PROSE Review Rubric

PROSE keeps the workflow understandable for humans before it becomes automation.

| Letter | Question | Strong Evidence |
| --- | --- | --- |
| P - Purpose | What job does the agent do? | The purpose names one bounded outcome. |
| R - Risk | What can go wrong? | The spec lists prompt injection, secret exposure, overbroad writes, and duplicate/noisy output risks where relevant. |
| O - Outputs | What may the agent produce? | The safe output schema is concrete enough to validate without reading the prompt. |
| S - Scope | What is out of bounds? | The spec names actions the agent must not take. |
| E - Evidence | How will humans verify the result? | The workflow preserves issue links, logs, rationale, validation commands, or review checkpoints. |

## Review Questions

- Can this workflow be reviewed as a markdown spec before it runs?
- Would the workflow still be useful as a manual checklist if `gh-aw` is unavailable?
- Does the generated `.lock.yml` remain treated as a compiled artifact that humans do not hand-edit?
- Are all write actions traceable to a safe output field?
- Is there a clear failure mode when validation rejects output?
- Could a malicious issue, comment, or log line trick the agent into doing something outside scope?
- Does the workflow strengthen human review instead of replacing it?

## Minimum Passing Bar

A workflow is ready for a workshop simulation when:

- Every safety area scores at least 1.
- Trigger scope, permissions, safe outputs, and human review gate score 2.
- The PROSE review has a written answer for all five letters.
- A teammate can explain the fallback path without installing `gh-aw`.

A workflow is ready for live repository experimentation only when every safety area scores 2 and maintainers have reviewed the generated lock file diff after `gh aw compile`.
