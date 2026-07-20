# Ch22 — Connect Azure Boards to GitHub — Coach Guide

> Audience: facilitators and graders. Pair with the delivery team member `README.md`.

## Grounding conversation (you will be called)

**Required coach check-in:** before completion, ask the customer practitioner to connect the exercise to a real migration wave.

**Their question:** Coach conversation — identify one migrated team that still plans in Azure Boards: which repositories must be connected first, who owns the GitHub app installation approval, and what evidence proves traceability survived cutover? Talk it through with your coach.

Use these follow-ups to steer the conversation:
- Which Azure Boards project remains the system of record after the repository moves to GitHub?
- Who can approve the Azure Boards GitHub App in the GitHub org, especially in an EMU-managed enterprise?
- What screenshots or audit evidence would convince a release manager that work-item-to-code traceability is working after cutover?

## Facilitation notes
- **Goal in one line:** the delivery team member wires the live Azure Boards-GitHub integration so post-migration commits and PRs in GitHub keep linking back to Azure Boards work items.
- **Why now:** GEI migrates Git source, PRs, and existing work-item links on PRs from Azure DevOps, but it does not migrate Azure Boards work items. This activity is the post-migration bridge for teams that keep planning in Azure Boards.
- **Preferred artifact:** a real migrated repository and a real, low-risk Azure Boards work item. A disposable work item is acceptable if the production project cannot be changed during the workshop.
- **Evidence standard:** verify both sides. Azure Boards should show GitHub artifacts in the work item's **Development** section, and the GitHub PR should show the Azure Boards work item when `AB#` is present in the PR description.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Setup / permissions check | ~20 min |
| Install Azure Boards app | ~20 min |
| Connect Azure Boards project to repo | ~20 min |
| Commit + PR linking validation | ~35 min |
| State transition validation | ~15 min |
| Wrap-up / debrief | ~10 min |
| **Total** | ~120 min |

## Expected Outputs

When a delivery team member completes this activity successfully, you should see:

- The **Azure Boards** GitHub App installed in the target GitHub org with repository access that includes the migrated repo.
- Azure DevOps **Project settings > GitHub connections** listing the GitHub organization and migrated repository.
- A GitHub commit created with an `AB#<id>` mention and visible as a link on the Azure Boards work item.
- A GitHub pull request whose description includes `Fixes AB#<id>` and is visible from the work item's **Development** section.
- The GitHub PR **Development** section showing the linked Azure Boards work item.
- After PR merge to the default branch, the work item is transitioned to the expected Resolved/Completed workflow-category state, or the delivery team member can explain the project-specific state mapping.
- A concise operating note naming who approves future app installation/repository access requests.

## Common Pitfalls

### GitHub App policy or EMU policy blocks installation
**Symptom:** The customer practitioner sees an app approval request instead of completing installation, or the repository is unavailable when configuring the app.
**Fix:** Have an org owner approve the Azure Boards app for selected repositories. In EMU environments, confirm enterprise and org GitHub App policies before the workshop.

### Repository connected to the wrong Azure DevOps organization
**Symptom:** `AB#` links resolve unexpectedly, link to a different project, or do not resolve consistently.
**Fix:** Microsoft Learn recommends connecting a GitHub repo to projects in a single Azure DevOps organization. Remove stale connections from **Project settings > GitHub connections**, then reconnect the repo to the intended project.

### `AB#` syntax is malformed or placed in the wrong field
**Symptom:** The PR exists, but no work-item link appears in Azure Boards.
**Fix:** Use `AB#123` exactly. For PRs, put the mention in the PR **description**; title-only mentions do not create the Azure Boards work-item link. Commit messages can also create links.

### Missing repository access on the app installation
**Symptom:** Azure Boards connection succeeds for other repos, but the migrated repo is missing.
**Fix:** In GitHub, open **Installed GitHub Apps > Azure Boards > Configure** and add the repository under **Repository access**.

### PR merge does not transition the work item
**Symptom:** The link appears, but state does not change after merge.
**Fix:** Confirm the PR merged into the default branch and used `fix`, `fixes`, or `fixed` before the `AB#` mention, or used an exact valid state name such as `Closed AB#123`. If the process template lacks a Resolved state category, Azure Boards falls back to Completed; if no matching state exists, no transition occurs.

## Progressive Hints

Use these in order — give the first hint, wait, then give the next only if the delivery team member is still stuck.

