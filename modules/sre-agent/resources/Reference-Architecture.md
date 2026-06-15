# Reference Architecture

## Learning Architecture

The hackathon uses a single service story and a chain of evidence. Each challenge adds one layer to the team's operating model.

```text
Backlog issue
  -> starter context and human roles
  -> branch
  -> pull request
  -> review and validation
  -> repo instrumentation primitives
  -> GitHub Actions workflow
  -> deterministic gate map
  -> Azure deployment
  -> deployment evidence
  -> incident signal
  -> Azure SRE Agent investigation pattern
  -> source-code context
  -> GitHub issue or pull request
  -> human review
```

## Core Systems

| System | Role in the Hackathon |
| --- | --- |
| GitHub Issues | Captures intent, acceptance criteria, blockers, and remediation work. |
| GitHub Pull Requests | Carries implementation, review, validation, and merge decisions. |
| GitHub Copilot | Assists with comprehension, implementation, tests, review preparation, and summaries. |
| Repo instrumentation primitives | Externalize instructions, personas, reusable prompts, skills, memory, decisions, specs, and gates. |
| Agent workflows | Help decompose work, preserve context, and route feedback while humans own decisions. |
| GitHub Agentic Workflows | Represent safe markdown workflow specs that can compile to GitHub Actions lock files when `gh-aw` is available. |
| GitHub Actions | Provides validation, deployment automation, and auditable workflow evidence. |
| Azure | Hosts or represents the runtime target for the service. |
| Azure SRE Agent | Supports investigation patterns that connect production symptoms, source-code context, and remediation. |

## Human, Agent, and Platform Layers

The learning architecture separates three kinds of responsibility:

| Layer | Responsibility | Hackathon Examples |
| --- | --- | --- |
| Human | Own intent, judgment, policy, review, merge, and release decisions. | Issue acceptance criteria, PR review, deployment approval, incident decision notes. |
| Agent | Propose, summarize, decompose, investigate, draft changes, and surface risks. | Copilot prompts, agent workflow plans, cloud coding agent PRs, SRE investigation plans. |
| Platform | Provide deterministic records, controls, execution, and audit evidence. | GitHub Issues, Pull Requests, Actions checks, environments, Azure deployment records, runbooks. |

The deterministic/probabilistic seam matters throughout the day. Agent output is probabilistic: useful for exploration, drafting, and investigation, but not proof by itself. Platform evidence is deterministic enough to inspect: issue history, pull request diffs, workflow logs, deployment records, timestamps, and explicit human review. Coaches should keep asking teams to move useful agent output across that seam into auditable GitHub or Azure evidence before treating it as done.

## Evidence Chain

Coaches should continually ask teams to preserve evidence in these places:

| Evidence | Where It Should Live |
| --- | --- |
| Product intent | GitHub issue. |
| Human accountability | Setup note, issue, project note, or repo instruction. |
| Agent instructions and conventions | Versioned instruction, prompt, skill, memory, decision, or workflow spec. |
| Implementation and review | Pull request. |
| AI assistance and human validation | Pull request notes or review comments. |
| Build and test results | GitHub Actions run or documented local output. |
| Deterministic gate map | Pull request, deployment note, or workflow documentation. |
| Deployment result | GitHub Actions run, environment record, endpoint note, or fallback packet. |
| Incident timeline | Incident investigation note or issue. |
| Source-code hypothesis | File, line, commit, or pull request reference when evidence supports it. |
| Remediation | GitHub issue or pull request requiring human review. |

## Runtime Model for the Hackathon

Participants should reason about agents as a runtime, not magic:

| Part | Workshop Translation |
| --- | --- |
| Model | The probabilistic engine proposing text, code, plans, or diagnoses. |
| Harness | The client or workflow runner that resolves files, provides tools, and applies permissions. |
| Agent source code | Markdown instructions, persona files, prompts, skills, specs, workflow definitions, and memory notes. |
| Client | Copilot Chat, cloud agent, GitHub Agentic Workflow, CLI, editor, or SRE Agent surface. |

Markdown that steers agents is code. It should be versioned, reviewed, tested, packaged, and pinned when the environment supports it. Descriptions are activation APIs: vague descriptions produce unreliable activation.

## Execution Meta-Process

Use ADAPT across multi-step work:

```text
Audit -> Plan -> Wave -> Validate -> Ship
```

This keeps agent work checkpointed. It also gives coaches a recovery path when a team has tried one long prompt and lost track of evidence.

## Azure SRE Agent Boundary

Use source-aligned language:

- Azure SRE Agent can connect source code for investigations.
- Investigations can analyze repositories, provide file and line references, create To-Do investigation plans, correlate symptoms to code changes, and create pull requests in review or autonomous modes when source branches exist.
- The microsoft/sre-agent repository is the community hub for labs and resources.
- Azure/sre-agent-plugins provides official plugin examples and marketplace structure.

Avoid promising specific tenant availability, production autonomy, or automatic remediation outcomes. Use preview or simulation framing whenever live access is uncertain.
