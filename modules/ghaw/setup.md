# GHAW setup

Choose one of these environments, then run `ghaw-00` to authenticate and verify the toolchain.

## Bring your own repo

Use a repository the team owns when one is available. Update the workflow wherever the activity references the sample repo so it uses your issues, PRs, and history. If you do not have a candidate repository, use the sample repo from this setup.

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

## Install or repair `gh aw`

Both environments install `gh-aw` for you. If `gh aw --version` fails, reinstall it:

```bash
curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
```

Activity 00 runs the authentication and hello-world dry-run checks.

## Trial mode and repository access

Team members do not need write access to `microsoft/frontier-agentic-devops-rvas` for the Activity 00 smoke test. In trial mode, `gh-aw` uses a temporary host repository in the member's own GitHub account and only simulates the target repository.
