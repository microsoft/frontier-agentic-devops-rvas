# Ch46: Pages publishing governance

**Session outcome:** Your approved repository publishes a GitHub Pages site that the right readers can open and others can't. You publish a change and roll it back through review.

## Prerequisites

- Owner rights on a GitHub Enterprise Cloud organization.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch46 --org <org>`.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- A repository approved to publish Pages, or the seeded sample repository.

> [!IMPORTANT]
> Use an approved customer repository if you have one. Otherwise use `ghec-ch46-pages-site`. Don't change organization-wide Pages settings without explicit approval.

## Sample test repository

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch46 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch46 --org <org>
```

Setup is idempotent. It creates `ghec-ch46-pages-site` with starter content under `docs/` and a governance issue. Teardown accepts only the `ghec-ch46-*` prefix.

## Tasks

1. Check the current policy in Organization settings → Pages: who may publish and which visibility options exist. Note the owner of any exception in the governance issue.
2. Publish from the `docs/` folder on `main` (or use GitHub Actions if the customer prefers). In Settings → Pages, or with the API:
   ```bash
   gh api -X POST repos/<org>/ghec-ch46-pages-site/pages \
     -f 'source[branch]=main' \
     -f 'source[path]=/docs'
   ```
   If Pages already exists, update the source instead.
3. Check the result:
   ```bash
   gh api repos/<org>/ghec-ch46-pages-site/pages
   ```
4. **Test access.** Repository visibility and Pages visibility are separate: a private repository doesn't make its site private. Publish only non-sensitive content until you've checked this.
   - Open the site as an intended reader and in a signed-out browser.
   - For a private site, confirm a denied account can't read it.
   - For an approved public site, confirm signed-out access works.
5. Push a harmless marker change through a PR and confirm it appears on the site.
6. Revert that commit through a reviewed PR, wait for the deployment, and confirm the earlier content is back for the same audience.

**Blocked:** if private publication or your approval is missing, leave customer content unpublished, note the blocker in the governance issue, and stop. The session isn't complete.

## Reference links

- [Managing publication of GitHub Pages sites for your organization](https://docs.github.com/en/organizations/managing-organization-settings/managing-the-publication-of-github-pages-sites-for-your-organization)
- [Configuring a publishing source](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [Creating a GitHub Pages site](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
- [About GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages)
- [Pages REST API](https://docs.github.com/en/rest/pages/pages)
