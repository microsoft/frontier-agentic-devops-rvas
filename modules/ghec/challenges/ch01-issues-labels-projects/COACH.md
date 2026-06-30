# Ch01 — Issues, Labels & Project Boards — Coach Guide

> Audience: facilitators and graders. Pair with the student `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the learner to connect the exercise to work they actually own.

**Their question:** Coach conversation — what real work item or backlog from your team would you model differently now that you understand GitHub's label taxonomy and Projects v2 automation, and what field or view are you missing today? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> **Bring-your-own grading:** prefer students who ran this on a **real artifact they own** over the `wth-ch01-issues-labels-projects` sample. If they used the sample, confirm they can name the actual repo, team, project, or workflow they'll apply this to and any blockers. The lasting outcome is the goal; the sample is fallback.

Use these follow-ups to steer the conversation:
- Walk me through one specific project or repo your team tracks work in — what labels exist there today?
- Where does triage break down or slow things down in that project? Could a custom field, saved view, or label rule fix it?
- What is the ONE label, field, or automation rule you'll add to that board next week?

## Facilitation notes
- **Goal in one line:** the student turns a raw, untriaged backlog into a governed system — labeled, milestoned, and tracked on a Projects (v2) board with working automation.
- **Where students get stuck:**
  - **Issue *forms* vs issue *templates*.** Many students write a markdown template and miss that forms are YAML with typed inputs. Point them at the issue-forms schema.
  - **Projects (v2) is org-level, not the old repo "Projects" tab.** Some create a classic project. Make sure they create a **Projects (v2)** board and link the repo.
  - **Built-in workflows** are under the project's "⚙ Workflows" — easy to miss. The auto-move only fires on *new* events, so they must close an issue *after* enabling.
- **How to unblock without giving the answer:** ask "what typed input would stop a reporter from forgetting the severity?" (→ dropdown), and "where would a new item's status get set without you clicking?" (→ workflows).
- **Org-scoped note:** this challenge runs with just an org + org-owner token; no enterprise owner needed. Projects (v2) lives at org scope, which is why `project` token scope is required.

## Grading rubric (point-weighted, 100 pts)
| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Issue hygiene (forms + task lists + assignees) | 20 | Two valid issue forms render; a new issue filed through one; task list + cross-reference present; ≥5 issues assigned |
| Label taxonomy | 25 | ≥13 labels in `dimension: value` form; every backlog issue has ≥ `type:` and `priority:` |
| Milestones | 15 | Two milestones with due dates; 4–6 issues each; progress bars populated |
| Projects (v2) board + fields + views | 25 | Four custom fields; all issues added; three saved views (board/table/roadmap) |
| Automation + insights | 15 | A built-in workflow demonstrably moved a closed issue to Done; an insight chart grouped by Priority saved |
| **Total** | **100** | |

## Automated verification hints
Use these to check Definition of Done quickly (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>; REPO=wth-ch01-issues-labels-projects   # swap REPO for the student's own repo if they brought one

# Repo exists and issue forms are present
gh repo view $ORG/$REPO --json name,visibility
gh api repos/$ORG/$REPO/contents/.github/ISSUE_TEMPLATE --jq '.[].name'

# Label count + naming convention (expect >= 13, dimensioned)
gh label list --repo $ORG/$REPO | wc -l
gh api repos/$ORG/$REPO/labels --paginate --jq '.[].name'

# No issue should have fewer than 2 labels
gh issue list --repo $ORG/$REPO --state all --json number,labels \
  --jq '.[] | select((.labels|length) < 2) | .number'   # expect EMPTY output

# Milestones with due dates
gh api repos/$ORG/$REPO/milestones --jq '.[] | {title, due_on, open_issues, closed_issues}'

# Projects (v2): list org projects and inspect fields
gh project list --owner $ORG
gh project field-list <project-number> --owner $ORG
gh project item-list <project-number> --owner $ORG --format json --jq '.items | length'
```
- **Issue forms:** the `contents` call should return at least two `.yml` files. Markdown-only templates → not full marks.
- **Labels:** `wc -l` ≥ 13 *and* the name list shows the four dimensions. Flat labels (`bug`, `p0`) without the `dimension: value` shape → partial credit.
- **Automation:** ask the student to show the closed issue now sitting in the project's `Done` column; confirm via `item-list` that its `Status` field reads `Done`.

## Common pitfalls
- **Classic Projects vs Projects v2.** If `gh project list` shows nothing, they likely built a classic board or a user-scoped project. Re-create at org scope.
- **Token missing `project` scope.** Field/item API calls 403. Fix: re-auth with `gh auth refresh -s project,read:org`.
- **Workflow enabled but didn't fire.** Built-in workflows only act on events after they're turned on — close a *fresh* issue to demonstrate.
- **Label color must be a 6-hex string without `#`** when using `gh label create --color`.

## Useful references for coaching

- [About issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues), [Configuring issue templates (issue forms)](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch01 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch01 --org <org> --yes  # PowerShell
```
- Removes only `wth-ch01-*` artifacts (prefix-guarded): the repo and the linked Projects (v2) board.
- **Manual cleanup (if any):** none. Everything created lives under the `wth-ch01-*` namespace.

## Time budget
- Setup + read backlog: ~30 min
- Parts A–B (issues + labels): ~1 hr
- Part C (milestones): ~20 min
- Part D (project board + automation): ~1.5 hrs
- Stretch: ~45 min
- **Total facilitated:** ~3–4 hrs across sessions.
