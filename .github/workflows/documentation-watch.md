---
description: Identify stale official GitHub links and product terminology in repository documentation.
on:
  schedule: weekly on Monday
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
    labels: [documentation]
  add-comment:
  noop:
    report-as-issue: false
imports:
  - shared/github-guard-policy.md
  - shared/reporting.md
  - shared/platform-maintenance.md
---

# Documentation Link and Product-Term Watcher

Review repository Markdown, setup instructions, and customer-facing documentation for
links to official GitHub properties and GitHub product terminology. Check a bounded,
representative set each run and rotate through remaining files over time.

Report only:

- an unreachable or redirected official GitHub URL that changes the intended destination;
- an official GitHub product rename or terminology change with a canonical source;
- a documented capability, prerequisite, or command contradicted by current official docs.

Use the shared monthly assessment contract. Comment on the current month's platform
assessment issue when possible; otherwise create it. Each finding must name the exact
repository path and source URL. Do not recommend wording changes without official
evidence, and do not create pull requests or edit documentation. Use `noop` when no
material issue is found.
