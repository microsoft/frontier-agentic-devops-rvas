# Build Agentic Workflows

This folder is the local home for Peli's Factory and GitHub Agentic Workflows assets used in Challenge 05, with supporting patterns that also reinforce Challenge 03 orchestration. These assets give coaches and students a practical way to design GitHub Agentic Workflows-inspired automation from scratch. They are safe by default and useful even when the `gh aw` extension is unavailable, blocked by policy, or not yet installed in the delivery environment.

The templates are written as markdown workflow specifications. Teams can review them as design artifacts, adapt them into live GitHub Agentic Workflows with the `gh-aw` Quick Start path, or use them as fallback specs for simulated agent behavior during a workshop.

## How This Maps To Peli's Factory

Peli's Agent Factory pattern encourages small, named agents with clear jobs, constrained tools, visible handoffs, and human review gates. These templates apply that pattern to Peli's Factory challenge work:

| Agent | Factory Pattern | What It Practices |
| --- | --- | --- |
| [Issue Triage Agent](issue-triage-agent.md) | Intake line | Reads a new issue, applies only allowed labels, and leaves a rationale comment for humans. |
| [CI Doctor](ci-doctor.md) | Diagnostic bench | Investigates failed CI evidence, summarizes likely causes, and opens a diagnostic issue or proposed next step. |
| [Plan Command](plan-command.md) | Planning cell | Responds to `/plan` by decomposing a work item into safe, reviewable subtasks. |

Each agent keeps the same operating model: minimal permissions, read-only investigation first, structured safe outputs, and a narrow post-stage that performs repository writes after validation.

## GitHub Agentic Workflows Quick Start Mapping

When `gh-aw` is available, the expected quick start flow is:

1. Install the extension with `gh extension install github/gh-aw`.
2. Add or scaffold workflows with `gh aw add-wizard`.
3. Configure repository or environment secrets such as `COPILOT_GITHUB_TOKEN` or provider-specific API keys only where the workflow requires them.
4. Edit the markdown workflow frontmatter and body.
5. Run `gh aw compile` after frontmatter changes.
6. Commit both the markdown spec and generated lock file, but do not edit the generated `.lock.yml` by hand.

These workshop specs intentionally do not require that flow. Participants can still review the design, validate required sections locally, and simulate the resulting GitHub issue or comment changes.

## Safe-By-Default Design Rules

- Start with read-only context collection.
- Grant the narrowest permissions needed for the post-stage write.
- Do not expose repository secrets to the agent runtime.
- Treat labels, comments, and created issues as safe outputs that must pass schema checks.
- Keep write behavior deterministic and scoped.
- Include threat checks for prompt injection, malicious issue content, untrusted log output, and unsafe file references.
- Require human review before merging code changes or changing release gates.

## Workshop Use

Use these assets in Challenge 03 when teams design agent coordination patterns, and in Challenge 05 when teams compare cloud coding agents with repository automation agents.

Suggested flow:

1. Pick one template and identify the trigger, permissions, tools, and safe outputs.
2. Review the template with the [agentic workflow review rubric](agentic-workflow-review-rubric.md).
3. Run `bash modules/sre-agent/resources/scripts/validate-agentic-workflow-specs.sh` from the repository root.
4. If `gh-aw` is available, adapt the spec through `gh aw add-wizard` and compile it.
5. If `gh-aw` is unavailable, simulate the safe outputs in an issue thread and have humans review the result.

## References

- Peli's Agent Factory: use as the workshop mental model for small agents, controlled tools, explicit handoffs, and review gates.
- GitHub Agentic Workflows Quick Start: install `github/gh-aw`, create workflows with `gh aw add-wizard`, and compile lock files with `gh aw compile`.

## Related Resources

- [Agentic SDLC Practices](../Agentic-SDLC-Practices.md)
- [Agent-Ready Issue Template](../Agent-Ready-Issue-Template.md)
- [Reference Architecture](../Reference-Architecture.md)