1. **Hint 1 (gentle):** Start from the connection, not the syntax. Can Azure DevOps **Project settings > GitHub connections** see the exact GitHub repo you are testing?
2. **Hint 2 (medium):** Check where the `AB#` mention lives. A PR title is not enough; put `AB#123` or `Fixes AB#123` in the PR description, or put `AB#123` in a commit message.
3. **Hint 3 (specific):** Open GitHub **Installed GitHub Apps > Azure Boards > Configure** and verify the app has access to this repository. Then remove duplicate Azure DevOps project/org connections before retrying with a fresh PR description containing `Fixes AB#<id>`.

## Debrief Questions

Ask these after the activity to reinforce learning:

- What did GEI preserve from Azure DevOps PR metadata, and what did it intentionally not migrate from Azure Boards?
- Which teams in your migration plan will keep Azure Boards after cutover, and which will move planning into GitHub Issues or Projects?
- What is your minimum evidence pack for traceability: app installation, Azure DevOps connection, work-item Development links, GitHub PR Development links, and state transition screenshot?
- How will you govern repository access changes to the Azure Boards app as additional repos migrate?

## Grading rubric (point-weighted, 100 pts)

| Criterion | Points | What "full marks" looks like |
|---|---:|---|
| Migration rationale | 15 | Delivery team member correctly explains that GEI migrates existing PR work-item links but not Azure Boards work items/backlogs. |
| App installation | 20 | Azure Boards GitHub App installed or approved for the selected org/repo with least-broad practical repository access. |
| Azure Boards connection | 20 | Azure DevOps project lists the migrated GitHub repo in **Project settings > GitHub connections**. |
| Link validation | 20 | Commit or PR with `AB#<id>` appears in the Azure Boards work item's **Development** section. |
| State transition | 15 | Merged PR with `Fixes AB#<id>` transitions the work item as expected, or state mapping is accurately explained. |
| Troubleshooting and operating model | 10 | Delivery team member can explain wrong-org, syntax, permissions, and EMU policy failure modes and name the app approval owner. |
| **Total** | **100** | |

## Verification hints

There is no single reliable CLI-only verification because the Azure Boards connection and work-item Development control are UI-backed. Use these checks:

```bash
ORG=<github-org>; REPO=<migrated-repo>

# Confirm the validation PR exists and contains the AB# mention in the body.
gh pr list --repo "$ORG/$REPO" --state all --search "AB#" --json number,title,state,mergedAt,url

# Inspect a specific PR body and merge state.
gh pr view <pr-number> --repo "$ORG/$REPO" --json title,body,state,mergedAt,url
```

Coach should also visually verify:
- GitHub org **Settings > GitHub Apps** or app configuration page shows **Azure Boards** installed for the repo.
- Azure DevOps **Project settings > GitHub connections** lists the repo.
- Azure Boards work item **Development** section lists the GitHub commit/PR.
- GitHub PR **Development** section lists the Azure Boards work item.
- Work item state after merge matches the process template's Resolved/Completed behavior.

## Useful references for coaching

- Azure Boards Integration With GitHub — https://learn.microsoft.com/en-us/azure/devops/boards/github/?view=azure-devops
- Install the Azure Boards App for GitHub — https://learn.microsoft.com/en-us/azure/devops/boards/github/install-github-app?view=azure-devops
- Connect an Azure Boards project to a GitHub repository — https://learn.microsoft.com/en-us/azure/devops/boards/github/connect-to-github?view=azure-devops
- Link GitHub commits, PRs, branches, and issues to work items — https://learn.microsoft.com/en-us/azure/devops/boards/github/link-to-from-github?view=azure-devops
- Internal migration research report, section 4 — `/home/marco/.copilot/session-state/58bb295a-c8c1-42e1-b6f2-898549a9f8b8/research/all-migration-patterns-supported-to-github-enterpr.md`

## Teardown

For production migrations, do not tear down the connection. For workshop-only validation:

1. In Azure DevOps, open **Project settings > GitHub connections**.
2. Select the connection **More options** menu and choose **Remove repositories** for only the test repo, or **Remove connection** if the entire connection was temporary.
3. In GitHub, open **Settings > Applications > Installed GitHub Apps > Azure Boards > Configure** and remove repository access if no longer needed.
4. Leave the linked work item intact if it is useful audit evidence; otherwise close or tag it according to the team's Boards hygiene process.
