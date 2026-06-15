# The Frontier GitHub Platform Hackathon

One repo. One GitHub Pages site. Four hackathon modules, 57 challenges, zero configuration drama.

## Modules

| Module ID | Name | Challenges | Tracks |
|---|---|---|---|
| `ghec` | GitHub Enterprise Cloud | 20 | Developer Flow, Admin & Governance, Security, Automation & AI |
| `ghas` | GitHub Advanced Security | 6 | Security Fundamentals |
| `ghaw` | GitHub Agentic Workflows | 24 | Hello Agent, MCP Integration, Production Patterns, Safe Outputs |
| `agentic-devops` | Agentic DevOps & Azure SRE | 7 | Agentic Arc |

> **Total:** 57 challenges across 4 modules.

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

The build script is the **only bridge** between content metadata and the rendered site. Never hand-copy metadata.

## Building Locally

**Prerequisites:** Node.js ≥ 18. No npm install required.

```bash
node docs/build.js
```

Output lands in `docs/assets/data/`. The Pages site (`docs/`) is fully self-contained.

### Verified output

```
✓ built platform.json  (modules: 4, challenges: N)
✓ built dependency-graph.json  (nodes: N, edges: N)
✓ copied student/coach guides → docs/assets/data/challenges/
```

Exit code 0 = success. Non-zero = validation errors (check stderr).

## Validation

The build validates:
- Every `prerequisites` entry references a real challenge `id` in the catalog.
- No circular dependencies.
- Warns on missing optional fields.

CI runs the same build on every PR and fails the check if validation errors are found.

## Contributing Content

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the `meta.yml` field contract and authoring guide.  
See [`modules/README.md`](modules/README.md) for the module and directory layout.  
Use `modules/_TEMPLATE/challenge/` as your starting point for new challenges.

## Deploy

GitHub Actions (`.github/workflows/build-deploy.yml`) runs `node docs/build.js` on every push to `main` and deploys `docs/` to GitHub Pages automatically.

## License

MIT License — Copyright (c) Microsoft Corporation. See [`LICENSE`](LICENSE).  
Content sourced from four Microsoft hackathon repositories under MIT license.  
See each module's `ATTRIBUTION.md` for source provenance.
