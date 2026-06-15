# GHAW Setup

Use one of these supported environment paths before starting `ghaw-0-00`:

## Option 1: GitHub Codespaces
1. Open the source repository: <https://github.com/microsoft/frontier-ghaw-hackathon>
2. Click **Code** → **Codespaces** → **Create codespace on main**.
3. Wait for the dev container to finish building.

## Option 2: Local dev container
1. Install Docker Desktop and VS Code.
2. Clone the source repository:
   ```bash
   git clone https://github.com/microsoft/frontier-ghaw-hackathon.git
   cd frontier-ghaw-hackathon
   ```
3. Install the **Dev Containers** extension in VS Code.
4. Run **Dev Containers: Reopen in Container**.

## Verify the toolchain
```bash
gh auth login
gh auth status
gh aw --version
gh aw run examples/hello-world.md --dry-run
```

If `gh aw --version` fails in a local environment, reinstall with:
```bash
curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
```

Expected outcome: GitHub authentication succeeds, `gh aw --version` prints a version, and the hello-world dry run completes without errors.
