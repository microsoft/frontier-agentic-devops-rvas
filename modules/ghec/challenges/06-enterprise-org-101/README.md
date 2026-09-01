# Ch06 — Enterprise & Organization 101

> Deliver an organisation governance baseline: membership, privileges, repository-creation and visibility policies, security defaults, and API-verifiable evidence.

## Prerequisites
- Recommended: Ch52 (Enterprise Landing Zone & Organization Strategy) completed first — its topology map, delegated-admin model, and settings register are the preferred source for this activity's enterprise-level checks in Part F; otherwise this activity's organization-level baseline stands on its own.
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch06 --org <org>` (least-privilege; for this activity: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `modules/ghec/resources/provisioning/scripts/setup.sh doctor` to verify).
- No GHAS, Codespaces, or enterprise-owner features are required. Every hands-on task in this activity lives at organization scope; enterprise-level items are inspected as evidence, not configured.
- EMU note: Enterprise Managed Users cannot create public repositories. In EMU orgs, setup requests `ghec-ch06-public-sample` as public but GitHub rejects that visibility, so the provisioner falls back to a private repo and prints a warning. The governance lesson still applies: public visibility is platform-blocked, and you verify/document that constraint instead of changing that repo to public.

## What you will deliver
- Read and reason about an organization's member privileges baseline (default repository permission, repo creation, page/visibility, fork policy).
- Configure repository creation, visibility, and deletion/transfer policies for members.
- Manage members vs outside collaborators and understand how each gets access.
- Set organization-wide security defaults (2FA awareness, default workflow permissions, dependency-graph defaults).
- Inspect and verify every setting from the org-settings REST API (`gh api /orgs/<org>`) so configuration is auditable, not just clicked.
- Distinguish the enterprise-level policy decision from this organization's implementation, and record which one you inspected.

## Scenario
You're the first platform admin hired at a fast-growing GHEC customer. The organization was created in a hurry: defaults are wide open, public repo creation may be allowed in standard GHEC or platform-blocked in EMU, base permissions are too generous, and nobody can say what the current policy actually is. Leadership wants a documented, defensible baseline — least-privilege member access, controlled repository creation, sensible security defaults — and they want it verifiable from the API, not from screenshots. Your job is to bring order to the org and prove it.

> [!IMPORTANT]
> Use an approved customer target first. If you have candidate organisation settings and repos, use them wherever this guide names `ghec-ch06-public-sample` or the sibling `ghec-ch06-*` repos, and skip Setup. Otherwise use the fallback seeded repos below, then move the validated proposal to an approved customer organisation.
>
> Record the selected target, organisation owner, risk decision, and next action.

## Sample test repository or environment
Skip if you brought your own org/repo policy target.

```bash
# Bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch06 --org <org>
```
```powershell
# PowerShell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch06 --org <org>
```

Setup creates these resources (all names use the `ghec-ch06-*` prefix, and teardown is prefix-guarded):
- Three seeded repos — `ghec-ch06-public-sample`, `ghec-ch06-private-sample`, and `ghec-ch06-internal-sample` — each with a short `README` so you have real objects to apply visibility/permission policy against. On EMU, `ghec-ch06-public-sample` is expected to fall back to private because public repos are blocked.
- A starter team `ghec-ch06-members` with one of the sample repos attached at the default permission, so you can observe how base permissions flow.
- A printed current baseline snapshot (the org's existing member-privilege settings dumped from the API) so you can see "before," then prove "after."
- A printed Next steps block telling you where to start.

## Tasks

### Part A — Read the baseline (before you change anything)
1. Snapshot the org via the API. Run `gh api /orgs/<org> --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories, members_can_delete_repositories, members_can_fork_private_repositories, web_commit_signoff_required, two_factor_requirement_enabled}'` and `gh api /orgs/<org>/actions/permissions/workflow`. Save both outputs — this is your "before."
2. Map the membership. List members and their roles: `gh api /orgs/<org>/members --jq '.[].login'` and `gh api /orgs/<org>/memberships/<your-login> --jq '.role'`. Note who is an owner vs a member.
3. List outside collaborators on the seeded repos: `gh api /orgs/<org>/outside_collaborators --jq '.[].login'`. Understand the difference: members belong to the org; outside collaborators have repo-level access only.

