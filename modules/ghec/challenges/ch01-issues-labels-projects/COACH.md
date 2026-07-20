# Ch01 — Issues, Labels & Project Boards — Delivery Assurance Guide

> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


## Customer adoption decision

Required delivery assurance check: before implementation is accepted, confirm the authorized tenant scope, implementation evidence, risk controls, accountable owner, handover, and next adoption action.

Decision prompt: what real work item or backlog from your team would you model differently now that you understand GitHub's label taxonomy and Projects v2 automation, and what field or view are you missing today? Record the accountable owner, implementation evidence, risk or blocker, and next customer adoption action.

> Customer implementation preference: prioritize an authorized customer tenant or artifact over the `ghec-ch01-issues-labels-projects` sample. If a sample is necessary, record the target tenant scope, accountable owner, authorization blocker, evidence to carry forward, and the adoption, cutover, or rollout decision. The sample is a safe fallback, not the destination.

Use these prompts to verify customer ownership and the next action:
- Walk me through one specific project or repo your team tracks work in — what labels exist there today?
- Where does triage break down or slow things down in that project? Could a custom field, saved view, or label rule fix it?
- What is the ONE label, field, or automation rule you'll add to that board next week?

## Delivery assurance notes
- Customer adoption outcome: the customer implementation owner turns a raw, untriaged backlog into a governed system — labeled, milestoned, and tracked on a Projects (v2) board with working automation.
- Implementation risks to verify:
  - Issue *forms* vs issue *templates*. Many customer implementation owners write a markdown template and miss that forms are YAML with typed inputs. Point them at the issue-forms schema.
  - Projects (v2) is org-level, not the old repo "Projects" tab. Some create a classic project. Make sure they create a Projects (v2) board and link the repo.
  - Built-in workflows are under the project's "⚙ Workflows" — easy to miss. The auto-move only fires on *new* events, so they must close an issue *after* enabling.
- Delivery lead prompts: ask "what typed input would stop a reporter from forgetting the severity?" (→ dropdown), and "where would a new item's status get set without you clicking?" (→ workflows).
- Org-scoped note: this activity runs with just an org + org-owner token; no enterprise owner needed. Projects (v2) lives at org scope, which is why `project` token scope is required.

## Implementation acceptance evidence
| Criterion | Assurance weight | Customer-owned evidence |
|---|---:|---|
| Issue management (forms + task lists + assignees) | 20 | Two valid issue forms render; a new issue filed through one; task list + cross-reference present; ≥5 issues assigned |
| Label taxonomy | 25 | ≥13 labels in `dimension: value` form; every backlog issue has ≥ `type:` and `priority:` |
| Milestones | 15 | Two milestones with due dates; 4–6 issues each; progress bars populated |
| Projects (v2) board + fields + views | 25 | Four custom fields; all issues added; three saved views (board/table/roadmap) |
| Automation + insights | 15 | A built-in workflow demonstrably moved a closed issue to Done; an insight chart grouped by Priority saved |
| Assurance coverage | 100 | |

## Implementation verification evidence
Use these to verify the customer implementation evidence (prefer `gh` CLI / API over manual clicks):
```bash
ORG=<org>; REPO=ghec-ch01-issues-labels-projects   # swap REPO for the customer implementation owner's own repo if they brought one

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
- Issue forms: the `contents` call should return at least two `.yml` files. Markdown-only templates → not complete implementation evidence.
- Labels: `wc -l` ≥ 13 *and* the name list shows the four dimensions. Flat labels (`bug`, `p0`) without the `dimension: value` shape → partial credit.
- Automation: ask the customer implementation owner to show the closed issue now sitting in the project's `Done` column; confirm via `item-list` that its `Status` field reads `Done`.

## Common pitfalls
- Classic Projects vs Projects v2. If `gh project list` shows nothing, they likely built a classic board or a user-scoped project. Re-create at org scope.
- Token missing `project` scope. Field/item API calls 403. Fix: re-auth with `gh auth refresh -s project,read:org`.
- Workflow enabled but didn't fire. Built-in workflows only act on events after they're turned on — close a *fresh* issue to demonstrate.
- Label color must be a 6-hex string without `#` when using `gh label create --color`.

## References for delivery leads

- [About issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues), [Configuring issue templates (issue forms)](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository).

## Teardown
```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh teardown ch01 --org <org> --yes   # Bash
modules/ghec/resources/provisioning/scripts/setup.ps1 teardown ch01 --org <org> --yes  # PowerShell
```
- Removes only `ghec-ch01-*` artifacts (prefix-guarded): the repo and the linked Projects (v2) board.
- Manual cleanup (if any): none. Everything created lives under the `ghec-ch01-*` namespace.

## Time budget
- Setup + read backlog: ~30 min
- Parts A–B (issues + labels): ~1 hr
- Part C (milestones): ~20 min
- Part D (project board + automation): ~1.5 hrs
- Stretch: ~45 min
- Indicative implementation effort: ~3–4 hrs across sessions.
