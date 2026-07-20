# Ch25 — Migrate from GitLab to GitHub — Delivery Assurance Guide
> Customer authorization and rollout boundary: Apply changes in a customer-owned tenant or repository only after the named customer owner authorizes the scope. A fallback is a sample test repository or environment, not the destination: record its evidence, risks and controls, accountable owner, handover, and the explicit tenant adoption, cutover, or rollout decision.


> Audience: delivery assurance leads and authorized customer implementation owners. Pair with the corresponding customer implementation `README.md`.

## Intent

Deliver the accurate self-serve GitLab-to-GitHub path: Git source and history through `git clone --bare` plus `git push --mirror`, followed by GitLab CI conversion through GitHub Actions Importer. The critical customer decision is fidelity: GitLab is not a self-serve GEI source, so Merge Requests, issues, and other metadata require GitHub Expert Services.

## Timing (reference)

| Phase | Duration |
|---|---:|
| Authorized scope, prerequisites, and target repo creation | ~25 min |
| Bare clone, mirror push, and ref validation | ~45 min |
| Loss inventory and large-repo caveats | ~25 min |
| Actions Importer audit, dry-run, and migrate | ~60 min |
| Cutover-risk decision and handover | ~25 min |
| Total | ~180 min |

## Expected Outputs

For delivery assurance, collect the following customer-owned evidence:

- A GitHub repository containing the GitLab repository's migrated branches, tags, and commit history.
- Evidence that commit authorship links correctly when GitLab commit emails are present on GitHub accounts.
- A written list of non-migrated GitLab data: MRs, issues, labels, milestones, CI/CD history, wikis, packages/registry/artifacts, and LFS objects.
- GitHub Actions Importer audit and dry-run output, plus a migration PR or generated `.github/workflows/*.yml` workflow.
- Notes identifying unsupported or manually reviewed CI conversion items.
- A clear recommendation for Expert Services when metadata fidelity is required.

## Common Pitfalls

### Expecting Merge Requests and issues to migrate
Symptom: Customer implementation owner says GEI or `git push --mirror` migrated GitLab MRs, issues, labels, or milestones.
Fix: Re-anchor on fidelity. The self-serve Git CLI path is source + history only. GitLab metadata migration to GHEC is GitHub Expert Services only.

### Commit authorship appears unattributed
Symptom: Commits show as unlinked names or email addresses in GitHub.
Fix: Have the user add and verify the GitLab commit email on their GitHub account. Git commit authorship is matched by email, not by GEI mannequin reclaim.

### Git LFS objects are missing
Symptom: Files are pointer text after migration or large binaries are absent.
Fix: Explain that LFS is not moved by the bare clone mirror path. Plan a separate LFS migration or replace oversized Git objects before cutover.

### Mirror push fails near 2 GiB
Symptom: `remote: fatal: pack exceeds maximum allowed size` or `fatal: the remote end hung up unexpectedly`.
Fix: Use the batch technique from the README: push every Nth commit on the default branch, lower N if needed, then run the final `git push --mirror`.

### GitHub blocks a large file
Symptom: Push fails because an individual file exceeds 100 MiB.
Fix: Move the file to Git LFS or remove/rewrite it before import. The standard GitHub repository limit is 100 MiB per file.

### Actions Importer conversion is partial
Symptom: Generated workflow contains TODOs, unsupported tasks, wrong runner labels, or missing secrets.
Fix: Normalize expectations: Actions Importer targets about 80% automatic conversion. Customer implementation owners must review, test, and patch the workflow before an authorized rollout.

## Implementation troubleshooting prompts

1. Gentle: Ask what fidelity tier their command provides. Does `git push --mirror` know anything about GitLab Merge Requests or issues?
2. Medium: Have them list refs with `git ls-remote --heads` and `git ls-remote --tags`, then compare that evidence to the missing metadata list.
3. Specific: If the CI step stalls, run `gh actions-importer configure`, then repeat `audit gitlab`, `dry-run gitlab`, and `migrate gitlab` with `--source-file-path .gitlab-ci.yml` and a GitHub target URL.

## Customer adoption decision

- Which business requirement decides whether self-serve Git CLI is enough or Expert Services is required?
- What user-communication step prevents surprises about missing MRs, issues, pipeline history, LFS, and packages after cutover?
- How would you rehearse the final migration window so no GitLab commits land after the mirror push?
- Which generated Actions workflow items must be manually validated before making the workflow a required check?

## Delivery assurance evidence

Accept implementation readiness for accurate fidelity framing and observable evidence, not for a perfect production workflow. The customer owner should be able to state: "We migrated Git history self-serve; metadata did not move; CI was converted separately and needs review; full-fidelity GitLab migration requires Expert Services."
