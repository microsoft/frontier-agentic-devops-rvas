# Ch22 — Connect Azure Boards to GitHub

> By the end of this challenge you can restore post-migration traceability between Azure Boards work items and GitHub code activity by installing the Azure Boards GitHub App, connecting a migrated repository, and proving `AB#` links and PR-driven state transitions work.

| | |
|---|---|
| **Track** | Migration |
| **Difficulty** | Intermediate *(post-migration bridge)* |
| **Duration** | ~2 hrs |
| **Minimum input** | A GitHub org/repo you administer, an Azure DevOps Services org/project, and permission to install a GitHub Marketplace app. |
| **App** | None |
| **EMU compatible** | yes, if your enterprise/org policy permits GitHub App installation or an org owner approves the request |

## Prerequisites
- GitHub organization with org-owner rights, or repository admin rights plus a path to request GitHub App installation approval.
- An Azure DevOps Services organization with an Azure Boards project and at least one work item you can edit.
- Project Collection Administrator rights in Azure DevOps, or a project administrator who can create the GitHub connection.
- A migrated GitHub repository that represents code formerly tracked in Azure DevOps.
- Local tooling for the validation path: `git` and `gh` authenticated to the target GitHub org.

**Recommended sequence:** do this after the migration planning/cutover challenge for Azure DevOps-to-GitHub migrations, because this challenge assumes the repository now lives in GitHub and Azure Boards remains the system of record for work items.

## Scenario objectives
By completing this challenge you will:
- Explain why GitHub Enterprise Importer (GEI) does not migrate Azure Boards work items: it migrates Git repos, PRs, and existing work-item links on PRs, but not the Boards backlog itself.
- Install and configure the **Azure Boards** GitHub Marketplace app for selected migrated repositories.
- Connect one Azure Boards project to the GitHub repository from **Project settings > GitHub connections**.
- Link GitHub commits and pull requests to work items using `AB#<id>`.
- Demonstrate that a merged PR can transition a linked work item when the PR description or commit message uses a supported phrase such as `Fixes AB#<id>`.
- Validate the link from both sides: Azure Boards work item **Development** section and GitHub PR **Development** section.

## Why this matters
GEI preserves only work-item links that already existed on Azure DevOps pull requests. It does **not** move Azure Boards work items, board columns, queries, or backlog state into GitHub. After cutover, teams that keep planning in Azure Boards need a live bridge so new GitHub commits and pull requests continue to appear on the work item. The Azure Boards GitHub App is that bridge.

## Bring your own outcome (do this first)
Pick one migrated repository and one Azure Boards work item from a real team. The challenge is complete only when that real repository is connected and a real work item shows a GitHub commit or PR link.

Use these variables in the commands below:

```bash
ORG=<github-org>
REPO=<migrated-repo>
WORK_ITEM_ID=<azure-boards-work-item-id>
```

## Tasks

### Part A — Install the Azure Boards GitHub App
1. Open the Azure Boards app in GitHub Marketplace: <https://github.com/marketplace/azure-boards>.
2. Under **Plans and pricing**, choose the **Free** plan and select **Install**.
3. In **Install & Authorize Azure Boards**, choose your GitHub organization.
4. Select **Only select repositories** and choose the migrated repo you will validate, or choose **All repositories** only if your migration governance allows broad app access.
5. Select **Install & Authorize**.
6. If your org uses Enterprise Managed Users or restricts GitHub App installation, capture the approval request URL/screenshot and ask an org owner to approve the **Azure Boards** app for the selected repository.

### Part B — Connect the Azure Boards project
1. In Azure DevOps, open `https://dev.azure.com/<ado-org>/<project>`.
2. Go to **Project settings > GitHub connections**.
3. For a first connection, select **Connect your GitHub account**. For a later connection, select **New connection**.
4. Authenticate with the GitHub account that administers the repository, then select the GitHub organization.
5. In **Add GitHub Repositories**, select the migrated repository and choose **Save**.
6. On the GitHub approval page, select **Approve, Install, & Authorize** if prompted.
7. Confirm the connection list shows the GitHub organization and repository under **Project settings > GitHub connections**.

> Avoid connecting the same GitHub repository to more than one Azure DevOps organization or project. Microsoft Learn warns this can cause unexpected `AB#` mention linking.

### Part C — Link a commit to a work item
1. Clone the migrated repository and create a branch.

```bash
gh repo clone "$ORG/$REPO"
cd "$REPO"
git switch -c boards-link-validation
```

2. Make a harmless documentation change that can be merged or reverted later.

```bash
printf '\nAzure Boards traceability validation for AB#%s\n' "$WORK_ITEM_ID" >> traceability-proof.md
git add traceability-proof.md
git commit -m "Link GitHub commit to AB#$WORK_ITEM_ID"
git push -u origin boards-link-validation
```

3. Open the Azure Boards work item. In the **Development** section, confirm a GitHub commit link appears. If it does not appear after a short delay, continue to troubleshooting before opening the PR.

