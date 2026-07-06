# Dev Container — Frontier GitHub Platform Delivery Session

A single **all-in-one** dev container that pre-installs every tool needed by **all four
modules** (GHEC, GHAS, GHAW, SRE Agent) so you can work any challenge from one environment.

## What's included

| Tool | Source | Used by |
|------|--------|---------|
| `git` | `base:ubuntu` base image | all modules |
| `jq` | `postCreate.sh` (apt) | all modules |
| `gh` CLI | `github-cli` feature | all modules |
| **`gh-aw`** (GitHub Agentic Workflows) | `postCreate.sh` | GHAW, SRE |
| **Node 22** + `npm` | `node` feature | SRE sample app, Juice Shop |
| **Python 3.12** | `python` feature | GHEC/GHAW helpers |
| **Azure CLI** (`az`) | `azure-cli` feature | SRE Agent |
| **Bicep** | `postCreate.sh` (`az bicep install`) | SRE Agent |
| **Docker** (docker-in-docker) | `docker-in-docker` feature | GHAS (Juice Shop) |

The base is the lightweight official **`mcr.microsoft.com/devcontainers/base:ubuntu-22.04`**
image (~a few hundred MB). Every tool is layered on via pinned Dev Container Features, so the
container stays small and reproducible rather than shipping a ~10GB universal image.

VS Code extensions: Copilot + Copilot Chat, GitHub Actions, CodeQL, Bicep, YAML, Markdown.

## What's *not* included (by design)

This is a **tools-only** container. The per-module **sample apps** — OWASP **Juice Shop**
(GHAS) and **Contoso Claims** (SRE) — are **not auto-pulled** at container create time
(they are large; ~75% of participants never need both). Juice Shop is registered as a git
submodule and fetched lazily when needed.

**GHAS participants:** after the container starts, run:
```bash
npm run setup:juice-shop
```
This fetches Juice Shop at the pinned commit, verifies the SHA, and links it to `app/` so
`cd app && npm start` works immediately. Contoso Claims (SRE module) is vendored in-tree
and needs no separate fetch.

## Getting started

1. Open this repo in **Codespaces** (`Code → Codespaces → Create codespace`) or locally via
   **Dev Containers: Reopen in Container**.
2. Wait for the build. `postCreate.sh` installs `gh-aw` + Bicep and runs the doctor.
3. Authenticate:
   ```bash
   gh auth login          # all modules
   az login               # SRE Agent module only
   ```

## Verify the environment

Run the doctor any time:

```bash
bash scripts/doctor.sh
```

It checks `git`, `gh`, `gh aw`, `jq`, `node`, `npm`, `python3`, `az`, `bicep`, and `docker`,
prints a status table, and exits non-zero if a required tool is missing.

## Build & verify locally (maintainers)

Requires Docker + the [Dev Containers CLI](https://github.com/devcontainers/cli):

```bash
npm i -g @devcontainers/cli
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash scripts/doctor.sh
```

> The base image is lightweight, but the features (Node, Azure CLI, docker-in-docker) add a
> few minutes to the first build.

## Notes

- API keys for agentic engines (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`) are
  best set as **Codespace secrets** at `github.com/settings/codespaces` so they're available
  automatically.
- `*.lock.yml` files are associated with the GitHub Actions workflow schema for syntax help.
