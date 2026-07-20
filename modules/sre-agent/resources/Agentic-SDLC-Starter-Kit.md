# Agentic SDLC Starter Kit

Use this resource as optional coach material for the implemented Activity 03 context review and Activity 05 remediation handoff. Do not build everything. Build the smallest useful starter set and improve it only where the activity exposes a gap.

## Why This Exists

Agents fail on real codebases when team knowledge is undocumented. In this delivery session, participants should document intent, conventions, boundaries, and review gates before assigning more autonomous work.

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

Use whatever the workshop repository allows. Good options include:

- `.github/copilot-instructions.md` or a repo instruction note.
- `.github/prompts/<task>.prompt.md` or a reusable prompt in an issue comment.
- `.github/agents/<role>.agent.md` or a short role card in the project wiki.
- `docs/decisions/<date>-<topic>.md` or a pinned issue comment.
- Pull request templates, issue templates, workflow files, and runbooks.

When a file path is unavailable or inappropriate for the customer's environment, use an issue, pull request comment, or project note. The key is durability and reviewability.

## PROSE Constraints Checklist

Use this before asking an agent to act.

| Constraint | Question |
| --- | --- |
| Progressive Disclosure | Did we give only the context needed for this step? |
| Reduced Scope | Did we state non-goals and protected areas? |
| Orchestrated Composition | Is one agent enough, or do we need writer/reviewer/tester or audit/execute/validate? |
| Safety Boundaries | Did we deny risky actions and require validation? |
| Explicit Hierarchy | Did we state which instruction wins when guidance conflicts? |

## Checking Whether Agent Guidance Is Available

When an instruction, persona, prompt, skill, or memory note seems ignored, debug it in this order:

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
- Treat context window as capacity, not attention. The most important instruction still needs to be clear, local, and activated.

## Separating Agent Suggestions from Enforced Controls

For consequential effects, let the model propose actions, then use automated controls and human approval to decide whether to proceed.

| Agent May Propose | Deterministic or Human Gate Decides |
| --- | --- |
| Code change | Tests, review, branch protection, merge approval. |
| Workflow change | YAML validation, permissions review, environment protection. |
| Deployment | CI success, allowlists, environment approval, runtime validation. |
| Incident remediation | Evidence review, customer-safe summary, owner approval. |

## Five-Step Execution Process

Use this meta-process when work spans more than one prompt or agent.

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
