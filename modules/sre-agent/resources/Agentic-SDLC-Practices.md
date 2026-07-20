# Agentic SDLC Practices

This note connects the delivery session path to The Agentic SDLC Handbook without adding a separate lecture track. Use it as a coach reference when teams need language for responsible agent-assisted delivery.

## Handbook Integration

- External reference: [The Agentic SDLC Handbook](https://danielmeppiel.github.io/agentic-sdlc-handbook/)
- Workshop anchor: keep every agent-assisted step tied to a GitHub issue, pull request, review, deployment signal, or incident artifact.
- Delivery stance: prefer small, reviewable changes with visible human ownership over broad autonomous rewrites.
- Operating warning: avoid the Vibe Coding Cliff by externalizing implicit team knowledge before increasing agent autonomy.
- Primitive stance: treat instructions, agents, skills, prompts, memory, specs, orchestration, and hooks as code that can be versioned, reviewed, tested, packaged, and pinned.

## Where It Fits

| Moment | Practice |
| --- | --- |
| Activity 00 | Choose human accountability roles and create a starter context artifact. |
| Activity 01 | Turn vague intent into an issue with acceptance criteria, boundaries, validation commands, and human checkpoints. |
| Activity 03 | Use PROSE-style coordination prompts, validate agent output, and externalize one discovered convention as starter repo instrumentation: instructions, persona, reusable prompt or skill, and memory or decision note. |
| Activity 04 | Treat CI, environments, approvals, schemas, allowlists, and deployment logs as the deterministic substrate. |
| Activity 05 | Build safe GitHub Agentic Workflows style specs and review cloud-agent work like teammate work. |
| Activity 05 | Convert incident learning into a follow-up issue or pull request with operational context and instrumentation improvements. |

## Quick Checks

| Lens | Question |
| --- | --- |
| PROSE | Is the work progressively disclosed, reduced in scope, composed intentionally, bounded for safety, and governed by explicit hierarchy? |
| Load lifecycle | Did the artifact resolve, materialize, bind, and activate? |
| Attention economy | Did the team avoid context dumping and preserve only the context needed for the next step? |
| Deterministic/probabilistic seam | What can the model propose, and what do tests, schemas, allowlists, permissions, or humans decide? |
| Orchestration | Is one agent enough, or does the task need writer/reviewer/tester, audit/execute/validate, one-file-one-agent, waves, or checkpoints? |

## Coach Prompts

- Where is the human decision recorded?
- What context did the agent receive, and what context was withheld?
- Which test, review, or deployment signal would catch a bad agent suggestion?
- What should become reusable guidance after this activity?
- Which primitive failed, and how will the team fix it before asking the agent again?

## Related Assets

- [Build Agentic Workflows](agentic-workflows/README.md)
- [Agentic SDLC Starter Kit](Agentic-SDLC-Starter-Kit.md)
- [GitHub Agentic Workflows Starter](GitHub-Agentic-Workflows-Starter.md)
- [Agent-Ready Issue Template](Agent-Ready-Issue-Template.md)
- [Reference Architecture](Reference-Architecture.md)
- [Activity 03: Onboard Service Context and Response Plans](../challenges/03-onboard-context/README.md)