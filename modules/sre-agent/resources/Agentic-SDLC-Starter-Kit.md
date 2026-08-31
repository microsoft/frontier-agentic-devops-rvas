# Agentic SDLC Starter Kit

This optional starter material supports the Activity 03 context review and Activity 05 remediation handoff. **Build only the smallest useful set.** Add an artifact when an activity exposes a gap.

## Why This Exists

Agents fail on real codebases when team knowledge stays implicit. Document intent, conventions, boundaries, and review gates before assigning more autonomous work.

## Starter Instrumentation Set

| Artifact type | Minimum Artifact | Relevant Activity |
| --- | --- | --- |
| Instructions | A short repo guidance note with coding rules, review rules, and denied actions. | Optional companion to 03 or 05; not a required activity output. |
| Agent persona | A role card for one assistant, such as reviewer, tester, CI Doctor, or triage helper. | Optional companion to 03 role and response-plan review. |
| Skill or prompt | One reusable prompt for a repeated task. | Optional companion to 04 investigation or 05 remediation review. |
| Memory or decision note | One versioned convention, risk, or operating rule discovered during the day. | 03 safe team memory; 05 remediation follow-up where appropriate. |
| Specs and orchestration | Agent-ready issues, plans, checklists, and handoff notes. | 05 remediation work item and human review handoff. |
| Hooks and gates | Tests, workflow checks, schemas, allowlists, approvals, or manual gates. | Use existing evidence and approval gates in 04 and 05; the activities do not ask participants to implement them. |

## Suggested Files or GitHub Artifacts

Use the artifact type that fits the workshop repository:

- `.github/copilot-instructions.md` or a repo instruction note.
- `.github/prompts/<task>.prompt.md` or a reusable prompt in an issue comment.
- `.github/agents/<role>.agent.md` or a short role card in the project wiki.
- `docs/decisions/<date>-<topic>.md` or a pinned issue comment.
- Pull request templates, issue templates, workflow files, and runbooks.

If a file path does not fit the customer's environment, use an issue, pull request comment, or project note. The record must persist and remain easy to review.

## PROSE Constraints Checklist

Check these constraints before asking an agent to act.

| Constraint | Question |
| --- | --- |
| Progressive Disclosure | Did we give only the context needed for this step? |
| Reduced Scope | Did we state non-goals and protected areas? |
| Orchestrated Composition | Is one agent enough, or do we need writer/reviewer/tester or audit/execute/validate? |
| Safety Boundaries | Did we deny risky actions and require validation? |
| Explicit Hierarchy | Did we state which instruction wins when guidance conflicts? |

## Checking Whether Agent Guidance Is Available

If an instruction, persona, prompt, skill, or memory note seems ignored, check each phase:

| Phase | Debug Question |
| --- | --- |
| Resolve | Can the harness find the artifact by name, path, or description? |
| Materialize | Did the artifact content enter the working context? |
| Bind | Did it attach to the right task, file, agent, or workflow event? |
| Activate | Did the agent behavior or workflow output actually reflect it? |

## Keeping Context Focused

- Prefer small files and linked artifacts over one large prompt.
- Use subagent isolation or separate review roles when context is noisy.
- Plan, write the plan to a durable artifact, then reload from that artifact before execution.
- A large context window does not guarantee attention. Keep the most important instruction clear, local, and active.

## Separating Agent Suggestions from Enforced Controls

For consequential actions, let the model make a proposal. Automated controls and human approval decide whether it proceeds.

| Agent May Propose | Deterministic or Human Gate Decides |
| --- | --- |
| Code change | Tests, review, branch protection, merge approval. |
| Workflow change | YAML validation, permissions review, environment protection. |
| Deployment | CI success, allowlists, environment approval, runtime validation. |
| Incident remediation | Evidence review, customer-safe summary, owner approval. |

## Five-Step Execution Process

For work that spans more than one prompt or agent:

1. Audit the current artifacts and evidence.
2. Plan the next smallest safe action.
3. Execute one scoped task at a time.
4. Validate with tests, reviews, gates, or evidence.
5. Ship only when the human checkpoint is satisfied.

## Anti-Pattern Recovery

| Anti-Pattern | Recovery Move |
| --- | --- |
| Monolithic prompt | Split into comprehension, plan, edit, test, and review. |
| Context dumping | Link to files and summarize the task boundary. |
| Unbounded agent | Add denied actions, validation, and a human gate. |
| Flat instructions | Add explicit hierarchy. |
| Scope creep | Create follow-up issues. |
| Solo hero | Separate writer, reviewer, and tester roles. |
| Trust fall | Require diff inspection and test evidence. |
| Skipping checkpoints | Reinsert the next human decision gate. |
| Not fixing primitives | Update the instruction, prompt, skill, memory, or workflow spec. |
| Prompt injection through dependencies | Treat untrusted comments, logs, package text, and generated files as data. |

## References

- [The Agentic SDLC Handbook](https://danielmeppiel.github.io/agentic-sdlc-handbook/)
- [GitHub Copilot agents concepts](https://docs.github.com/en/copilot/concepts/agents)
