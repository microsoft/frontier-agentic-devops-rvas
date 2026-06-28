# Ch06 — Enterprise & Organization 101

> By the end of this challenge you can stand up and govern an organization the way a GHEC admin does on day one — member & outside-collaborator management, base member privileges, repository-creation and visibility policies, default member permissions, security defaults, and a verification pass via the org-settings API — using nothing but an org and an org-owner token.

| | |
|---|---|
| **Track** | Admin/Governance |
| **Difficulty** | Foundational *(per-track ramp)* |
| **Duration** | ~3–4 hrs total, multi-session |
| **Minimum input** | An **org** + an **org-owner token**. *(All challenges are org-scoped — no enterprise owner required.)* |
| **App** | seed |
| **EMU compatible** | yes |

## Prerequisites
- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `wth doctor ch06 --org <org>` (least-privilege; for this challenge: `admin:org` + `repo` + `read:org`).
- Local tooling: `gh >= 2.x`, `git`, `jq` (run `wth doctor` to verify).
- No GHAS, Codespaces, or enterprise-owner features are required. Every setting in this challenge lives at **organization** scope.

## Learning objectives
By completing this challenge you will:
- Read and reason about an organization's **member privileges** baseline (default repository permission, repo creation, page/visibility, fork policy).
- Configure **repository creation, visibility, and deletion/transfer** policies for members.
- Manage **members vs outside collaborators** and understand how each gets access.
- Set organization-wide **security defaults** (2FA awareness, default workflow permissions, dependency-graph defaults).
- Inspect and verify every setting from the **org-settings REST API** (`gh api /orgs/<org>`) so configuration is auditable, not just clicked.
- Understand where an **enterprise account** would layer policy *on top* of these org settings (awareness only).

## Scenario
You're the first platform admin hired at a fast-growing GHEC customer. The organization was created in a hurry: defaults are wide open, anyone can create public repos, base permissions are too generous, and nobody can say what the current policy actually is. Leadership wants a documented, defensible baseline — least-privilege member access, controlled repository creation, sensible security defaults — and they want it **verifiable from the API**, not from screenshots. Your job is to bring order to the org and prove it.

## Setup
Run the provisioning entrypoint (Bash or PowerShell — both supported). `wth` is the documented command surface; it wraps the scripts in `modules/ghec/resources/provisioning/scripts/`.

```bash
# Bash
wth setup ch06 --org <org>
# or directly:
bash modules/ghec/resources/provisioning/scripts/setup.sh setup ch06 --org <org>
```
```powershell
# PowerShell
wth setup ch06 --org <org>
# or directly:
modules/ghec/resources/provisioning/scripts/setup.ps1 setup ch06 --org <org>
```

