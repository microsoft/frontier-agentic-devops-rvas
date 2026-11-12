# Agentic DevSecOps

**Learn by doing** through four outcomes and three modules,
or **set up GitHub** with the GitHub Enterprise setup skill.

The [setup overview](docs/github-setup.html) explains what the skill covers. The
[setup guide](docs/github-setup-guide.html) walks through installation and use.
For hands-on activities, use the catalog and session builder.

> **Use your own environment.** Work with your own applications, repositories, and data
> so your team keeps the result after the session. If you don't have a suitable
> application, use OWASP Juice Shop or the seed repositories.

## Outcomes

**Pick an outcome to see its activities.** Filter by session type, or build a custom set
for your team. Migration activities cover different source platforms; pick yours.

Use one customer repository or service across the selected activities, and check
prerequisites first. Shared sets keep the builder's activity order.

With no outcome selected, the catalog groups all active activities by session type.

| Outcome ID | Purpose |
|---|---|
| `github-adoption` | Standardize software delivery. |
| `platform-migration` | Migrate development platforms. |
| `ghas-adoption` | Strengthen application security. |
| `agentic-workflows` | Automate development tasks with AI. |

## Modules

| Module ID | Name | Activities | Tracks |
|---|---|---|---|
| `ghec` | GitHub Enterprise Cloud | 41 | Developer Flow, Admin & Governance, Security, Automation & AI, Migration |
| `ghas` | GitHub Advanced Security | 9 | Admin & Governance, Developer Flow |
| `ghaw` | GitHub Agentic Workflows | 7 | Getting Started, Pull Requests & Issues, Repository Operations |

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

The build generates the site data from activity metadata and outcomes. Don't copy metadata by hand.

**Edit the top bar in `docs/_partials/header.html`.** The build copies it into every page. Keep page-specific navigation in the page itself.

## Build locally

You need Node.js ≥ 18. No npm install is required.

```bash
npm run build
node --test scripts/test-catalog-grouping.js
```

The build writes to `docs/assets/data/`. The Pages site has all its files under `docs/`.

### Verified output

```
✓ built platform.json  (modules: 3, outcomes: 4, challenges: N)
✓ built dependency-graph.json  (nodes: N, edges: N)
✓ copied delivery guides → docs/assets/data/challenges/
```

The build exits with 0 on success. On a non-zero exit, check stderr for validation errors.

## Set up GitHub

Install the [GitHub Enterprise setup plugin](plugins/github-enterprise-setup/README.md)
in GitHub Copilot CLI. You need `gh`, `jq`, and authenticated access to an existing
GitHub Enterprise Cloud account. After the plugin and marketplace are published:

```bash
copilot plugin marketplace add microsoft/frontier-agentic-devops-rvas
copilot plugin install github-enterprise-setup@frontier-agentic-devops
copilot
```

Tell Copilot to use `github-enterprise-setup`, name your enterprise and host,
and describe the outcome. The skill starts in **Plan**: it checks the current state
and recommends changes. Review the saved plan before requesting Apply.
You approve each write batch; high-impact changes need a separate confirmation.

The plugin replaces the Bash wizard. Don't resume old wizard runs; start a new skill plan.
The skill doesn't run the lab provisioners. **Live end-to-end validation is still
pending.** The plugin guide covers local installation and release checks.

## External labs and submodules

Large lab dependencies are pinned as git submodules and fetched only when needed.
A normal `git clone` is enough for the curriculum site. To fetch Juice Shop:

```bash
npm run setup:juice-shop
```

To prefetch everything during clone, use `git clone --recurse-submodules <repo>`. For an existing clone after pulling updates, run `git submodule update --init --recursive --depth 1`. See [`docs/EXTERNAL-REPOS.md`](docs/EXTERNAL-REPOS.md) for the full refresh and pin-bump workflow.

## Validation

The build checks that every `prerequisites` entry references an activity `id` in the
active catalog and that dependencies contain no cycles. It also checks outcome membership
and link targets. It warns about missing optional fields.

Run the content audits with:

```bash
npm run audit          # check content facts without network calls
npm run audit:content  # rebuild, then audit generated catalog/link consistency
npm run test:setup-plugin  # check marketplace, package, and bundled references
```

The ruleset monitor and workflow starters use Python 3. Run their tests with:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s modules/ghec/resources/drift -p 'test_*.py'
PYTHONDONTWRITEBYTECODE=1 python3 -S modules/ghec/resources/ci/test_workflows.py
PYTHONDONTWRITEBYTECODE=1 python3 -S modules/ghec/resources/release/test_release.py
PYTHONDONTWRITEBYTECODE=1 python3 -S modules/ghec/resources/intake/test_provision.py
```

`npm run audit:external` probes external URLs but only warns, so flaky links don't fail CI.

CI runs the same build on every PR and fails the check on validation errors.

## Contribute content

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the `meta.yml` field contract and authoring guide.  
See [`modules/README.md`](modules/README.md) for the module and directory layout.  
See [`docs/EXTERNAL-REPOS.md`](docs/EXTERNAL-REPOS.md) for how external dependencies (Juice Shop, sample apps, third-party delivery sessions) are managed and pinned.  
Use `modules/_TEMPLATE/challenge/` as your starting point for new activities.

## Deploy

GitHub Actions (`.github/workflows/build-deploy.yml`) builds and deploys the site on
pushes to `main`. Other branches and same-repository pull requests get a
**preview under `previews/`**, while the site root keeps the latest `main` content.
The workflow posts the preview link in its run summary and updates one comment on
each pull request. Fork pull requests run validation only.

The workflow creates `gh-pages` on the first preview build and stores previews
there so later deployments preserve them.

**Repository settings:** keep Settings > Pages > Source set to **GitHub Actions**.
In Settings > Environments > `github-pages`, allow preview branches and PR refs
under **Deployment branches and tags**; a `main`-only rule blocks previews. Keep
`main`, add the branch names or patterns you want to preview, and add
`refs/pull/*/merge` for PR deployments. Repository rules must also permit the
workflow's `GITHUB_TOKEN` to create and update `gh-pages`.

## License

MIT License. Copyright (c) Microsoft Corporation. See [`LICENSE`](LICENSE).
