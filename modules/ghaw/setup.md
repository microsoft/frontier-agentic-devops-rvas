# GHAW setup

**Build one useful workflow in a customer-owned repository.** Start with
[environment setup](challenges/00-setup/README.md), then choose one pilot:
[a documentation correction](challenges/19-daily-doc-updater/README.md),
[an approved regression test](challenges/21-daily-testify/README.md),
[CI diagnosis](challenges/18-ci-doctor/README.md), or
[issue triage](challenges/17-issue-triage-agent/README.md).
None requires the advanced activities.

## Bring your own repo

Pick a repository the team will keep maintaining. Name a workflow owner and an
independent PR reviewer. Start from a real task, not from the automation.
A sample repository is fine for practice, but it doesn't prove the workflow
runs in the customer's environment.

Work in the customer's approved development environment. This repository's dev
container installs `gh-aw` through `postCreate.sh`. In a Codespace or local
checkout without it, follow the
[official setup instructions](https://github.github.com/gh-aw/setup/quick-start/),
and check the install source and version first.

## Deployment readiness

In the customer checkout, run `gh auth status` and `gh aw --version`.
Check the remote and your repository role with `gh repo view`. Confirm that
GitHub Actions is enabled, a runner is available, and organization policy
allows the chosen actions and AI engine.

Configure the chosen [engine's authentication](https://github.github.com/gh-aw/reference/engines/)
in repository or organization secrets. **Local CLI authentication is not engine
authentication in Actions.** Record the engine and who owns its credential.
Set a usage budget. Keep secret values out of the workflow.

Keep the agent's GitHub token read-only. Declare only the
[safe outputs](https://github.github.com/gh-aw/reference/safe-outputs/) the task
needs; their separate jobs perform writes. Inspect the compiled `.lock.yml`
for permissions and approved destinations. Limit tools and network access to
the task. Run test code only in an isolated runner with no production credentials.

## Pilot acceptance

Keep this evidence in the workflow's setup PR or tracking issue:

- The customer task and its owner, plus the allowed inputs, write paths, and
  stop condition.
- The source `.md` and generated `.lock.yml`, reviewed together and deployed
  through the repository's normal change process.
- One live run and its output, compared with the source evidence. **A compile
  or dry run alone doesn't prove delivery.**
- A repeat or empty-input run that creates no duplicate work.
- For code or documentation PRs, the check results and the independent review.
  The maintainer records the decision and reason, merged or not.

Protect the base branch with required checks and review. Do not grant the agent
bypass or auto-merge rights. Confirm that generated PRs start the required
checks. Events created with `GITHUB_TOKEN` do not generally trigger other
workflows. If needed, use an approved, repository-scoped GitHub App for
safe-output writes and verify its permissions before enabling it.

**Keep the first run manual.** Enable a schedule only after the owner accepts the
output and agrees to maintain it. Missing access, or a workflow that has not
run, is a blocker. Record it.
