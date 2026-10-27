---
on:
  workflow_dispatch:
permissions:
  issues: read
checkout: false
safe-outputs:
  create-issue:
    max: 1
    title-prefix: "[gh-aw readiness] "
    deduplicate-by-title: true
tools:
  github:
    toolsets: [issues]
engine: copilot
---

# Customer repository runtime check

Search this repository for an issue titled
`[gh-aw readiness] Runtime verified`, including closed issues.
If one exists, call noop.

Otherwise, request one issue with that title. State that the AI engine ran and
requested this issue. The maintainer must check the Actions run and issue before
confirming readiness. Do not claim that any customer pilot or required PR checks
passed.
