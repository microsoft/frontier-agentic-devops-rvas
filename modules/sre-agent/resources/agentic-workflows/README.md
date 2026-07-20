# Build Agentic Workflows

This folder is the local home for Peli's Factory and GitHub Agentic Workflows assets. They are optional coach and workshop-reference material for Activity 03 context and role discussions and Activity 05 remediation handoffs; neither activity requires participants to deploy them. These assets give coaches and customer delivery team members a practical way to design GitHub Agentic Workflows-inspired automation from scratch. They are safety-oriented and useful even when the `gh aw` extension is unavailable, blocked by policy, or not yet installed in the delivery environment.

The templates are Markdown workflow specifications. Teams can review them as design artifacts, adapt them into live GitHub Agentic Workflows with the `gh-aw` Quick Start path, or use them as fallback specifications for simulated agent behavior during a workshop. Their frontmatter, safe-output examples, threat checks, and the local validation script document intended safeguards; they do not compile, execute, or enforce permissions, schemas, or post-stage validation by themselves.

## How This Maps To Peli's Factory

Peli's Agent Factory pattern encourages small, named agents with clear jobs, constrained tools, visible handoffs, and human review gates. These templates apply that pattern to Peli's Factory activity work:

| Agent | Factory Pattern | What It Practices |
| --- | --- | --- |
| [Issue Triage Agent](issue-triage-agent.md) | Intake line | Reads a new issue, applies only allowed labels, and leaves a rationale comment for humans. |
| [CI Doctor](ci-doctor.md) | Diagnostic bench | Investigates failed CI evidence, summarizes likely causes, and opens a diagnostic issue or proposed next step. |
| [Plan Command](plan-command.md) | Planning cell | Responds to `/plan` by decomposing a work item into safe, reviewable subtasks. |

Each specification describes the same intended operating model: minimal permissions, read-only investigation first, structured safe outputs, and a narrow post-stage that performs repository writes after validation. Those controls become runtime enforcement only in a separately configured and compiled workflow.

## GitHub Agentic Workflows Quick Start Mapping

When `gh-aw` is available, the expected quick start flow is:

1. Install the extension with `gh extension install github/gh-aw`.
2. Add or scaffold workflows with `gh aw add-wizard`.
3. Configure repository or environment secrets such as `COPILOT_GITHUB_TOKEN` or provider-specific API keys only where the workflow requires them.
4. Edit the markdown workflow frontmatter and body.
5. Run `gh aw compile` after frontmatter changes.
6. Commit both the markdown spec and generated lock file, but do not edit the generated `.lock.yml` by hand.

These workshop specs intentionally do not require that flow. Participants can review the design, validate required sections locally, and simulate the resulting GitHub issue or comment changes. The local check verifies required files, frontmatter keys, and headings; it does not parse Markdown as a workflow compiler or enforce runtime behavior.

## Safe-By-Default Design Rules

- Start with read-only context collection.
- Grant the narrowest permissions needed for the post-stage write.
- Do not expose repository secrets to the agent runtime.
- Design labels, comments, and created issues as safe outputs that a compiled workflow must validate against explicit schemas or allowlists before it writes.
- Keep write behavior deterministic and scoped.
- Include threat checks for prompt injection, malicious issue content, untrusted log output, and unsafe file references.
- Require human review before merging code changes or changing release gates.

## Workshop Use

Use these assets as an optional companion in Activity 03 when teams discuss agent roles and response plans, and in Activity 05 when teams discuss remediation handoffs. They are not required Activity 03 or Activity 05 deliverables.

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
