# Ch01: Issues, labels and project boards

**Session outcome:** The customer backlog has a working issue form and a small Projects board. One issue is ready for Ch02, and closing an issue updates the board.

## Prerequisites
- Write access to the Ch00 repository and permission to edit its project. Only the optional organization defaults need an owner.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch01 --org <org>` (least-privilege; for this activity: `repo` + `project` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS, Codespaces, or enterprise features are required for this activity.

## What you will deliver
- Create, triage, and close issues using templates (issue forms), assignees, and task lists.
- Use type labels and record priority and status in one place.
- Build one Projects board and verify its built-in closed-issue workflow.
- When several repositories share a backlog, reconcile their labels.

## Scenario
You manage the backlog for an internal developer-tools team at a GHEC customer. Requests are scattered across chat threads and spreadsheets. Leadership wants every request recorded as an issue and triaged within a day. Configure a GitHub board that shows work in progress, blockers, and planned deliveries for the sprint.

> [!IMPORTANT]
> Use an approved customer target first. If you have a candidate backlog and board, use it everywhere this guide says `ghec-ch01-issues-labels-projects` or `ghec-ch01-board` and skip Setup. Otherwise use the fallback seeded repo below for testing, then move the validated configuration to an approved customer target.
>
> Record the selected target, adoption owner, and next action.

## Sample test repository or environment
Skip if you brought your own repo or project board.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch01 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch01 --org <org>
```

Setup creates these resources (all names use the `ghec-ch01-*` prefix, and teardown is prefix-guarded):
- A seeded repo `ghec-ch01-issues-labels-projects` with a realistic `README`, a small source tree, and a `.github/ISSUE_TEMPLATE/` directory you will extend.
- ~26 seeded backlog issues (bugs, features, chores) with inconsistent or missing labels, no milestone, and no assignee.
- An incomplete label set: `bug`, `Bug`, `enhancement`, `urgent`, `wontfix`, `question`, `backend`, `frontend`. Note the duplicate `bug`/`Bug` casing.
- An empty Projects (v2) board `ghec-ch01-board` linked to the repo, with no custom fields yet.
- A printed Next steps block telling you where to start.

## Tasks
> `ghec-ch01-issues-labels-projects` is the fallback sample name; substitute your own artifact's name if you brought one.

### Part A: Make one issue ready

1. Reuse the repository selected in Ch00. Choose three real backlog items; do not triage every sample issue.
2. Add one issue form under `.github/ISSUE_TEMPLATE/` with a description and expected result. Merge it through the team's review process, then file an issue to test the form.
3. Assign the issue and describe a small, testable change for Ch02. For feature feedback, link the original request and name who decides whether to accept it. Use existing `bug` or `type: bug` labels consistently. Add a separate label scheme only if reporting needs it.

### Part B: Track the work once

4. Add the selected issues to one Projects board. Reuse its Status field and add Priority only if the team needs it. Do not duplicate status in labels or iteration dates in milestones.
5. Save a board grouped by Status. Enable *Item added to project → Todo* and *Item closed → Done*.
6. Close a completed test issue and verify it moves to Done. Keep the Ch02 issue open and link the board from it.

### Optional: Shared labels across repositories

7. For a multi-repository backlog, export labels from the customer repository and one other approved repository:
   ```bash
   gh label list --repo <org>/<repo> --limit 200 --json name,color,description
   ```
8. Agree on a small shared set with its maintainer. Rename existing labels where possible. Before deleting an old label, apply its replacement to affected issues and PRs. Check a filtered issue list on both repositories.
9. With organization-owner approval, configure those labels in **Organization settings → Repository → Repository defaults**. New defaults do not update existing repositories.
10. Create one approved private test repository after the change. Verify its labels without copying them manually. Ask the owner whether to keep or remove that repository. Record who owns the defaults and the results from both repositories.

Keep the issue and board URLs as [completion evidence](../../../README.md#completion-evidence). Sample configuration alone is practice.

## Reference links
- [About issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues)
- [Configuring issue templates (issue forms)](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels)
- [About milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones)
- [About Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects)
- [Automating Projects using the API](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [`gh issue` / `gh project` CLI manual](https://cli.github.com/manual/gh_issue)
