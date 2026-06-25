# Agentic SDLC Starter Kit

Use this resource during Challenges 00-06 to turn implicit team knowledge into repo-visible artifacts. Do not build everything. Build the smallest useful starter set and improve it as the day exposes gaps.

## Why This Exists

The handbook's core warning is that agents fail on real codebases when team knowledge is implicit. In this hackathon, participants should avoid that cliff by externalizing intent, conventions, boundaries, and review gates before assigning more autonomous work.

## Starter Instrumentation Set

| Primitive | Minimum Artifact | Challenge |
| --- | --- | --- |
| Instructions | A short repo guidance note with coding rules, review rules, and denied actions. | 00, 03 |
| Agent persona | A role card for one assistant, such as reviewer, tester, CI Doctor, or triage helper. | 03 |
| Skill or prompt | One reusable prompt for a repeated task. | 03 |
| Memory or decision note | One versioned convention, risk, or operating rule discovered during the day. | 03, 06 |
| Specs and orchestration | Agent-ready issues, plans, checklists, and handoff notes. | 01, 03, 05 |
| Hooks and gates | Tests, workflow checks, schemas, allowlists, approvals, or manual gates. | 04, 05 |

## Suggested Files or GitHub Artifacts

Use whatever the workshop repository allows. Good options include:

- `.github/copilot-instructions.md` or a repo instruction note.
- `.github/prompts/<task>.prompt.md` or a reusable prompt in an issue comment.
- `.github/agents/<role>.agent.md` or a short role card in the project wiki.
- `docs/decisions/<date>-<topic>.md` or a pinned issue comment.
- Pull request templates, issue templates, workflow files, and runbooks.

When a file path is unavailable or inappropriate for the customer's environment, use an issue, pull request comment, or project note. The key is durability and reviewability.

## PROSE Checklist

Use this before asking an agent to act.

| Constraint | Question |
| --- | --- |
| Progressive Disclosure | Did we give only the context needed for this step? |
| Reduced Scope | Did we state non-goals and protected areas? |
| Orchestrated Composition | Is one agent enough, or do we need writer/reviewer/tester or audit/execute/validate? |
| Safety Boundaries | Did we deny risky actions and require validation? |
| Explicit Hierarchy | Did we state which instruction wins when guidance conflicts? |

## Load Lifecycle Debugging

When an instruction, persona, prompt, skill, or memory note seems ignored, debug it in this order:

| Phase | Debug Question |
| --- | --- |
| Resolve | Can the harness find the artifact by name, path, or description? |
| Materialize | Did the artifact content enter the working context? |
| Bind | Did it attach to the right task, file, agent, or workflow event? |
| Activate | Did the agent behavior or workflow output actually reflect it? |

## Attention Economy Patterns

- Prefer small files and linked artifacts over one large prompt.
- Use subagent isolation or separate review roles when context is noisy.
- Plan, write the plan to a durable artifact, then reload from that artifact before execution.
- Treat context window as capacity, not attention. The most important instruction still needs to be clear, local, and activated.

## Deterministic/Probabilistic Seam

For consequential effects, use the rule: model proposes, deterministic substrate disposes.

| Agent May Propose | Deterministic or Human Gate Decides |
| --- | --- |
| Code change | Tests, review, branch protection, merge approval. |
| Workflow change | YAML validation, permissions review, environment protection. |
| Deployment | CI success, allowlists, environment approval, runtime validation. |
| Incident remediation | Evidence review, customer-safe summary, owner approval. |

## ADAPT Loop

Use this meta-process when work spans more than one prompt or agent.

1. Audit the current artifacts and evidence.
2. Plan the next smallest safe action.
3. Wave through scoped execution, one chunk at a time.
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
