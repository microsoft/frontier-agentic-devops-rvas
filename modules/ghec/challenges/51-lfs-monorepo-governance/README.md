# Ch51: Validate LFS or monorepo controls

**Session outcome:** The path you pick, LFS storage or monorepo ownership, works on a real push and pull request.

## Prerequisites

**Pick one path: A or B. Don't do both.** Use an approved repository. You need Git and repository write access. Path A also needs Git LFS and an approved storage budget. Neither path rewrites history.

## Path A: LFS push and fresh clone

**Acceptance test:** a fresh clone gets the original bytes, and the object is in LFS storage.

1. Pick a small non-sensitive fixture (a few kilobytes) and agree its LFS pattern with the storage owner.
2. On a branch, run `git lfs install`, then `git lfs track '*.fixture'`. Add `.gitattributes` and the fixture, commit, and push. Run `git show HEAD:path/to/sample.fixture` to confirm Git stores the LFS pointer.
3. Merge through normal review. In a **new directory**, clone the repository and run `git lfs pull`. Confirm the working file holds the original bytes, not the pointer. Compare SHA-256 checksums with the source.
4. Run `git lfs fsck` and `git lfs ls-files -l`. `.gitattributes` alone doesn't prove the object reached storage.

Converting existing history is separate work because it rewrites commits.

## Path B: Monorepo ownership and targeted checks

**Acceptance test:** a package-only PR requests its owner and runs only its tests, and a failing test blocks the merge.

1. Pick two existing package paths with different owning teams. Put the default CODEOWNERS wildcard first and the specific package paths after it.
2. Require Code Owner review on the default branch. Make sure the teams have write access, and test with a non-owner contributor.
3. Install and adapt the workflow below. Require its stable **Monorepo gate** check on the default branch. This aggregate check always runs and rejects selection failures or missing selected tests. Don't add workflow-level path filters.
4. Open one PR in each package. Confirm GitHub requests the intended team and runs only the tests that package and its dependencies need. Then change shared code and verify CI tests both packages.
5. Deliberately fail one selected test and prove the aggregate check blocks the merge. Fix it and get the correct owner's approval.

### Install targeted CI

The [working example](../../resources/ci/monorepo.yml) expects Node.js 22, a root `package-lock.json`, and npm workspaces `packages/web` and `packages/api` with real `test` scripts. Copy it to the approved repository:

```bash
export TARGET_CHECKOUT="/path/to/approved-monorepo"
mkdir -p "$TARGET_CHECKOUT/.github/workflows"
cp modules/ghec/resources/ci/monorepo.yml "$TARGET_CHECKOUT/.github/workflows/monorepo.yml"
```

Check for an existing workflow before overwriting it. Change the package paths in both the selector and the test commands to match your repository. For another stack, use its tested runtime and commands.

The selector compares the PR merge commit or merge-group head with its base. It includes deleted and renamed paths. Changes outside the two package directories, including the lockfile, CI, and shared code, select **both** packages. An empty diff also selects both. If one package depends on the other, update the selection so a change to the dependency tests its consumers too.

Run the exact package commands locally before merging the workflow. Protect the workflow with independent owner review, then run Path B's package-only, shared-change, and failing-test PR checks. If the repository uses merge queue, verify the gate also passes on a real `merge_group` run.

## References

- [Configuring Git LFS](https://docs.github.com/en/repositories/working-with-files/managing-large-files/configuring-git-large-file-storage)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
