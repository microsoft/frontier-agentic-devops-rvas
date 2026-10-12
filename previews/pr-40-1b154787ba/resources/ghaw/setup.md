# GHAW setup

**Build one useful workflow in a customer-owned repository.** Start with
[environment setup](challenges/00-setup/README.md), then choose one pilot:
[a documentation correction](challenges/19-daily-doc-updater/README.md),
[an approved regression test](challenges/21-daily-testify/README.md),
[CI diagnosis](challenges/18-ci-doctor/README.md), or
[issue triage](challenges/17-issue-triage-agent/README.md).
Choose one pilot. None requires the advanced activities.

## Bring your own repo

Choose a repository the team can maintain after the session. Identify its
workflow owner and independent PR reviewer. Confirm a real task before adding
automation. A sample repository is useful for practice, but does not prove that
the workflow can run in the customer's environment.

Use the customer's approved development environment. This repository's dev
container installs `gh-aw` through `postCreate.sh`. For a Codespace or local
checkout without it, follow the
[official setup instructions](https://github.github.com/gh-aw/setup/quick-start/).
Check the proposed installation source and version before running it.

## Deployment readiness

In the customer checkout, verify `gh auth status` and `gh aw --version`.
Check the remote and your repository role with `gh repo view`. Confirm that
GitHub Actions is enabled and a runner is available. Check that organization
policy allows the chosen actions and AI engine.

Configure the chosen [engine's authentication](https://github.github.com/gh-aw/reference/engines/)
in repository or organization secrets. **Local CLI authentication is not engine
authentication in Actions.** Record the engine and who owns its credential.
Set a usage budget. Keep secret values out of the guide and workflow.

Keep the agent's GitHub token read-only. Declare only the
[safe outputs](https://github.github.com/gh-aw/reference/safe-outputs/) the task
needs; their separate jobs perform writes. Inspect the compiled `.lock.yml`
for permissions and approved destinations. Limit tools and network access to
the task. Test code only in an isolated runner without production credentials.

## Pilot acceptance

Keep this evidence with the workflow's setup PR or tracking issue:

- Describe the customer task and name its owner. Record the allowed inputs,
  write paths, and stop condition.
- Keep the source `.md` and generated `.lock.yml`. Review them together and
  deploy them through the repository's normal change process.
- Link one live run and its useful output. Compare the result with source
  evidence. A compile or dry run alone does not prove delivery.
- Show a repeat or empty-input run that creates no duplicate work.
- For code or documentation PRs, retain the required check results and
  independent review. The maintainer records the decision and reason,
  including whether the PR was merged.

Protect the base branch with required checks and review. Do not grant the agent
bypass or auto-merge rights. Confirm that generated PRs start the required
checks. Events created with `GITHUB_TOKEN` do not generally trigger other
workflows. If needed, use an approved, repository-scoped GitHub App for
safe-output writes and verify its permissions before enabling it.

Keep the first run manual. Enable a schedule only after the owner accepts the
output and agrees to maintain it. Record missing access or a workflow that
has not run as a blocker.
