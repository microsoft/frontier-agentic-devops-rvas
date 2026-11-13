# Ch49: Publish an approved, tested release

**Session outcome:** A protected workflow publishes the exact tested artifact after independent approval. A rejected run publishes nothing, and the published files match the reviewed ones by checksum.

## Prerequisites

You need a repository with working build and artifact tests, a repository administrator, and an independent environment reviewer. You also need `gh`, `git`, and a local SHA-256 tool. Use an approved test release. **Ch39 and a cloud deployment aren't prerequisites.**

The [complete workflow example](../../resources/release/release.yml) uses a Node.js repository with a committed `package-lock.json`. It requires:

- `npm test` for the existing source tests and `npm run build` to produce `dist/`.
- `npm run test:artifact` to test the files in `dist/` with the application's existing artifact tests. A successful `echo` isn't a test.
- Reviewed release notes in `release-notes.md` at the candidate commit.

For another stack, swap in the runtime and the **Build and test** step from the customer's existing commands. Keep the tested output in `dist/`, or change the packaging path to match. The publish job must never build or run the application.

**Blocked:** if required reviewers aren't available for the repository's plan or visibility, stop and note the blocker in the adoption issue. A label or an approval in chat doesn't replace the gate, and the session isn't complete.

## Tasks

### Part A: Protect the publication route

1. Configure a test publication environment using the [shared approval setup](../../resources/environment-approval.md), or reuse one that already meets those requirements. Allow only the protected default branch, such as `main`. The manual workflow runs on that branch even though it publishes a tag.
2. Protect changes to `.github/workflows/release.yml` with CODEOWNERS and required code-owner review. Require review for the build scripts and artifact tests too.
3. With the administrator, apply tag rules to the release tag pattern (for example `v*`). Restrict updates and deletions, and restrict creation to the release operator or tag workflow. If available, enable release immutability in **Settings → General → Releases** before the test publication.

**The environment gates this job only.** It doesn't stop another workflow or an authorized API client from creating a release. Don't add App keys or deployment secrets to this workflow.

### Part B: Copy and customize the workflow

From the curriculum checkout, copy the example into the existing application checkout. Substitute its path:

```bash
export TARGET_CHECKOUT="/path/to/approved-repository"
mkdir -p "$TARGET_CHECKOUT/.github/workflows"
cp modules/ghec/resources/release/release.yml "$TARGET_CHECKOUT/.github/workflows/release.yml"
cd "$TARGET_CHECKOUT"
```

Check an existing `release.yml` before overwriting it. Then:

1. Change `environment: release` to your publication environment name. Set the runtime and build commands described in Prerequisites. Keep the `test:artifact` step after the build.
2. Use the action versions or commit pins your organization requires. The example gives the build only `contents: read`. Only `publish` gets `contents: write`.
3. Add `release-notes.md` with the test release's scope. Review it together with the workflow, then merge to the protected default branch.

The build checks that the candidate belongs to that branch and matches an existing tag. After testing, it packages `dist/` once, records the source SHA, and uploads the files. The publish job waits for approval, downloads **that artifact ID from the same run**, and verifies the checksum manifest. It rechecks the tag, creates a draft with the verified assets, then publishes a prerelease without marking it Latest. The publish job doesn't check out or rebuild anything.

### Part C: Choose the candidate and tag

Run these commands from the target checkout after merging. Replace the repository name and use an unused test tag:

```bash
export GH_REPO="YOUR-ORG/YOUR-REPO"
export BRANCH="$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)"
git fetch origin "$BRANCH" --tags
export CANDIDATE="$(git rev-parse "origin/$BRANCH")"
export TAG="v0.1.0-ch49.1"
gh release list --limit 20
git show "$CANDIDATE:release-notes.md"
```

Have the **authorized release operator** create the tag through the existing tag workflow. If manual tag creation is approved, the operator runs:

```bash
git tag -a "$TAG" "$CANDIDATE" -m "Approved Ch49 test candidate"
git push origin "refs/tags/$TAG"
```

