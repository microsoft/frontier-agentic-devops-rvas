# Hello World — gh-aw Smoke Test

---
on:
  schedule:
    - cron: "0 9 * * 1"
  workflow_dispatch:

permissions:
  issues: write

safe-outputs:
  create-issue:
    max: 1
    labels: [hello-world, automated]
  noop:

engine: copilot
---

## Goal

Create a "Hello from gh-aw!" issue to confirm the workflow runtime is working correctly.

## Steps

1. Note the current date and time (UTC).
2. Create an issue with the title `👋 Hello from gh-aw! — {YYYY-MM-DD}` and a short body
   confirming the workflow ran successfully, including the current date/time and a
   one-sentence note that this is an automated smoke test.

{{#runtime-import shared/noop-reminder.md}}
