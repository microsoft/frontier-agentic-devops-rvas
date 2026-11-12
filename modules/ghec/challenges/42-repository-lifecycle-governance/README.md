# Ch42: Repository inventory and lifecycle

**Session outcome:** You confirm repository owners and get approval for cleanup decisions. You also archive and restore an approved test repository.

## Prerequisites

Pick a small set of approved customer repositories. Include the test repository's administrator and accountable owner. Read access is enough for the initial inventory.

If no customer repositories are approved, `setup.sh provision ch42 --org <org>` creates private samples. It never archives or deletes repositories. Sample results are practice.

## Tasks

1. Export the visible repository inventory with pagination. Review only the agreed repositories:
   ```bash
   gh api --paginate --slurp 'orgs/<org>/repos?per_page=100&type=all' \
     --jq 'add | map({full_name,description,visibility,archived,pushed_at})' > inventory.json
   ```
   Record access limits. The token may not have access to the full enterprise inventory.
2. For each selected repository, check team grants and CODEOWNERS. Ask the proposed owning team to confirm in the review issue that they own it. A topic, recent committer, or CODEOWNERS entry alone doesn't establish a business owner.
3. Resolve at least one missing owner with that team's explicit acceptance. If nobody accepts, ask the organization owner to decide. Leave the repository unchanged.
4. Decide whether to keep the repository, improve its metadata, deprecate it, or propose archival. Before proposing archival, check dependent services and retention obligations. Fix one approved description or ownership record and verify it.
5. For one approved test repository, save its URL, default-branch SHA, visibility, and current access. Confirm no active deployment, package consumer, or Pages dependency will break. Get approval for both the archive and the restore.
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
8. Have the owner pick the final state and the next review date. Keep the inventory and the archive and restore results as [completion evidence](../../../README.md#completion-evidence).

You don't need to transfer or delete anything. If archival isn't approved, keep an accepted lifecycle assessment and record the archive and restore test as blocked.

## References

- [Archiving and unarchiving repositories](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories)
- [Repositories REST API](https://docs.github.com/en/rest/repos/repos)
