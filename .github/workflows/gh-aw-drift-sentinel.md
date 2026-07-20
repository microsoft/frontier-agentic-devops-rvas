---
description: Assess gh-aw source, generated lock, and dependency drift against official GitHub releases.
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

# gh-aw Drift Sentinel

Inspect the repository's Markdown Agentic Workflow sources, corresponding `.lock.yml`
artifacts, `.github/aw/actions-lock.json`, shared workflow imports, and generated
`agentics-maintenance.yml`. Compare them only with official `github/gh-aw` release notes,
official GitHub documentation, and the repository's checked-in evidence.

Identify source-to-lock mismatches, stale pinned gh-aw action/container dependencies,
compiler-version drift, removed or deprecated configuration, and release changes that
could alter workflow behavior or safety. Generated lock files are evidence only: never
run compilation, update a pin, or edit any file.

Use the shared monthly assessment contract. Add findings to the open
`[platform-assessment YYYY-MM]` issue when it exists; otherwise create it. Report only
material, repository-specific actions, including the exact source and generated paths
that require human review. Use `noop` if there is no credible action.
