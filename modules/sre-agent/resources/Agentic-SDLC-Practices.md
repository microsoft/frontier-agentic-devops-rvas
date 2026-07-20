# Agentic SDLC Practices

This note connects the delivery session path to The Agentic SDLC Handbook without adding a separate lecture track. Use it as a coach reference when teams need language for responsible agent-assisted delivery.

## Handbook Integration

- External reference: [The Agentic SDLC Handbook](https://danielmeppiel.github.io/agentic-sdlc-handbook/)
- Workshop anchor: keep every agent-assisted step tied to a GitHub issue, pull request, review, deployment signal, or incident artifact.
- Delivery stance: prefer small, reviewable changes with visible human ownership over broad autonomous rewrites.
- Operating warning: document team knowledge before granting an agent more autonomy.
- Treat instructions, agents, skills, prompts, memory, specifications, coordination rules, and hooks as versioned artifacts that can be reviewed and tested.

## Where It Fits

| Moment | Practice |
| --- | --- |
| Activity 00 | Confirm the supported Azure environment, access prerequisites, and coach fallback path before assigning work to an agent. |
| Activity 01 | Deploy or inspect the service environment, identify the connected Azure resources, and record healthy baseline evidence. |
| Activity 03 | Verify the knowledge, runbooks, response plans, alert routes, roles, and safe team memory that inform Azure SRE Agent. |
| Activity 04 | Use alerts, logs, metrics, traces, runbooks, and resource state as evidence; keep mitigation behind human or coach review. |
| Activity 05 | Correlate validated operational evidence with source-code leads, then create or review a remediation work item with uncertainty, validation, and a human decision gate. |

## Quick Checks

| Lens | Question |
| --- | --- |
| PROSE constraints (Progressive Disclosure, Reduced Scope, Orchestrated Composition, Safety Boundaries, Explicit Hierarchy) | Did the team provide only needed context, state protected areas and non-goals, define roles, require validation, and say which instruction takes precedence? |
| Instruction availability | Can the system find the artifact, load its content, attach it to the correct task, and apply it? |
| Focused context | Did the team preserve only the context needed for the next step? |
| Agent proposals and enforced gates | What can the model propose, and what do tests, schemas, allowlists, permissions, or humans decide? |
| Task coordination | Is one agent enough, or does the task need writer/reviewer/tester, audit/execute/validate, one-file-one-agent, or staged checkpoints? |

## Coach Prompts

- Where is the human decision recorded?
- What context did the agent receive, and what context was withheld?
- Which test, review, or deployment signal would catch a bad agent suggestion?
- What should become reusable guidance after this activity?
- Which primitive failed, and how will the team fix it before asking the agent again?

## Related Assets

- [Agentic SDLC Starter Kit](Agentic-SDLC-Starter-Kit.md)
- [GitHub Agentic Workflows Starter](GitHub-Agentic-Workflows-Starter.md)
- [Agent-Ready Issue Template](Agent-Ready-Issue-Template.md)
- [Reference Architecture](Reference-Architecture.md)
- [Activity 03: Onboard Service Context and Response Plans](../challenges/03-onboard-context/README.md)