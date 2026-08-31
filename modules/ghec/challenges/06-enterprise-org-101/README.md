# Ch06 — Enterprise & Organization 101

> Deliver an organisation governance baseline: membership, privileges, repository-creation and visibility policies, security defaults, and API-verifiable evidence.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Foundational *(per-track ramp)* |
| Duration | ~3–4 hrs total, multi-session |
| Minimum input | An org + an org-owner token. *(All activities are org-scoped — no enterprise owner required.)* |
| App | Provisioned starter repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: establish a defensible organisation governance baseline in the customer tenant.
- Customer-tenant target: approved member-privilege, repository-creation, visibility, security-default, and workflow-permission settings.
- Approval and safety boundary: governance changes proceed in the customer organisation only when the accountable organisation owner approves them; otherwise produce an approved rollout proposal and risk decision from the controlled sample.
- Records to keep: retain before/after API snapshots and any EMU constraints.
- Adoption owner / handover: the customer organisation owner accepts the baseline and assigns ongoing policy ownership.
- Next action and owner: approve the change window and apply the agreed baseline, or hand over the signed rollout proposal.

## Prerequisites
- Recommended: Ch52 (Enterprise Landing Zone & Organization Strategy) completed first. When available, its topology map, delegated-admin model, and settings register are the **preferred** source for this activity's enterprise-level checks (Part F). If Ch52 was not completed, this activity's organization-level baseline still stands independently — see "Enterprise vs. organization control" below for the fallback.
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
- Distinguish the enterprise-level policy decision from this organization's implementation, and record which one you inspected — see "Enterprise vs. organization control" below.

## Scenario
You're the first platform admin hired at a fast-growing GHEC customer. The organization was created in a hurry: defaults are wide open, public repo creation may be allowed in standard GHEC or platform-blocked in EMU, base permissions are too generous, and nobody can say what the current policy actually is. Leadership wants a documented, defensible baseline — least-privilege member access, controlled repository creation, sensible security defaults — and they want it verifiable from the API, not from screenshots. Your job is to bring order to the org and prove it.

> [!IMPORTANT]
> Use an approved customer target (do this first)
>
> Default to an authorised customer organisation policy or repository-default setting. Do the work there and keep the evidence, guardrails, or automation.
>
> - Have a candidate? Use your real org settings and repos wherever this guide names `ghec-ch06-public-sample` or the sibling `ghec-ch06-*` repos. Skip the Setup step below entirely.
> - No suitable one? Use the fallback below: seeded visibility sample repos plus a starter team for controlled policy validation. In EMU, the public sample is created as private because public repositories are not allowed.
>
> Record the selected target, organisation owner, risk decision, and next action and owner. Use the sample only for testing; move the validated proposal to an approved customer organisation.

## Sample test repository or environment (when tenant delivery is constrained)
Skip this if you brought your own org/repo policy target. Otherwise run the provisioning entrypoint (Bash or PowerShell — both supported).

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
> Throughout, `ghec-ch06-public-sample` is the fallback sample. If you brought your own artifact, substitute its name in every command and use your real history, teams, settings, or data as the material to work from.

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
16. Source the enterprise-level default-branch and member-privilege decision: if Ch52 was completed, cite its landing-zone topology/delegation register entry; otherwise, if you hold authorized enterprise-owner access, pull an enterprise export/inspection and cite it. If neither is available, record `enterprise policy not available / not applicable` in your evidence — do not infer enterprise-wide policy from this one organization.

## Operational extensions
- Write a small script that pulls the full `/orgs/<org>` settings object and highlights changes from an earlier snapshot.
- Add a second team `ghec-ch06-readonly` and demonstrate how base permission + team permission combine (the more permissive of the two wins).
- Research and document, in one paragraph each, three settings that only exist at the enterprise tier (e.g., enterprise-wide policy enforcement, allowed org visibility, SSO requirement) — see "Enterprise vs. organization control" below.

> Enterprise vs. organization control: An enterprise account sits above organizations and can *enforce* many of these same controls across every org at once — base-permission ceilings, repository-visibility allow-lists, 2FA requirements, and default-branch policy — so an individual org owner can't loosen them. This activity implements and verifies the **organization-level** settings; it does not complete or substitute for the enterprise-level decision. Prefer Ch52's landing-zone topology, delegation, and settings register (or an authorized enterprise export you can cite) as the source for any enterprise-scoped item. If Ch52 was not completed and no enterprise export is authorized, record the enterprise item as `not available / not applicable` — do not infer enterprise-wide policy from this one organization. No enterprise-owner access is required to complete the hands-on organization-level work in this activity.

## Reference links
- About organizations — https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/about-organizations
- Setting permissions for adding outside collaborators — https://docs.github.com/en/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators
- Setting base permissions for an organization — https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization
- Restricting repository creation in your organization — https://docs.github.com/en/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization
- About repository visibility — https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-repository-visibility
- Managing the forking policy for your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-the-forking-policy-for-your-organization
- Organizations REST API — https://docs.github.com/en/rest/orgs/orgs
- About enterprise accounts — https://docs.github.com/en/enterprise-cloud@latest/admin/overview/about-enterprise-accounts
