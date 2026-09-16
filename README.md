# Agentic DevSecOps

One GitHub Pages curriculum with five outcome paths, four delivery-session modules, and 87 activities.

> **Bring your own.** These activities are built to run on **your** tenant — work each one
> against your own applications, repositories, and data so the result keeps running in
> production after the session, not just as an upskilling exercise. The sample apps
> (OWASP Juice Shop, the Grubify sample, seed repos) are only a fallback so no one is
> blocked. Wherever a activity says "bring your own," start from your real work; the
> setup script and sample are there when you don't yet have a candidate.

## Outcomes

**Choose an outcome** to see its activities in delivery order. Without an outcome
selected, the catalog and session builder group activities by session type.
Product names appear on the cards.
Outcome headings reuse the homepage summaries; session-type headings use the track descriptions.

| Outcome ID | Purpose |
|---|---|
| `github-adoption` | Standardize software delivery. |
| `platform-migration` | Migrate development platforms. |
| `ghas-adoption` | Strengthen application security. |
| `agentic-workflows` | Automate development tasks with AI. |
| `agentic-devops-cloud` | Improve incident response. |

## Modules

| Module ID | Name | Activities | Tracks |
|---|---|---|---|
| `ghec` | GitHub Enterprise Cloud | 49 | Developer Flow, Admin & Governance, Security, Automation & AI, Migration |
| `ghas` | GitHub Advanced Security | 13 | Admin & Governance, Developer Flow |
| `ghaw` | GitHub Agentic Workflows | 20 | Hello, Agent, Repo Concierge, Continuous Intelligence, Production Patterns |
| `sre-agent` | SRE Agent | 5 | Azure SRE Agent |

> **Total:** 87 activities across 4 modules.

## Architecture

```
modules/<moduleId>/challenges/<slug>/
  meta.yml      ← single source of truth (build reads ONLY this)
  README.md     ← customer delivery team guide
        │
        ▼
  node docs/build.js
        │
        ▼
docs/assets/data/
  platform.json              ← full catalog (modules + challenges)
  dependency-graph.json      ← prereq graph (nodes + edges)
  challenges/<id>/README.md  ← copied customer delivery team guide (served by Pages)
```

The build script is the **only bridge** between content metadata, outcome journeys, and the rendered site. Never hand-copy metadata.

## Building Locally

**Prerequisites:** Node.js ≥ 18. No npm install required.

```bash
npm run build
node --test scripts/test-catalog-grouping.js
```

Output lands in `docs/assets/data/`. The Pages site (`docs/`) is fully self-contained.

### Verified output

```
✓ built platform.json  (modules: 4, challenges: N)
✓ built dependency-graph.json  (nodes: N, edges: N)
✓ copied delivery guides → docs/assets/data/challenges/
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
- Every `prerequisites` entry references a real activity `id` in the catalog.
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
See [`docs/EXTERNAL-REPOS.md`](docs/EXTERNAL-REPOS.md) for how external dependencies (Juice Shop, sample apps, third-party delivery sessions) are managed and pinned.  
Use `modules/_TEMPLATE/challenge/` as your starting point for new activities.

## Deploy

GitHub Actions (`.github/workflows/build-deploy.yml`) runs `node docs/build.js` on every push to `main` and deploys `docs/` to GitHub Pages automatically.

## License

MIT License — Copyright (c) Microsoft Corporation. See [`LICENSE`](LICENSE).  
