# Ch36: Controlled repository intake

**Session outcome:** A member requests a repository for their own approved team. After an authorized maintainer approves it, a GitHub App creates an Internal repository named `<team-slug>-<service-name>` and grants that team Write access. Ordinary members cannot create repositories outside this route.

## Prerequisites

Complete Ch38 first. Bring its template commit and actual required CI check names, an existing intake repository, and an organization owner. This starter targets GitHub Enterprise Cloud on GitHub.com.

The organization must support **repository policies**, currently in public preview. Internal repositories are readable by enterprise members; Write access goes to the owning team. Choose an intake maintainer team with Maintain or Admin access to the intake repository.

**Do not disable all creation under Member privileges.** That blanket setting blocks GitHub Apps too. Use an active repository policy to deny ordinary users and allow the provisioning App. Enterprise restrictions still apply; a policy exception cannot override a stricter enterprise policy.

## Tasks

### Part A: Register the provisioning App

An organization owner registers an organization-owned GitHub App:

1. Disable webhooks. Actions will handle request events.
2. Grant repository **Administration: Read and write** and **Contents: Read-only**, plus organization **Members: Read-only**. Metadata read access is included. No Contents write, Workflows write, or organization administration write permission is needed by the starter.
3. Install it on **All repositories** in the target organization. It must read the template and administer repositories that do not exist yet. Selected-repository installation is insufficient.
4. Generate its private key. Keep it out of Git and local command output. Restrict who can change the App, its installation, and the intake workflow.

The workflow mints a short-lived installation token after approval and revokes it when the job ends. It copies template files through GitHub's API; it never executes application code with this token.

### Part B: Enforce the creation route

With the organization owner:

1. Under **Organization settings → Policies → Repository**, create an **Active** policy targeting **all repositories**, including future ones. Enable **Restrict creation**. Add only the provisioning GitHub App to its allow list, plus organization administrators if the organization needs an owner-operated emergency path. Do not add requester teams, repository roles, or unrelated Apps.
2. Under **Member privileges → Repository creation**, permit **Internal** creation so the App can use it. Disable Public and Private creation unless another approved route needs them. Check enterprise policies do not block the App.
3. Leave the Ch38 organization branch rules active for future repositories. Do not give this App a branch-ruleset bypass.
4. Restrict visibility changes and repository renaming so ordinary members cannot sidestep the approved visibility or name after creation. Keep organization base permissions at Read or lower.
5. As a normal member, attempt direct creation through both the UI and `gh repo create`. Confirm GitHub rejects it, including an otherwise valid team-prefixed name.

The App bypass applies to the creation policy only. Organization owners retain administrative authority; this session does not remove that exception.

If the App is not available in the policy's allow list, or the policy feature is unavailable, **stop**. Do not enable unrestricted member creation or substitute an owner's PAT.

### Part C: Install the form and workflow

From the curriculum checkout:

```bash
export TARGET_CHECKOUT="/path/to/intake-repository"
mkdir -p "$TARGET_CHECKOUT/.github/ISSUE_TEMPLATE" "$TARGET_CHECKOUT/.github/workflows" "$TARGET_CHECKOUT/automation"
cp modules/ghec/resources/intake/repository-request.yml "$TARGET_CHECKOUT/.github/ISSUE_TEMPLATE/"
cp modules/ghec/resources/intake/repository-intake.yml "$TARGET_CHECKOUT/.github/workflows/"
cp modules/ghec/resources/intake/provision.py modules/ghec/resources/intake/config.json "$TARGET_CHECKOUT/automation/"
```

Review existing files before replacing them. In `automation/config.json`, set:

| Field | Value |
|---|---|
| `organization` | The target organization |
| `intake_repository` | Its existing intake repository, as `ORG/REPO` |
| `template_repository` | The Ch38 template, in the same organization |
| `template_commit` | Its reviewed 40-character commit SHA |
| `approved_teams` | Existing team slugs whose members may request repositories |
| `approver_team` | The intake maintainer team's slug |
| `required_checks` | Exact CI check contexts enforced by the Ch38 organization ruleset |

Match the form's **Owning team** options to `approved_teams`. The form asks only for a service name, team, and purpose. Visibility, template, and Write access come from administrator-controlled configuration.

Create the **repository-provisioning** environment in the intake repository:

- Require review by the intake maintainer team. Enable **Prevent self-review** and disable administrator bypass.
- Allow deployment only from the protected default branch.
- Store `PROVISIONER_APP_ID` and `PROVISIONER_PRIVATE_KEY` as **environment secrets**, not repository or organization secrets.

Protect the default branch and require platform-owner review for `.github/workflows/` and `automation/`. Give requesters no write access to the intake repository. Merge the installation through a reviewed PR.

### Part D: Fulfill a request

1. A member of an approved team submits the form, for example team `grubify` and service `orders`. It requests `grubify-orders`.
2. Open the request's run under the intake repository's **Actions → Repository intake** tab. Its **review** job shows the request body hash, resulting name, and pinned template commit before App credentials are available.
3. An independent maintainer checks the request and approves the **repository-provisioning** environment. They must still belong to `approver_team` and have the built-in Maintain or Admin role on the intake repository. Reject the deployment if the request should not proceed.
4. The job rechecks the live issue, requester membership, and GitHub's approval history. It verifies the template still points to the reviewed commit, creates an Internal repository using `cloneTemplateRepository`, and verifies the copied Git tree.
5. It checks inherited PR-review and CI rules, grants the requested team Write, verifies that grant, and comments with the repository URL and numeric ID before closing the request.
6. A team member opens a failing-then-passing application PR. Confirm required CI and independent review block merging until both pass. Adapt CODEOWNERS to the consuming team's ownership through that PR.

Submitting the form starts a waiting workflow; **approval is what permits creation**. If someone edits the request while it waits, the old run fails and the edit starts a new review.

### Part E: Prove the boundaries

Use a fresh service name for each successful test:

| Test | Expected result |
|---|---|
| Approved own-team request | Internal repository with the expected name, template files, and team Write |
| Missing approval or rejected deployment | No repository |
| Approver outside the maintainer team, without Maintain/Admin, or approving their own request | No repository |
| Request for another team, unknown team, or malformed service name | No repository |
| Request edited while waiting | Old approval fails; a new run needs approval |
| Template changed without updating the approved commit | No repository |
| Existing repository with the requested name, or replayed successful run | No new repository and no access changes to the existing one |
| Normal member attempts direct creation | GitHub rejects it |

**A failed run is not fulfillment.** The starter deliberately refuses to adopt existing repositories. If creation succeeds but a later check or team grant fails, leave the request open. The run records the created repository's numeric ID as soon as GitHub returns it.

An organization owner inspects that ID, the template tree, and the failed step before repairing the same repository. If a creation response is lost, creation may have succeeded: inspect the requested name and run time before retrying. Do not delete a repository or reuse an existing name merely to make a run pass. After repair, verify the first PR and close the request with the result.

Keep the successful request and a rejected request as [completion evidence](../../../README.md#completion-evidence). Include the direct-creation denial and first-PR link. Name the operator who handles failed runs.

## References

- [Repository policies and their interaction with member privileges](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/governing-how-people-use-repositories-in-your-organization)
- [Repository creation restrictions](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization)
- [Registering a GitHub App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app)
- [Environment approvals](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment)
- [Workflow approval history](https://docs.github.com/en/rest/actions/workflow-runs#get-the-review-history-for-a-workflow-run)
- [GitHub CLI's Internal template-generation implementation](https://github.com/cli/cli/blob/trunk/pkg/cmd/repo/create/http.go)
