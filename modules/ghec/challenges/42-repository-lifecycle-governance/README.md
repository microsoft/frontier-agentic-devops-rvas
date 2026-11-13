# Ch42: Repository inventory and lifecycle

**Session outcome:** You list a small set of real repositories, fix one metadata or ownership gap, and archive and restore one approved test repository.

## Prerequisites

- A small set of approved customer repositories. Read access is enough for the inventory.
- One test repository you may archive, and its administrator with approval for the archive and restore.

If no customer repositories are approved, `setup.sh provision ch42 --org <org>` creates private samples. It never archives or deletes repositories.

## Tasks

1. List the agreed repositories:
   ```bash
   gh api --paginate --slurp 'orgs/<org>/repos?per_page=100&type=all' \
     --jq 'add | map({full_name,description,visibility,archived,pushed_at})' > inventory.json
   ```
   The token may not see the full enterprise inventory.
2. Pick one repository with a missing description or owner. Check its team grants and CODEOWNERS, ask the proposed team to confirm ownership in the review issue, then fix the description or ownership record and verify it. A topic or recent committer alone doesn't establish an owner.
3. For the test repository, note its default-branch SHA, visibility, and access. Confirm no deployment, package consumer, or Pages site depends on it.
4. Archive it and check the status:
   ```bash
   gh repo archive <org>/<approved-test-repo> --yes
   gh repo view <org>/<approved-test-repo> --json isArchived
   ```
   Try a harmless branch push as a normal contributor. It must fail.
5. Restore it with **Settings → General → Unarchive this repository**, or:
   ```bash
   gh api --method PATCH repos/<org>/<approved-test-repo> -F archived=false
   ```
   Confirm the SHA and permissions are unchanged, push the test branch again, then delete it.

**Blocked:** if archiving isn't approved, note the blocker in the review issue and stop. The session isn't complete. Don't transfer or delete anything.

## References

- [Archiving and unarchiving repositories](https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories)
- [Repositories REST API](https://docs.github.com/en/rest/repos/repos)
