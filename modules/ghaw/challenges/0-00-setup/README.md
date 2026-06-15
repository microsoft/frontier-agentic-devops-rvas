## Objectives

By the end of this challenge you will have:

- A working `gh-aw` CLI environment (GitHub Codespaces or local Dev Container)
- Authenticated `gh` CLI session
- Successfully verified `gh-aw` is ready to use
- Cloned or forked the hackathon repository

## Getting Started

### Step 1: Set Up Your Environment

**Choose your path:**

- **GitHub Codespaces (Recommended):** Click the green **Code** button on the repository, select **Codespaces**, and create a codespace on main. Wait ~30 seconds for the container to build.
- **Local Setup:** Clone the repository and open it in VS Code with the Dev Containers extension. Then run **Dev Containers: Reopen in Container**.

Detailed instructions: DevContainer Setup Guide

### Step 2: Authenticate with GitHub

Your container doesn't have your GitHub credentials yet. Run:

```bash
gh auth login
```

Choose HTTPS or SSH (HTTPS is simpler if unsure), paste the device code into your browser, and grant the required permissions.

### Step 3: Verify gh-aw is Ready

```bash
gh aw --version
```

You should see a version number (e.g., `gh-aw version 1.0.0`).

### Step 4: Clone or Fork the Repo

If you haven't already:

```bash
git clone https://github.com/microsoft/frontier-ghaw-hackathon.git
cd gh-aw-hackathon
```

Or fork first (recommended):

```bash
gh repo fork https://github.com/microsoft/frontier-ghaw-hackathon --clone
cd gh-aw-hackathon
```

## Success Criteria

- [ ] `gh aw --version` returns a version string
- [ ] `gh aw run examples/hello-world.md --dry-run` completes without errors
- [ ] You can see the generated workflow YAML
- [ ] You have a local or Codespaces environment ready to code

## Resources

- DevContainer Setup Guide
- [gh-aw on GitHub](https://github.com/github/gh-aw)
- [What The Hack format explained](https://microsoft.github.io/WhatTheHack/)