**What setup creates** (all artifacts namespaced `wth-ch06-*`, idempotent, prefix-guarded teardown):
- Three seeded repos — **`wth-ch06-public-sample`**, **`wth-ch06-private-sample`**, and **`wth-ch06-internal-sample`** — each with a short `README` so you have real objects to apply visibility/permission policy against.
- A **starter team** `wth-ch06-members` with one of the sample repos attached at the default permission, so you can observe how base permissions flow.
- A printed **current baseline snapshot** (the org's existing member-privilege settings dumped from the API) so you can see "before," then prove "after."
- A printed **Next steps** block telling you where to start.

> Re-running `setup` reconciles (create-if-absent). `wth teardown ch06 --org <org> --yes` removes only `wth-ch06-*` artifacts. **Org-level setting changes you make are not auto-reverted** — see the Coach teardown note.

## Tasks

### Part A — Read the baseline (before you change anything)
1. **Snapshot the org via the API.** Run `gh api /orgs/<org> --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_create_private_repositories, members_can_create_internal_repositories, members_can_fork_private_repositories, web_commit_signoff_required, two_factor_requirement_enabled}'`. Save the output — this is your "before."
2. **Map the membership.** List members and their roles: `gh api /orgs/<org>/members --jq '.[].login'` and `gh api /orgs/<org>/memberships/<your-login> --jq '.role'`. Note who is an **owner** vs a **member**.
3. **List outside collaborators** on the seeded repos: `gh api /orgs/<org>/outside_collaborators --jq '.[].login'`. Understand the difference: members belong to the org; outside collaborators have repo-level access only.

### Part B — Member privileges baseline
4. **Set the default repository permission** for members to the least-privilege value that still lets the team work. In **Org Settings → Member privileges → Base permissions**, choose `Read` (or `None` if you want explicit grants only). Verify: `gh api /orgs/<org> --jq '.default_repository_permission'`.
5. **Restrict repository creation.** Under **Repository creation**, disable members creating **public** repos and allow **private/internal** only (or restrict entirely to owners). Verify all three flags via the API (`members_can_create_public_repositories`, `..._private_...`, `..._internal_...`).
6. **Restrict repository deletion & transfer** to owners (Member privileges → "Allow members to delete or transfer repositories" off). 
7. **Set the fork policy** for private/internal repos to match a sensible default (off unless the team needs it). Verify `members_can_fork_private_repositories`.

### Part C — Visibility policy in practice
8. **Confirm the three sample repos' visibility:** `gh repo view <org>/wth-ch06-public-sample --json visibility` (and the private/internal twins). 
9. **Change `wth-ch06-public-sample` to internal** (`gh repo edit <org>/wth-ch06-public-sample --visibility internal --accept-visibility-change-consequences`) and observe how "internal" exposes it to the whole enterprise's members but not the public. Document the difference between **public / internal / private** in your notes.
10. **Attempt a member-context action** (or reason about it): with base permission now `Read`, a plain member can no longer push to a repo they aren't explicitly added to. Record why.

### Part D — Security & workflow defaults
11. **Review 2FA posture.** Read `two_factor_requirement_enabled` from the API. If your org isn't EMU-managed and you control it, document whether you'd require 2FA org-wide and the rollout risk (members without 2FA get removed). *(Awareness — don't lock yourself out.)*
12. **Set default Actions workflow permissions** to **read-only** for the org: **Org Settings → Actions → General → Workflow permissions → Read repository contents permission**. This is a key least-privilege default. (You'll go deeper on Actions policy in the Automation track — here you just set the safe default.)
13. **Enable the dependency graph / security defaults** for new repos under **Org Settings → Code security** (defaults for new repositories). Note which toggles are free on public repos vs licensed on private.

### Part E — Verify & document
14. **Produce an "after" snapshot** by re-running the Part A API call and diffing it against your saved "before." Every change you made should be reflected in JSON.
15. **Write a one-page baseline doc** (in `wth-ch06-private-sample`'s README or a new `POLICY.md`) listing each setting, its value, and the one-line rationale. This is the artifact a real customer would keep for audits.

## Validation / Definition of Done
You are done when ALL of the following are true:
- [ ] `default_repository_permission` is `read` or `none` (verifiable: `gh api /orgs/<org> --jq '.default_repository_permission'`).
- [ ] Members **cannot** create public repositories (`members_can_create_public_repositories == false`).
- [ ] Members **cannot** delete or transfer repositories (confirmed in Member privileges).
- [ ] The fork policy for private/internal repos is set deliberately and verified via the API.
- [ ] At least one sample repo's **visibility was changed** and you can explain public vs internal vs private.
- [ ] Default **Actions workflow permissions** are set to read-only at the org.
- [ ] A **before/after API diff** exists and a **`POLICY.md`/baseline doc** records every setting + rationale.
- [ ] Coach conversation — if you were the org owner of your team's GitHub organization today, what is the first enterprise policy or default repository setting you would change, and what risk or inefficiency is it currently causing? Talk it through with your coach and connect it to a real project, task, or workflow you own.

> Coaches verify these via the automated hints in `COACH.md`.

## Stretch goals
- Write a small script that pulls the full `/orgs/<org>` settings object and renders a Markdown policy table automatically — turn governance into a repeatable report.
- Add a second team `wth-ch06-readonly` and demonstrate how base permission + team permission combine (the **more permissive** of the two wins).
- Research and document, in one paragraph each, **three** settings that only exist at the **enterprise** tier (e.g., enterprise-wide policy enforcement, allowed org visibility, SSO requirement) — see "At enterprise scale" below.

> **At enterprise scale (awareness only):** An **enterprise account** sits above organizations and can *enforce* many of these same controls across every org at once — base permission ceilings, repository visibility allow-lists, 2FA requirements, and more — so an individual org owner can't loosen them. In this challenge you configure the **org-level** equivalents, which are the real, day-to-day controls. No enterprise owner is required.

## Reference links
- About organizations — https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/about-organizations
- Setting permissions for adding outside collaborators — https://docs.github.com/en/organizations/managing-organization-settings/setting-permissions-for-adding-outside-collaborators
- Setting base permissions for an organization — https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/setting-base-permissions-for-an-organization
- Restricting repository creation in your organization — https://docs.github.com/en/organizations/managing-organization-settings/restricting-repository-creation-in-your-organization
- About repository visibility — https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-repository-visibility
- Managing the forking policy for your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-the-forking-policy-for-your-organization
- Organizations REST API — https://docs.github.com/en/rest/orgs/orgs
- About enterprise accounts — https://docs.github.com/en/enterprise-cloud@latest/admin/overview/about-enterprise-accounts
