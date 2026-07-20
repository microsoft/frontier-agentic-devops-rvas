# Ch26 — Migrate Legacy VCS (SVN, Mercurial, TFVC, Perforce) — Delivery Assurance Guide
> **Customer authorization and rollout boundary:** Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.

## Intent

Deliver practical source-and-history migration paths for legacy VCS sources that GitHub Enterprise Importer and the GitHub Importer web tool do not handle directly. The customer outcome is not completing every possible source system at once; it is an authorized migration decision supported by one or more proven conversions, correct author mapping, a metadata-loss record, and safe push and cutover controls under GitHub size limits.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Authorized scope, source inventory, tool checks | ~30 min |
| SVN authors map and conversion | ~55 min |
| Mercurial, TFVC, or Perforce conversion | ~65 min |
| Large-file, LFS, and 2 GiB push planning | ~35 min |
| GitHub push validation, handover, and evidence capture | ~35 min |
| Cutover decision and handover | ~20 min |
| **Total** | **~240 min** |

## Expected Outputs

For delivery assurance, collect the following customer-owned evidence:

- A source-specific conversion directory containing a valid Git repository.
- An `authors.txt` or equivalent author map with real names and email addresses.
- At least one GitHub repository populated from a legacy VCS conversion.
- Branches and tags visible in GitHub when they existed in the source and were converted.
- Evidence from `git log --all --format='%aN <%aE>'` showing useful author identities.
- Large-file scan output or notes showing no blocked files, LFS remediation, or a documented exception.
- A written migration note for untested systems that includes the commands, source URL shape, owner, and blocker.

## Common Pitfalls

### Missing or incorrect `authors.txt`
**Symptom:** Conversion fails with an unknown author error, or Git history contains `unknown`, raw usernames, or fake email addresses.
**Fix:** Extract all source users first, map every one to `Full Name <email@example.com>`, then reconvert. Do not patch only the newest commits.

### `git svn -s` assumes standard SVN layout
**Symptom:** `git svn clone -s` misses branches or tags, or imports the wrong root.
**Fix:** Confirm whether the source has `trunk`, `branches`, and `tags`. If not, rerun with explicit `--trunk`, `--branches`, and `--tags` paths.

### SVN tags remain remote refs
**Symptom:** Tags appear under remote refs or are missing in GitHub after push.
**Fix:** Convert `refs/remotes/origin/tags/*` into local Git tags before pushing. Verify with `git tag --list`.

### `hg-fast-export` Python dependency issues
**Symptom:** Converter exits with Python module, encoding, or executable errors.
**Fix:** Use a supported Python runtime for the chosen `hg-fast-export` version, run from a fresh `git init` directory, and keep the Mercurial clone path separate from the output path.

### TFVC has no direct GitHub CLI conversion
**Symptom:** Customer implementation owner searches for a `git tfvc` or GitHub Importer path and cannot find one.
**Fix:** Reinforce the required sequence: TFVC to Azure Repos Git first, then Git push or the Azure Repos Git migration pattern. Cross-reference ch21 for Azure Repos Git repository migrations.

### Perforce depot scope is too broad
**Symptom:** `git p4 clone //depot/...@all` takes too long, creates an oversized Git repository, or imports unrelated products.
**Fix:** Narrow the depot path, decide branch mapping, and migrate one product path at a time.

### 2 GiB push failure
**Symptom:** `git push --mirror` fails with the GitHub 2 GiB pack or single-push limit.
**Fix:** Push large history in commit batches per branch, then push tags and final refs after GitHub already has most objects. Reduce batch size if a batch still fails.

### Line-ending or encoding issues
**Symptom:** Converted files show unexpected diffs, mojibake, or scripts fail after migration.
**Fix:** Sample old and new checkouts, verify `.gitattributes`, and document any source encoding assumptions before cutover.

## Implementation troubleshooting prompts

Use these progressively to resolve an implementation blocker while preserving customer ownership and the cutover boundary.

1. **Gentle:** Start by proving identity mapping. A conversion with bad authors is not a migration success even if the push works.
2. **Medium:** If branches or tags look wrong, inspect refs with `git for-each-ref` before pushing. Legacy converters often create remote refs that need to become normal Git branches or tags.
3. **Specific:** For large repositories, do not keep retrying `git push --mirror`. Scan blobs over 50 MiB, move binaries to LFS when appropriate, push the main branch in commit batches under the 2 GiB limit, then push remaining refs.

## Customer adoption decision

- Which legacy VCS source would you migrate first in a real program, and why?
- What source metadata did your chosen conversion preserve, and what did it lose?
- How did author mapping change the quality of the migrated history?
- What is your plan for files over 100 MiB, binary history, and Git LFS ownership?
- Where would you freeze source writes, validate converted branches and tags, and communicate cutover timing?
- For TFVC specifically, who owns the TFVC to Azure Repos Git step before GitHub migration begins?

## Delivery assurance evidence

Use a subset of controlled conversions when access to every legacy VCS is unrealistic. Accept implementation readiness only with at least one customer-owned converted GitHub repository plus credible end-to-end documentation for the other requested source systems. Do not accept copied commands without evidence of author mapping, branch/tag review, size-limit checks, a GitHub destination repository or documented blocker, and a customer cutover decision.

## Useful Verification Commands

```bash
# In the converted Git repository
git status
git log --oneline --decorate --graph --all | head -50
git branch --all
git tag --list | head -50
git log --all --format='%aN <%aE>' | sort -u | head -100

# Against the GitHub destination
gh repo view "$GITHUB_ORG/$DEST_REPO" --json nameWithOwner,visibility,defaultBranchRef
gh api "repos/$GITHUB_ORG/$DEST_REPO/branches" --jq '.[].name'
gh api "repos/$GITHUB_ORG/$DEST_REPO/tags" --jq '.[].name'
```

## Reference Links

- About source code imports using the command line — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/about-source-code-imports-using-the-command-line
- Importing an external Git repository using the command line — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-an-external-git-repository-using-the-command-line
- Importing a Subversion repository — https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/importing-a-subversion-repository
- About GitHub Importer — https://docs.github.com/en/migrations/importing-source-code/using-github-importer/about-github-importer
- About large files on GitHub — https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
- Troubleshooting the 2 GB push limit — https://docs.github.com/en/get-started/using-git/troubleshooting-the-2-gb-push-limit
