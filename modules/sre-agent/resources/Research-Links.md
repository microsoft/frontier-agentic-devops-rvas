# Research Links

Curated references for the Frontier Agentic DevOps Delivery session. Prefer these links when writing challenge guides, coach notes, and setup instructions.

## Azure SRE Agent

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [microsoft/sre-agent](https://github.com/microsoft/sre-agent) | Source for SRE Agent labs, sample environments, prompt guides, docs links, feedback, and community resources. | Official community hub. Good starting point for Challenge 6 coach preparation. |
| [Azure/sre-agent-plugins](https://github.com/Azure/sre-agent-plugins) | Source for the plugin model. | Official plugin repo. Plugins live under `plugins/` and are registered in `.github/plugin/marketplace.json`. |
| [Connect source code in Azure SRE Agent](https://learn.microsoft.com/en-us/azure/sre-agent/connect-source-code) | Source for source-code connection behavior and prerequisites. | Covers GitHub and Azure DevOps repo connection, OAuth/PAT auth, investigation file:line references, To-Do Plans, symptom-to-code correlation, and PR creation caveats. |
| [Azure SRE Agent documentation](https://learn.microsoft.com/en-us/azure/sre-agent/) | Main product documentation entry point. | Use for setup and current product behavior close to delivery date. |

## GitHub Copilot Agents

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [GitHub Copilot agents concepts](https://docs.github.com/en/copilot/concepts/agents) | Source for agent concepts across cloud agent, CLI, app, code review, memory, hooks, third-party coding agents, agent apps, skills, and enterprise management. | Useful for Challenges 2, 3, and 5. Keep feature availability caveats in the student guide. |
| [GitHub Copilot cloud agent concepts](https://docs.github.com/en/copilot/concepts/agents/cloud-agent) | Source for asynchronous coding-agent flow. | Best used when writing the Challenge 5 issue-to-agent-to-review story. |
| [About GitHub Copilot code review](https://docs.github.com/en/copilot/concepts/agents/code-review) | Source for PR review behavior. | Use when explaining that agent-created changes still need human review. |

## Agentic SDLC Methodology

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [The Agentic SDLC Handbook](https://danielmeppiel.github.io/agentic-sdlc-handbook/) | Methodology frame for AI-native software delivery. | Daniel Meppiel's handbook is a living pre-release under CC BY-NC-ND 4.0. Summarize and attribute; do not copy long passages. |
| [The Agentic SDLC Thesis](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch01-the-agentic-sdlc-thesis.html) | Source for the claim that AI-native delivery needs an operating model, not only tool adoption. | Useful framing for Challenge 00 and Challenge 01. |
| [The Reference Architecture](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch04-the-reference-architecture.html) | Source for human, agent, and platform separation. | Connect to the delivery session evidence chain and review gates. |
| [Governance for AI-Assisted Delivery](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch05-governance-for-ai-assisted-delivery.html) | Source for governance and accountability language. | Use when explaining why humans still own policy, review, and release decisions. |
| [The Practitioner's Mindset](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch10-the-practitioners-mindset.html) | Source for practitioner habits when working with agents. | Applies directly to Challenge 03 prompt, plan, test, and verify loops. |
| [The Runtime Machine](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch11-the-runtime-machine.html) | Source for agent runtime concepts. | Useful for Challenge 03 coordination and handoff design. |
| [The Instrumented Codebase](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch12-the-instrumented-codebase.html) | Source for repo instrumentation as an agent-enablement layer. | Connect to tests, scripts, workflow logs, and validation evidence. |
| [The PROSE Specification](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch13-the-prose-specification.html) | Source for constraint-based specification practice. | Use as a lens for agent-ready issues and reviewable PRs. |
| [The Load Lifecycle](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch14-the-load-lifecycle.html) | Source for how context is prepared for agent work. | Connect to concise issue context, relevant files, and acceptance criteria. |
| [Attention and Context Economy](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch15-attention-and-context-economy.html) | Source for context-budget thinking. | Useful for keeping challenge prompts and handoffs focused. |
| [Deterministic/Probabilistic Boundary](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch16-deterministic-probabilistic-boundary.html) | Source for separating agent judgment from deterministic validation. | Connect Azure SRE Agent investigation evidence to human validation and governed remediation. |
| [Multi-Agent Orchestration](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch17-multi-agent-orchestration.html) | Source for coordinating specialized agents. | Applies to Challenge 03 and Challenge 05 handoff/review loops. |
| [The Execution Meta-Process](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch18-the-execution-meta-process.html) | Source for iterative execution around agent work. | Useful when coaches explain plan, act, validate, adapt cycles. |
| [Architectural Patterns Rosetta Stone](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch19-architectural-patterns-rosetta-stone.html) | Source for naming recurring agentic architecture patterns. | Use lightly for coach preparation, not as required student reading. |
| [Anti-Patterns and Failure Modes](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch20-anti-patterns-and-failure-modes.html) | Source for warning signs in agentic delivery. | Useful for Challenge 05 review and rejection discussion. |
| [Primitives as Code](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch21-primitives-as-code.html) | Source for making agent primitives inspectable and reusable. | Connect to workflow specs, issue templates, prompts, and runbooks. |
| [The Reference Architecture Earned](https://danielmeppiel.github.io/agentic-sdlc-handbook/handbook/ch22-the-reference-architecture-earned.html) | Source for trust emerging from repeated evidence. | Good closing frame for the full challenge arc. |

## GitHub Agentic Workflows and Peli's Agent Factory

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [GitHub Agentic Workflows](https://github.github.com/gh-aw/) | Source for repository-level agentic automation concepts. | The site describes Markdown-authored workflows compiled into guarded GitHub Actions automation. Treat as early development and supervision-required. |
| [Quick Start](https://github.github.com/gh-aw/setup/quick-start/) | Source for setup flow using the `gh aw` extension. | Useful for optional coach demos; requires compatible GitHub CLI, Actions, provider credentials, and repo permissions. |
| [Welcome to Peli's Agent Factory](https://github.github.com/gh-aw/blog/2026-01-12-welcome-to-pelis-agent-factory/) | Source for the factory pattern: many specialized workflows tested in real repositories. | Good conceptual companion for Challenge 03 and Challenge 05. |
| [Issue Triage Workflow](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows/) | Source for a simple triage-agent pattern. | Maps to Challenge 01 issue hygiene and Challenge 03 routing. |
| [Fault Investigation / CI Doctor](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-quality-hygiene/) | Source for CI failure and fault-investigation workflow patterns. | Useful background for comparing GitHub workflow diagnostics with Azure SRE Agent incident investigation. |
| [Project Coordination / Plan Command](https://github.github.com/gh-aw/blog/2026-01-13-meet-the-workflows-campaigns/) | Source for plan/decomposition workflows. | Maps directly to Challenge 03 decomposition and multi-agent coordination. |

## GitHub Actions and Delivery

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [GitHub Actions quickstart](https://docs.github.com/en/actions/get-started/quickstart) | Basic Actions workflow reference. | Confirms Actions is a CI/CD platform for automating build, test, and deployment pipelines. |
| [Understanding GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions) | Workflow concepts. | Use for Challenge 4 coach notes when explaining events, jobs, runners, and steps. |
| [GitHub Actions starter workflows](https://github.com/actions/starter-workflows) | Workflow examples. | Useful fallback when teams need a starting point for CI or deployment. |

## What The Hack Format

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [microsoft/WhatTheHack](https://github.com/microsoft/WhatTheHack) | Format anchor for challenge-based delivery session structure. | What The Hack challenges describe high-level tasks and goals, not step-by-step labs. Coaches guide without giving direct answers. |
| [Modern Development and DevOps with GitHub](https://github.com/microsoft/WhatTheHack/tree/master/065-ModernGitHubDev) | Reference for GitHub SDLC challenge design. | Useful when shaping Challenge 1 and Challenge 4. |
| [GitHub Copilot What The Hack](https://github.com/microsoft/WhatTheHack/tree/master/071-GitHubCopilot) | Reference for Copilot learning flow. | Useful when shaping Challenge 03. |
| [DevOps with GitHub Actions](https://github.com/microsoft/WhatTheHack/tree/master/044-DevOpswithGithubActions) | Reference for Actions-focused delivery exercises. | Useful when Challenge 4 needs a deeper Actions path. |

## Azure Operational Excellence

| Source | Use in Curriculum | Notes |
| --- | --- | --- |
| [Azure Well-Architected: Operational excellence](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/) | Reliability and operations frame for Challenge 6. | Official guidance covers DevOps culture, development standards, observability, automation, safe deployments, operational tasks, and incident response. |
| [Design an incident response strategy](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/incident-response) | Incident response design reference. | Use to keep SRE response work tied to operational practice rather than tool demos. |
| [Design for observability](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/observability) | Observability reference. | Useful when defining the evidence packet for Challenge 6. |
| [Use safe deployment practices](https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/safe-deployments) | Deployment safety reference. | Connects Challenge 4 deployment gates to Challenge 6 operational response. |

## Source Caveats

- The Agentic SDLC Handbook is licensed CC BY-NC-ND 4.0. Attribute Daniel Meppiel, summarize in your own words, and do not adapt or reproduce large sections in curriculum files.
- GitHub Agentic Workflows and Peli's Agent Factory are early, evolving sources. Verify current setup, security, provider, and repository-permission requirements before delivery.
- Product docs can change quickly. Re-check Azure SRE Agent and GitHub Copilot agent docs before customer delivery.
- Some features may require preview access, specific run modes, region availability, repository permissions, or tenant policy approval.
- Use simulated packets when live access is blocked, but keep the same artifacts: signal, evidence, suspected cause, remediation path, and follow-up work item.