---
description: Assess official GitHub platform announcements and create one monthly, evidence-backed repository impact issue.
on:
  schedule: "0 14 1 * *"
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
  web-fetch:
safe-outputs:
  create-issue:
    title-prefix: "[platform-assessment "
    labels: [agentic-workflows, enhancement]
  add-comment:
  noop:
    report-as-issue: false
imports:
  - shared/github-guard-policy.md
  - shared/reporting.md
  - shared/platform-maintenance.md
---

# Platform Radar

Assess changes published since the previous calendar month only. Retrieve announcements
from the GitHub Changelog, GitHub Blog, GitHub Docs, and official `github/gh-aw` release
notes. Do not use other sources.

Compare each credible change against this repository's `.github/workflows/`, `.github/aw/`,
`modules/`, `docs/`, dev-container setup, and contributor instructions. Focus on GitHub
Actions, GitHub Agentic Workflows, Copilot, GitHub Advanced Security, GitHub Enterprise
Cloud, APIs, webhooks, runners, Codespaces, and deprecations.

Create at most one issue titled `[platform-assessment YYYY-MM] GitHub platform radar`
when at least one material finding exists. Use the shared monthly assessment contract.
Group findings by assessment, include only repository-specific recommendations, and label
uncertain conclusions as `watch` or `evaluate`. If no material finding exists, use `noop`.

Never change code, workflow files, generated locks, labels, settings, or documentation.
