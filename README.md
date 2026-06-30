# Agentic DevOps

One repo. One GitHub Pages site. Five outcome journeys, four hackathon modules, 64 challenges, zero configuration drama.

## Outcomes

The site is organized around business outcomes first, then platform modules:

| Outcome ID | Purpose |
|---|---|
| `github-adoption` | Streamline adoption of GitHub Enterprise Cloud as the enterprise developer platform. |
| `platform-migration` | Move projects from Azure DevOps, Bitbucket, GitLab, or other platforms to GitHub. |
| `ghas-adoption` | Adopt GitHub Advanced Security as a repeatable secure-development operating model. |
| `agentic-workflows` | Start using reviewable, safe agentic workflows on GitHub. |
| `agentic-devops-cloud` | Connect GitHub, Azure, and agents into an end-to-end DevOps and SRE loop. |

## Modules

| Module ID | Name | Challenges | Tracks |
|---|---|---|---|
| `ghec` | GitHub Enterprise Cloud | 27 | Developer Flow, Admin & Governance, Security, Automation & AI, Migration |
| `ghas` | GitHub Advanced Security | 7 | Security |
| `ghaw` | GitHub Agentic Workflows | 25 | Hello, Agent, Repo Concierge, Continuous Intelligence, Production Patterns |
| `sre-agent` | SRE Agent | 5 | Azure SRE Agent |

> **Total:** 64 challenges across 4 modules.

## Architecture

```
modules/<moduleId>/challenges/<slug>/
  meta.yml      ← single source of truth (build reads ONLY this)
  README.md     ← student guide
  COACH.md      ← coach guide (facilitator notes, expected outputs, hints)
        │
        ▼
  node docs/build.js
        │
        ▼
docs/assets/data/
  platform.json              ← full catalog (modules + challenges)
  dependency-graph.json      ← prereq graph (nodes + edges)
  challenges/<id>/README.md  ← copied student guide (served by Pages)
  challenges/<id>/COACH.md   ← copied coach guide
```

The build script is the **only bridge** between content metadata, outcome journeys, and the rendered site. Never hand-copy metadata.

## Building Locally

**Prerequisites:** Node.js ≥ 18. No npm install required.

```bash
npm run build
```

Output lands in `docs/assets/data/`. The Pages site (`docs/`) is fully self-contained.

### Verified output

```
✓ built platform.json  (modules: 4, challenges: N)
✓ built dependency-graph.json  (nodes: N, edges: N)
✓ copied student/coach guides → docs/assets/data/challenges/
```

Exit code 0 = success. Non-zero = validation errors (check stderr).

## External Labs and Submodules

Large local lab dependencies are pinned as lazy git submodules. A normal `git clone` is enough for the curriculum site; fetch each lab only when needed:

```bash
npm run setup:juice-shop
npm run setup:sre-agent-lab
```

To prefetch everything during clone, use `git clone --recurse-submodules <repo>`. For an existing clone after pulling updates, run `git submodule update --init --recursive --depth 1`. See [`docs/EXTERNAL-REPOS.md`](docs/EXTERNAL-REPOS.md) for the full refresh and pin-bump workflow.

## Validation

The build validates:
- Every `prerequisites` entry references a real challenge `id` in the catalog.
- No circular dependencies.
- Warns on missing optional fields.

Additional deterministic content audits are available:

```bash
npm run audit          # validate factuality surfaces without network calls
npm run audit:content  # rebuild, then audit generated catalog/link consistency
```

`npm run audit:external` can probe external URLs, but reports them as warnings only to avoid flaky CI gates.

CI runs the same build on every PR and fails the check if validation errors are found.

## Contributing Content

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the `meta.yml` field contract and authoring guide.  
See [`modules/README.md`](modules/README.md) for the module and directory layout.  
See [`docs/EXTERNAL-REPOS.md`](docs/EXTERNAL-REPOS.md) for how external dependencies (Juice Shop, sample apps, third-party hackathons) are managed and pinned.  
Use `modules/_TEMPLATE/challenge/` as your starting point for new challenges.

## Deploy

GitHub Actions (`.github/workflows/build-deploy.yml`) runs `node docs/build.js` on every push to `main` and deploys `docs/` to GitHub Pages automatically.

## License

MIT License — Copyright (c) Microsoft Corporation. See [`LICENSE`](LICENSE).  
