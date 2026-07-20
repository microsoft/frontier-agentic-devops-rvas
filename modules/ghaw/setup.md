# GHAW Setup

Use one of these supported environment paths before starting `ghaw-00`:

## Roles used in the activities

- Delivery team: the customer team completing an activity and adapting it to a repository they own.
- Facilitator: the person guiding the session, helping the delivery team test and connect the exercise to their work. Files named `COACH.md` are facilitator guides.

Some older activity text uses squad for the delivery team and coach for the facilitator. Read those terms using the roles defined above.

## Option 1: GitHub Codespaces
1. Open this repository (`microsoft/frontier-agentic-devops-rvas`) on GitHub.
2. Click Code → Codespaces → Create codespace on main.
3. Wait for the dev container to finish building. `gh-aw` installs automatically via `postCreate.sh`.

## Option 2: Local dev container
1. Install Docker Desktop and VS Code.
2. Clone this repository (if you haven't already):
   ```bash
   git clone https://github.com/microsoft/frontier-agentic-devops-rvas.git
   cd frontier-agentic-devops-rvas
   ```
3. Install the Dev Containers extension in VS Code.
4. Run Dev Containers: Reopen in Container. `gh-aw` installs automatically via `postCreate.sh`.

## Verify the toolchain
```bash
gh auth login
gh auth status
gh aw --version
gh aw trial modules/ghaw/resources/examples/hello-world.md --logical-repo microsoft/frontier-agentic-devops-rvas --dry-run --yes
```

If `gh aw --version` fails in a local environment, reinstall with:
```bash
curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
```

Expected outcome: GitHub authentication succeeds, `gh aw --version` prints a version, and the hello-world dry run completes without errors.

The `--logical-repo` flag tells `gh-aw` which repository to simulate. This avoids failures when your local clone uses an SSH host alias or another non-standard remote URL.

Customer delivery team members do not need write access to `microsoft/frontier-agentic-devops-rvas` for this smoke test. In trial mode, `gh-aw` uses a temporary host repository in the delivery team member's own GitHub account and only simulates the delivery session repository as the target.
