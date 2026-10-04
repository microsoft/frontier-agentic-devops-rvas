# Configure an environment approval gate

Use this setup for the selected deployment or release job. Reuse an existing approved environment when its reviewers and allowed refs match the job; completing a deployment exercise is unnecessary for release-only use.

1. With the repository administrator, open **Settings → Environments**. Create or select the approved test environment.
2. Require an independent reviewer. Enable **Prevent self-review** and disable administrator bypass for the test.
3. Under **Deployment branches and tags**, select only the approved protected branch or tag patterns. A manually dispatched release workflow runs on its selected branch even when it publishes a tag.
4. Set `environment:` on the job that performs the privileged operation, after its successful build/test dependency. Do not put the environment on the build job as a substitute for gating publication or deployment.
5. Keep only the credentials that operation needs in that environment. A release job using `GITHUB_TOKEN` needs no cloud credential.

Check the configuration without exposing secret values:

```bash
export GH_REPO="YOUR-ORG/YOUR-REPO"
gh api "repos/$GH_REPO/environments" --jq '.environments[] | {name,protection_rules,deployment_branch_policy}'
```

If required reviewers are unavailable for the repository plan or visibility, record the blocker. A label or written approval does not replace the gate.

Each workflow must prove its own denied and approved operation. A rejected deployment does not prove that release publication is gated. The environment protects only jobs referencing it; review other workflows and identities that can perform the same privileged operation.
