# Ch01 — Issues, Labels & Project Boards

> By the end of this challenge you can run a real piece of work end-to-end on GitHub — triaged with labels and milestones, tracked on a Projects (v2) board with custom fields, automated workflows, and an insight chart — using nothing but an org and an org-owner token.

| | |
|---|---|
| **Track** | Developer Flow |
| **Difficulty** | Foundational *(per-track ramp)* |
| **Duration** | ~3–4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch01 --org <org>` (least-privilege; for this challenge: `repo` + `project` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `wth doctor` to verify).
- No GHAS, Codespaces, or enterprise features are required for this challenge.

## Learning objectives
By completing this challenge you will:
- Create, triage, and close **issues** using templates (issue forms), assignees, and task lists.
- Design a **label taxonomy** (type / priority / area / status) and apply it consistently.
- Group work into **milestones** and track completion percentage.
- Build a **Projects (v2)** board with custom fields, saved views (board + table + roadmap), and **built-in workflows** that auto-move items.
- Drive the whole flow from both the **UI** and the **`gh` CLI / GraphQL API** so you can automate it later.

## Scenario
You have just inherited the backlog for an internal developer-tools team at a GHEC customer. Work is scattered across chat threads, spreadsheets, and people's heads. Leadership wants a single source of truth: every request becomes an issue, every issue is triaged within a day, and a live board shows what's in flight, what's blocked, and what ships this sprint. Your job is to stand that system up on GitHub the way you'd hand it to a real team on Monday morning.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch01 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh ch01 --org <org>
```
```powershell
# PowerShell
wth setup ch01 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 ch01 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch01-*`, idempotent, prefix-guarded teardown):
- A seeded repo **`wth-ch01-issues-labels-projects`** with a realistic `README`, a small source tree, and a `.github/ISSUE_TEMPLATE/` directory you will extend.
- **12–15 seeded issues** describing a backlog (bugs, features, chores) — deliberately *untriaged*: no labels, no milestone, no assignee.
- A few **starter labels** only (`bug`, `enhancement`) so you can feel the gap and design the rest.
- An **empty Projects (v2) board** `wth-ch01-board` linked to the repo, with no custom fields yet.
- A printed **Next steps** block telling you where to start.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch01 --org <org> --yes` removes only `wth-ch01-*` artifacts (the repo and the project).

## Tasks

### Part A — Issues & issue hygiene
1. **Read the backlog.** Open the repo's **Issues** tab and skim every seeded issue. Note that none are labeled, assigned, or milestoned — this is your raw material.
2. **Add issue forms.** In `.github/ISSUE_TEMPLATE/`, add a **bug report** form and a **feature request** form using GitHub's **issue forms** (`.yml`) schema (not plain markdown). Each form must collect a title, a structured body, and at least one dropdown (e.g., area or severity). Open the **New issue** chooser and confirm both forms render.
3. **File one issue through your new form** to prove it works. Use a task list (`- [ ]`) in the body with at least three sub-tasks, and reference another issue with `#<number>` so the timeline cross-links.
4. **Triage assignment.** Assign yourself to at least 5 issues. Use `gh issue edit <n> --add-assignee @me` to do it in bulk where that's faster than clicking.

### Part B — Label taxonomy
5. **Design a label scheme.** Create labels across four dimensions, each with a distinct color family:
   - `type:` → `type: bug`, `type: feature`, `type: chore`, `type: docs`
   - `priority:` → `priority: p0`, `priority: p1`, `priority: p2`
   - `area:` → `area: frontend`, `area: backend`, `area: ci`
   - `status:` → `status: needs-triage`, `status: blocked`, `status: in-review`

   Create them via the UI **or** the CLI, e.g.:
   ```bash
   gh label create "type: bug" --color B60205 --description "Defect in existing behavior"
   ```
6. **Apply labels to the whole backlog.** Every seeded issue must end with at least a `type:` and a `priority:` label:
   ```bash
   gh issue edit <n> --add-label "type: bug,priority: p1"
   ```
7. **Prove consistency.** Run `gh issue list --label "priority: p0"` and confirm the highest-priority items surface correctly.

### Part C — Milestones
8. **Create two milestones:** `Sprint 1` (due 2026-06-15) and `Sprint 2` (due 2026-06-29) — via the UI or `gh api repos/<org>/wth-ch01-issues-labels-projects/milestones -f title='Sprint 1' -f due_on='2026-06-15T00:00:00Z'`.
9. **Assign issues to milestones** so each sprint has a realistic, finite scope (4–6 issues each). Open a milestone and confirm the **progress bar** reflects open/closed counts.

### Part D — Projects (v2) board
10. **Add custom fields** to `wth-ch01-board`:
    - a **single-select** `Status` field (`Todo`, `In Progress`, `In Review`, `Done`)
    - a **single-select** `Priority` field (`P0`, `P1`, `P2`)
    - an **Iteration** field with two iterations matching your milestones
    - a **number** field `Estimate`
11. **Add all backlog issues to the board** (`gh project item-add <project-number> --owner <org> --url <issue-url>`), then set `Status` and `Priority` for each item.
12. **Create three saved views:** a **Board** view grouped by `Status`, a **Table** view grouped by `Priority`, and a **Roadmap** view laid out on the `Iteration` field.
13. **Turn on built-in workflows.** In the project's **Workflows** settings, enable:
    - *Item added to project* → set `Status = Todo`
    - *Item closed* → set `Status = Done`

    Then close one issue and confirm the board moves it to **Done** automatically.
14. **Add an insight chart.** In the project's **Insights**, create a chart that counts open items grouped by `Priority`, and save it.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] The repo has **two working issue forms** under `.github/ISSUE_TEMPLATE/` and both appear in the New-issue chooser.
- [ ] **Every** seeded issue carries at least a `type:` and a `priority:` label (verifiable: `gh issue list --json number,labels` shows no issue with fewer than 2 labels).
- [ ] At least **13 distinct labels** exist following the `dimension: value` convention.
- [ ] **Two milestones** exist with due dates and a non-zero set of assigned issues each.
- [ ] The **Projects (v2)** board has the four custom fields, all backlog issues added, and **three saved views** (board / table / roadmap).
- [ ] A **built-in workflow** is enabled and demonstrably moved a closed issue to `Done`.
- [ ] An **Insights chart** grouped by `Priority` is saved on the project.
- [ ] Coach conversation — what real work item or backlog from your team would you model differently now that you understand GitHub's label taxonomy and Projects v2 automation, and what field or view are you missing today? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Add a **third issue form** for "incident" with a required severity dropdown, and a `status: blocked` label that comments on the issue when applied.
- Use the **GraphQL API** to bulk-set the `Estimate` field on every project item in a single scripted pass (`gh api graphql -f query=…`).
- Add a project automation that **auto-archives** `Done` items older than 14 days.

## Reference links
- About issues — https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues
- Configuring issue templates (issue forms) — https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- Managing labels — https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels
- About milestones — https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones
- About Projects — https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects
- Automating Projects using the API — https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
- `gh issue` / `gh project` CLI manual — https://cli.github.com/manual/gh_issue
