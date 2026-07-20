<!--
  CANONICAL DELIVERY-TEAM-GUIDE TEMPLATE — DO NOT EDIT IN PLACE.
  Copy this file into activities/ch##-<slug>/README.md and fill every section.
  Every activity MUST keep these section headings, in this order. The Pages
  site (Basher) renders these sections; the scripts (Yen) key off the Setup
  command and meta.yml. Keep prose tight — rich, not bloated.
  Date convention for any dates in content: ISO (YYYY-MM-DD).
-->

# Ch## — <Activity Title>

> One-sentence hook: what the delivery team member will be able to do by the end.

| | |
|---|---|
| **Track** | <Developer Flow \| Admin/Governance \| Security \| Automation & AI> |
| **Difficulty** | <Foundational \| Intermediate \| Advanced> *(per-track ramp)* |
| **Duration** | <3–8 hrs total, multi-session> |
| **Minimum input** | An **org** + an **org-owner token**. *(All activities are org-scoped — no enterprise owner required.)* |
| **App** | <juice-shop \| seed \| none> |
| **EMU compatible** | <yes \| no — if no, state why + the prerequisite> |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch## --org <org>` (least-privilege; documented per activity).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- <Any activity-specific prerequisite, e.g., "Copilot coding agent policy enabled (NOT available on EMU repos)".>

## Scenario objectives
By completing this activity you will:
- <Objective 1 — verb-first, observable.>
- <Objective 2.>
- <Objective 3.>

## Scenario
<2–4 sentences of narrative framing. Why does this matter to a real GHEC customer?
Set the stakes so the tasks feel purposeful, not academic.>

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported):

```bash
# Bash
./scripts/setup.sh ch## --org <org>
```
```powershell
# PowerShell
./scripts/setup.ps1 ch## --org <org>
```

**What setup creates** (all artifacts namespaced `ghec-ch##-*`, idempotent, prefix-guarded teardown):
- <e.g., repo `ghec-ch##-<slug>` seeded with starting content.>
- <e.g., labels / issues / branch protection / ruleset / Juice Shop import at pinned ref v20.0.0.>
- A printed **Next steps** block telling you where to start.


## Tasks
1. **<Task 1 title>** — <what to do; link to the exact UI path or `gh` command.>
2. **<Task 2 title>** — <…>
3. **<Task 3 title>** — <…>
4. **<Task 4 title>** — <…>
<!-- Long-form activity: aim for enough numbered tasks to fill the duration. -->

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] <Observable, checkable outcome 1 — ideally verifiable via `gh` / Actions.>
- [ ] <Outcome 2.>
- [ ] <Outcome 3.>

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- <Optional deeper task for fast finishers.>
- <Another stretch — keep these clearly optional.>

## Reference links
- <Official docs.github.com link (Enterprise Cloud version where admin-scoped).>
- <Second reference.>

<!-- Hidden links/data live in meta.yml — keep this README human-readable. -->
