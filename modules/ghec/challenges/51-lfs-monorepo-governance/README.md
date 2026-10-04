# Ch51: Validate LFS or monorepo controls

**Session outcome:** The selected storage or ownership path works on a real push and pull request. Record which path was tested.

## Prerequisites

Choose **one** path for an approved repository. Reuse Ch02 and Ch04 controls. You need Git and repository write access. Path A also needs Git LFS and an approved storage budget. Neither path requires rewriting history.

## Path A: LFS push and fresh clone

1. Choose a small non-sensitive fixture and agree its LFS pattern with the storage owner. A few kilobytes are enough; do not upload large files merely to demonstrate LFS.
2. On a branch, run `git lfs install`, then `git lfs track '*.fixture'`. Add `.gitattributes` and the fixture, commit, and push. Inspect `git show HEAD:path/to/sample.fixture` to confirm Git stores the LFS pointer.
3. Merge through normal review. In a **new directory**, clone the repository and run `git lfs pull`. Confirm the working file contains the original bytes rather than the pointer. Compare SHA-256 checksums with the source.
4. Run `git lfs fsck` and record the object ID from `git lfs ls-files -l`. Keep the push and fresh-clone results. `.gitattributes` alone does not prove the object reached storage.
5. Record who owns storage and the approved pattern. Converting existing history is separate work because it rewrites commits.

## Path B: Monorepo ownership and targeted checks

1. Pick two existing package paths with different owning teams. Put the default CODEOWNERS wildcard first and the specific package paths after it.
2. Require Code Owner review on the default branch. Ensure the teams have write access and use a non-owner contributor for testing.
3. Install and adapt the workflow below. Require its stable **Monorepo gate** check on the default branch. The aggregate always runs and rejects selection failures or missing selected tests. Do not add workflow-level path filters.
4. Open one PR in each package. Confirm GitHub requests the intended team and runs only the necessary tests for the package and its dependencies. Then change shared code and verify CI tests both packages.
5. Deliberately fail one selected test and prove the aggregate check blocks merge. Repair it and obtain the correct owner's approval.

Keep the selected path's test results as [completion evidence](../../../README.md#completion-evidence).

### Install targeted CI

The [working example](../../resources/ci/monorepo.yml) expects Node.js 22, a root `package-lock.json`, and npm workspaces `packages/web` and `packages/api` with real `test` scripts. Copy it to the approved repository:

```bash
export TARGET_CHECKOUT="/path/to/approved-monorepo"
mkdir -p "$TARGET_CHECKOUT/.github/workflows"
cp modules/ghec/resources/ci/monorepo.yml "$TARGET_CHECKOUT/.github/workflows/monorepo.yml"
```

Review an existing workflow before replacing it. Change the package paths in both the selector and the test commands to match the actual repository. Use its tested runtime and commands for another stack.

The selector compares the PR merge commit or merge-group head with its base. It includes deleted and renamed paths. Changes outside the two package directories, including the lockfile, CI, and shared code, select **both** packages. An empty diff also selects both. If one package depends on the other, update the selection so a change to that dependency tests its consumers too.

Run the exact package commands locally before merging the workflow. Protect the workflow with independent owner review, then perform Path B's package-only, shared-change, and failing-test PR checks. If the repository uses merge queue, verify the gate also passes on a real `merge_group` run.

## References

- [Configuring Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
