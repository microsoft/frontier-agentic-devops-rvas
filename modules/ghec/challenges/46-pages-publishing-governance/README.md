# Ch46: Pages Publishing Governance

> Deliver an approved operating model for GitHub Pages publishing: org policy decision, repo publishing configuration, and evidence for visibility, ownership, exceptions, and rollback.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Intermediate |
| Duration | ~3 hrs total, multi-session |
| Minimum input | An org + an org-owner token. |
| App | Provisioned Pages candidate repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Objective: prevent unmanaged Pages publication while allowing approved documentation sites.
- Delivery target: an approved organization Pages policy and one repository-level publishing proof.
- Safety boundary: organization Pages settings are org-wide controls. Change them only with org-owner approval; setup never changes them.
- Evidence: before/after policy snapshots, site URL, source or workflow run, exception decision, rollback owner, and next review.
- Owner: platform governance or developer experience.
- Next decision: approve rollout, publish the first production site, or review exceptions.

## Prerequisites

- An organization you own (or org-owner rights) on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch46 --org <org>`.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- A repository that is approved to publish a Pages site, or the seeded sample repository.

## Customer delivery objectives

You will:

- Inspect the current organization Pages publication policy.
- Decide who may publish Pages sites and which visibilities are allowed.
- Configure repository-level Pages publishing through a branch source or GitHub Actions.
- Verify site publication, visibility, rollback, and owner evidence.
- Record exceptions and review cadence in the governance register.

## Scenario

A customer wants to use GitHub Pages for engineering documentation. Organization owners need clear controls before sites appear under the organization namespace. Capture the current policy, agree on the publishing model, configure one approved repository, and keep evidence that operators can publish and roll back the site safely.

> [!IMPORTANT]
> Use an approved customer target first. If you have a real documentation repository, use it and skip setup. If not, use the fallback `ghec-ch46-pages-site` repository created by setup. Do not change organization Pages settings without explicit approval.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch46 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch46 --org <org>
```

Setup is idempotent and creates only these namespaced artifacts. Teardown accepts only the `ghec-ch46-*` prefix.

- `ghec-ch46-pages-site` with starter static content under `docs/`.
- A governance issue listing the policy decision to complete.
- A printed organization Pages policy snapshot when the API returns those fields.

## Tasks

### Part A — Capture current policy

1. Snapshot organization Pages settings from Organization settings → Pages, or with the organization API when available.
2. Record the allowed publisher population, visibility options, default stance, and exception owner.
3. Decide whether the production policy changes now or is captured as a rollout proposal.

### Part B — Approve the publishing model

4. Choose the publishing source: branch folder (`docs/`) or GitHub Actions.
5. Record site owner, content owner, review cadence, rollback owner, and incident contact.
6. Confirm repository visibility and Pages visibility match customer policy.

### Part C — Configure repository Pages

7. In the approved repository, configure Pages in Settings → Pages, or use the REST API for repository-level Pages setup:
   ```bash
   gh api -X POST repos/<org>/ghec-ch46-pages-site/pages \
     -f 'source[branch]=main' \
     -f 'source[path]=/docs'
   ```
8. If Pages already exists, update the source instead of creating a duplicate configuration.
9. Do not change org-wide Pages publication settings unless the approved policy decision says to do so.

### Part D — Verify publication and rollback

10. Capture repository Pages settings:
    ```bash
    gh api repos/<org>/ghec-ch46-pages-site/pages
    ```
11. Visit the site URL, capture the source branch/path or workflow run, and confirm visibility.
12. Document rollback: disable Pages, revert source, or remove workflow approval.

## Validation / Definition of Done

- [ ] Current org Pages publication policy is captured.
- [ ] Approved policy decision names publisher scope, allowed visibility, exception path, and review cadence.
- [ ] Org-wide settings were changed only by explicit participant action with approval, or a rollout proposal exists.
- [ ] Target repository has a compliant Pages source or workflow.
- [ ] Evidence includes site URL, source or workflow run, rollback owner, and next review.
- [ ] Adoption handover names the Pages policy owner and first production/review action.

## Reference links

- Managing publication of GitHub Pages sites for your organization — https://docs.github.com/en/organizations/managing-organization-settings/managing-the-publication-of-github-pages-sites-for-your-organization
- Configuring a publishing source — https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
- Creating a GitHub Pages site — https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site
- About GitHub Pages — https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages
- Pages REST API — https://docs.github.com/en/rest/pages/pages