Use signed tags if repository policy requires them. Don't force-push, move, or reuse an existing tag. The release workflow deliberately doesn't create tags.

### Part D: Withhold approval, then reject

1. Dispatch from the allowed default branch:

   ```bash
   gh workflow run release.yml --ref "$BRANCH" \
     -f candidate_sha="$CANDIDATE" -f release_tag="$TAG"
   gh run list --workflow release.yml --event workflow_dispatch --limit 5
   ```

   Set `RUN_ID` to the new run's ID after matching its branch and start time:

   ```bash
   export RUN_ID="NEW-RUN-ID"
   gh run view "$RUN_ID" --web
   ```

2. Wait for `build` to pass. In the run, confirm `publish` is waiting for environment review and none of its steps has started. Leave it waiting while you check that no release or draft exists:

   ```bash
   gh api "repos/$GH_REPO/releases" --paginate \
     --jq ".[] | select(.tag_name == \"$TAG\") | {tag_name,draft,html_url}"
   ```

   A successful API call with no matching output means no release exists. Authentication or network errors prove nothing.
3. The independent reviewer opens the run, chooses **Review deployments**, selects the environment, and clicks **Reject** with a short reason. Check the failed run and repeat the release query. Nothing should exist.

### Part E: Review and publish the tested files

Start a **fresh run**, using the same command, candidate, and still-unused tag. Set `RUN_ID` to its new ID. Once the build passes, download its artifact before approving:

```bash
export RUN_ID="FRESH-RUN-ID"
export ATTEMPT="$(gh run view "$RUN_ID" --json attempt --jq .attempt)"
export ARTIFACT="release-$RUN_ID-$ATTEMPT"
mkdir -p "review-$RUN_ID"
gh run download "$RUN_ID" --name "$ARTIFACT" --dir "review-$RUN_ID"
(cd "review-$RUN_ID" && sha256sum -c SHA256SUMS)
cat "review-$RUN_ID/source-sha.txt"
cat "review-$RUN_ID/release-notes.md"
```

On macOS, use `shasum -a 256 --check SHA256SUMS` in place of `sha256sum -c SHA256SUMS`.

The reviewer checks the candidate SHA, test logs, and notes. Then they choose **Review deployments → environment → Approve and deploy**. This workflow publishes a release. Despite the button's wording, it doesn't deploy the application.

After approval:

```bash
gh run watch "$RUN_ID" --exit-status
gh release view "$TAG" --json url,isDraft,isPrerelease,targetCommitish
mkdir -p "published-$RUN_ID"
gh release download "$TAG" --dir "published-$RUN_ID"
(cd "published-$RUN_ID" && sha256sum -c SHA256SUMS)
cmp "review-$RUN_ID/SHA256SUMS" "published-$RUN_ID/SHA256SUMS"
cmp "review-$RUN_ID/release.tgz" "published-$RUN_ID/release.tgz"
```

Both `cmp` commands should exit zero. They compare the published bytes with the files reviewed before approval. The Actions artifact's archive digest and the inner `release.tgz` checksum cover different files, so don't compare those two digests to each other.

### Optional: Recover with a second release

- **Rejected before publication:** no release exists. Fix the reason and start a fresh run. A new candidate needs a new tag.
- **Failed after draft creation:** the workflow refuses to overwrite an existing draft or release. Remove only an unpublished test draft, then start a fresh gated run. Never delete a published release to make a retry pass.
- **Published but unsuitable:** edit the release notes to warn readers off this version. Leave its tag and assets unchanged.

To test a correction, merge it, pick a new tag such as `v0.1.0-ch49.2`, and repeat Parts C to E. Link the corrected release from the original release notes.

If the route also deploys the application, a corrected release alone doesn't prove deployment recovery. Repeat Ch39's gated restore with the retained known-good artifact.

## References

- [Managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [Deployment environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [`gh release create`](https://cli.github.com/manual/gh_release_create)