### Part D — Link and merge a pull request
1. Create a pull request whose **description** contains the `AB#` mention. Microsoft Learn specifies that `AB#<id>` in a PR description creates the work-item link; a PR title alone does not create the Azure Boards work-item link.

```bash
gh pr create \
  --repo "$ORG/$REPO" \
  --base main \
  --head boards-link-validation \
  --title "Validate Azure Boards traceability" \
  --body "Validates migrated repo traceability. Fixes AB#$WORK_ITEM_ID"
```

2. Open the PR in GitHub. Confirm the PR **Development** section shows the linked Azure Boards work item.
3. Open the work item in Azure Boards. Confirm the **Development** section shows the GitHub PR link.
4. Merge the PR into the default branch.

```bash
gh pr merge --repo "$ORG/$REPO" --squash --delete-branch
```

5. Return to the work item and refresh. A phrase such as `Fixes AB#<id>` transitions the work item to the first state in the **Resolved** workflow category, or if none exists, the first state in the **Completed** category. State transitions apply when the PR is merged into the default branch.

### Part E — Validate and document the operating model
Capture evidence for the migration runbook:
- GitHub App installation page showing **Azure Boards** installed for the selected repository.
- Azure DevOps **Project settings > GitHub connections** showing the connected repo.
- Azure Boards work item **Development** section showing the GitHub commit and PR.
- GitHub PR **Development** section showing the Azure Boards work item.
- The work item state before and after PR merge, or a note explaining why the process template uses a different target state.
- The owner who can approve future GitHub App repository access changes.

## Troubleshooting

### App installed but Azure Boards cannot see the repo
Check GitHub **Organization settings > GitHub Apps** or personal **Settings > Applications > Installed GitHub Apps > Azure Boards > Configure**. Ensure repository access includes the migrated repo. If third-party application access or EMU app-install policy blocks the app, request approval from an org owner.

### `AB#` does not create a link
Use `AB#123`, not `AB-123`, `ADO#123`, or a URL-only reference. Put the `AB#` mention in the commit message or PR description. For GitHub PRs, the PR title alone is not enough to create the Azure Boards work-item link.

### Links go to the wrong Azure DevOps org or project
A GitHub repository should be connected to only one Azure DevOps organization/project. Remove stale connections from **Project settings > GitHub connections**, then reconnect the repo to the intended Boards project.

### PR merge did not transition the work item
Confirm the PR merged into the default branch and used a supported phrase such as `Fixes AB#123`, `Fixed AB#123`, or a valid state name such as `Closed AB#123`. If the process template has no matching state/category, Azure Boards can link without changing state.

### Permissions error during installation
The Azure Boards app requires a GitHub organization owner/admin for installation and repository access changes. In EMU environments, enterprise policy can require app approval. Capture the GitHub approval request and route it through your org-owner process.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] The **Azure Boards** GitHub Marketplace app is installed for the GitHub organization and the migrated repository is selected.
- [ ] Azure DevOps **Project settings > GitHub connections** lists the migrated GitHub repository.
- [ ] A commit or PR using `AB#<work-item-id>` created a visible link in the Azure Boards work item's **Development** section.
- [ ] A PR description containing `Fixes AB#<work-item-id>` was merged into the default branch and transitioned the linked work item to the expected Resolved/Completed workflow-category state, or you documented why the process template maps differently.
- [ ] The GitHub PR **Development** section shows the linked Azure Boards work item.
- [ ] You can explain how to troubleshoot wrong-org connections, missing app permissions, malformed `AB#` mentions, and EMU app-install policy blocks.
- [ ] Coach conversation — identify one migrated team that still plans in Azure Boards: which repositories must be connected first, who owns the GitHub app installation approval, and what evidence proves traceability survived cutover? Talk it through with your coach.

## Cleanup
Keep the connection if this is a production migration bridge. If you used a disposable test repository, remove the connection from Azure DevOps **Project settings > GitHub connections > More options > Remove repositories** or remove the app repository access from GitHub **Installed GitHub Apps > Azure Boards > Configure**.

## Reference links
- Azure Boards Integration With GitHub — https://learn.microsoft.com/en-us/azure/devops/boards/github/?view=azure-devops
- Install the Azure Boards App for GitHub — https://learn.microsoft.com/en-us/azure/devops/boards/github/install-github-app?view=azure-devops
- Connect an Azure Boards project to a GitHub repository — https://learn.microsoft.com/en-us/azure/devops/boards/github/connect-to-github?view=azure-devops
- Link GitHub commits, PRs, branches, and issues to work items — https://learn.microsoft.com/en-us/azure/devops/boards/github/link-to-from-github?view=azure-devops
- Internal migration research report, section 4 — `/home/marco/.copilot/session-state/58bb295a-c8c1-42e1-b6f2-898549a9f8b8/research/all-migration-patterns-supported-to-github-enterpr.md`
