---
description: Review this repository as a product and publish one evidence-backed, current set of feature opportunities when material gaps exist.
on:
  schedule: weekly on Tuesday
  workflow_dispatch:
permissions:
  contents: read
  issues: read
network: defaults
timeout-minutes: 10
tools:
  github:
    min-integrity: approved
    toolsets: [repos, issues, labels]
safe-outputs:
  create-issue:
    title-prefix: "[feature-opportunities] "
    labels: [agentic-workflows, enhancement]
    max: 1
    close-older-issues: true
  noop:
    report-as-issue: false
imports:
  - shared/github-guard-policy.md
  - shared/reporting.md
---

# Next Feature Opportunities

Review this repository as the product it delivers. Identify the most impactful
functional improvements the maintainers could build next, using only evidence in
the repository and its issue tracker. Do not modify source code, documentation,
settings, labels, Projects, or workflows.

## Evidence-gathering protocol

1. Map current capabilities from the root README, user-facing documentation,
   module metadata, application routes or handlers where present, and relevant
   configuration. State the repository paths that support each finding.
2. Review open issues for already-requested work, reported friction, and
   duplicates. Do not recommend work that an open issue already owns unless the
   recommendation is a clearly identified missing dependency or consolidation.
3. Identify gaps in user journeys, discoverability, feedback, accessibility,
   onboarding, integrations, automation, and operational handover. Consider
   monetization only when repository evidence shows it is applicable.
4. Rank only recommendations that are specific, feasible in this repository,
   and materially improve the product for its users. Do not invent users,
   competitors, integrations, data sources, or features absent from the
   repository evidence.

## Reporting rules

Create one issue only when there are material, evidence-backed opportunities
that are not already tracked. Use the title:

`Next feature opportunities`

Use this structure:

### Feature health overview

Briefly describe the product's current capability and the most important
observed strengths and gaps. Cite repository paths throughout.

### Top 5 next features

For each ranked recommendation include:

- **Area**
- **Opportunity**
- **User story**: As a ... I want to ... so that ...
- **Evidence**: repository paths and relevant issue references
- **User value**
- **Implementation considerations**: existing architecture, data, operations,
  and UI or documentation surfaces affected
- **Effort**: Small, Medium, or Large
- **Priority**: P0, P1, P2, or P3

### Quick UX wins

List only low-effort improvements grounded in an observed user-flow or
accessibility gap.

### Not recommended yet

Name plausible ideas that lack sufficient repository evidence or are already
tracked, with the reason they should not be started.

Keep the report concise and actionable. If no material, untracked opportunities
exist, use `noop` and summarize the evidence reviewed.
