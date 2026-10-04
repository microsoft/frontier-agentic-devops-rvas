# Ch42: Repository inventory and lifecycle

**Session outcome:** You confirm repository owners and get approval for cleanup decisions. You also archive and restore an approved test repository.

## Prerequisites

Choose a small set of approved customer repositories. Include the test repository's administrator and accountable owner. Read access is enough for the initial inventory.

If no customer repositories are approved, `setup.sh provision ch42 --org <org>` creates private samples. It does not archive or delete repositories. Sample results are practice.

## Tasks

1. Export the visible repository inventory with pagination. Review only the agreed repositories:
   ```bash
   gh api --paginate --slurp 'orgs/<org>/repos?per_page=100&type=all' \
     --jq 'add | map({full_name,description,visibility,archived,pushed_at})' > inventory.json
   ```
   Record access limits. The token may not have access to the full enterprise inventory.
2. For each selected repository, inspect team grants and CODEOWNERS. Ask the proposed owning team to confirm responsibility in the review issue. A topic, recent committer, or CODEOWNERS entry alone does not establish a business owner.
3. Resolve at least one missing owner with that team's explicit acceptance. If nobody accepts, ask the organization owner to decide. Leave the repository unchanged.
4. Decide whether to keep the repository, improve its metadata, deprecate it, or propose archival. Check dependent services and retention obligations before proposing archival. Fix one approved description or ownership record and verify it.
5. For one approved test repository, save its URL, default-branch SHA, visibility, and current access. Confirm no active deployment, package consumer, or Pages dependency will break. Get approval for both archive and restoration.
6. Archive the repository and inspect its status:
   ```bash
   gh repo archive <org>/<approved-test-repo> --yes
   gh repo view <org>/<approved-test-repo> --json isArchived
   ```
   Attempt a harmless branch push as a normal contributor and confirm writes are blocked.
7. Restore using repository **Settings → General → Unarchive this repository**, or:
   ```bash
   gh api --method PATCH repos/<org>/<approved-test-repo> -F archived=false
   ```
   Verify the original SHA and permissions remain, and repeat the contributor branch push. Clean up the test branch.
8. Have the owner choose the final state and next review date. Keep the inventory and results from archiving and restoring as [completion evidence](../../../README.md#completion-evidence).

No transfer or deletion is required. If archival is not approved, keep an accepted lifecycle assessment and record the blocked archive and restore test.

## References

- [Archiving and unarchiving repositories](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories)
- [Repositories REST API](https://docs.github.com/en/rest/repos/repos)