### Part B — Member privileges baseline
4. Set the default repository permission for members to the least-privilege value that still lets the team work. In Org Settings → Member privileges → Base permissions, choose `Read` (or `None` if you want explicit grants only). Verify: `gh api /orgs/<org> --jq '.default_repository_permission'`.
5. Restrict repository creation. Under Repository creation, disable members creating public repos and allow private/internal only (or restrict entirely to owners). In EMU, public repo creation is already platform-blocked; verify and document that rather than trying to enable it. Verify all three flags via the API (`members_can_create_public_repositories`, `..._private_...`, `..._internal_...`).
6. Restrict repository deletion & transfer to owners (Member privileges → "Allow members to delete or transfer repositories" off). 
7. Set the fork policy for private/internal repos to match a sensible default (off unless the team needs it). Verify `members_can_fork_private_repositories`.

### Part C — Visibility policy in practice
8. Confirm the three sample repos' visibility: `gh repo view <org>/ghec-ch06-public-sample --json visibility` (and the private/internal twins). In EMU, expect `ghec-ch06-public-sample` to report `PRIVATE` even though its name says public sample.
9. Change one sample repo's visibility. In standard GHEC, change `ghec-ch06-public-sample` to internal (`gh repo edit <org>/ghec-ch06-public-sample --visibility internal --accept-visibility-change-consequences`) and observe how "internal" exposes it to the whole enterprise's members but not the public. In EMU, use an allowed transition such as private ↔ internal if internal is available, or document that public is unavailable by design. Document the difference between public / internal / private in your notes.
10. Attempt a member-context action (or reason about it): with base permission now `Read`, a plain member can no longer push to a repo they aren't explicitly added to. Record why.

### Part D — Security & workflow defaults
11. Review 2FA posture. Read `two_factor_requirement_enabled` from the API. If your org isn't EMU-managed and you control it, document whether you'd require 2FA org-wide and the rollout risk (members without 2FA get removed). *(Awareness — don't lock yourself out.)*
12. Set default Actions workflow permissions to read-only for the org: Org Settings → Actions → General → Workflow permissions → Read repository contents permission. Verify with `gh api /orgs/<org>/actions/permissions/workflow --jq '.default_workflow_permissions'`. (You'll go deeper on Actions policy in the Automation track — here you just set the safe default.)
13. Enable the dependency graph / security defaults for new repos under Org Settings → Code security (defaults for new repositories). Note which toggles are free on public repos vs licensed on private.

### Part E — Verify
14. Produce "after" snapshots by re-running both Part A API calls and diffing them against your saved "before" outputs.

### Part F — Default-branch policy (enterprise vs. organization)
15. Inspect the effective **organization** default-branch policy for new repositories through the API or organization settings. This is the org-level implementation, not the enterprise-level decision — keep the two distinct in your notes.
16. Source the enterprise-level default-branch and member-privilege decision: cite Ch52's landing-zone topology/delegation register entry, or an authorized enterprise export/inspection; if neither is available, record `enterprise policy not available / not applicable` in your evidence. Don't infer enterprise-wide policy from this one organization.

## Reference links
- About organizations — https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/about-organizations
- Setting permissions for adding outside collaborators — https://docs.github.com/en/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators
- Setting base permissions for an organization — https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization
- Restricting repository creation in your organization — https://docs.github.com/en/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization
- About repository visibility — https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-repository-visibility
- Managing the forking policy for your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-the-forking-policy-for-your-organization
- Organizations REST API — https://docs.github.com/en/rest/orgs/orgs
- About enterprise accounts — https://docs.github.com/en/enterprise-cloud@latest/admin/overview/about-enterprise-accounts
