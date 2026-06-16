# Dev Container — Frontier GitHub Platform Hackathon

A single **all-in-one** dev container that pre-installs every tool needed by **all four
modules** (GHEC, GHAS, GHAW, SRE Agent) so you can work any challenge from one environment.

## What's included

| Tool | Source | Used by |
|------|--------|---------|
| `git`, `jq` | `universal:2` base image | all modules |
| `gh` CLI | `github-cli` feature | all modules |
| **`gh-aw`** (GitHub Agentic Workflows) | `postCreate.sh` | GHAW, SRE |
| **Node 22** + `npm` | `node` feature | SRE sample app, Juice Shop |
| **Python 3.12** | `python` feature | GHEC/GHAW helpers |
| **Azure CLI** (`az`) | `azure-cli` feature | SRE Agent |
| **Bicep** | `postCreate.sh` (`az bicep install`) | SRE Agent |
| **Docker** (docker-in-docker) | `docker-in-docker` feature | GHAS (Juice Shop) |

VS Code extensions: Copilot + Copilot Chat, GitHub Actions, CodeQL, Bicep, YAML, Markdown.

## What's *not* included (by design)

This is a **tools-only** container. The per-module **sample apps** — OWASP **Juice Shop**
(GHAS) and **Contoso Claims** (SRE) — are **not vendored** here. Clone them on demand from
their source repos when a challenge requires them. Each source repo also ships its own
purpose-built dev container if you prefer to work a single module there.

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

> The `universal:2` base is multi-GB, so the first build pulls a large image and can take
> several minutes.

## Notes

- API keys for agentic engines (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`) are
  best set as **Codespace secrets** at `github.com/settings/codespaces` so they're available
  automatically.
- `*.lock.yml` files are associated with the GitHub Actions workflow schema for syntax help.
