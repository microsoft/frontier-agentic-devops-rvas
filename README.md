# Agentic DevSecOps

Choose **learn by doing** through five outcomes and four delivery-session modules,
or **set up GitHub** with the GitHub Enterprise setup skill.

The portal's home page presents both routes. The [setup overview](docs/github-setup.html)
explains the skill's scope; the [setup guide](docs/github-setup-guide.html) covers
installation and the guided workflow. The hands-on catalog and session builder remain available.

> **Use your own environment.** Work with your own applications, repositories, and data
> so your team can keep using the result after the session. Use OWASP Juice Shop, Grubify,
> or seed repositories when you do not have a suitable application.
> Where an activity says "bring your own," start with your team's work.

## Outcomes

**Choose an outcome to see its activities.** Use the session-type filters to narrow
the list, or build a custom set for your team. Migration chapters cover different
source platforms; select the one you use.

Keep one customer repository or service throughout the selected activities. Reuse
approved controls and check prerequisites before starting. The session builder
preserves chapter order in shared sets.

Without an outcome selected, the catalog groups all active activities by session type.

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
| `ghec` | GitHub Enterprise Cloud | 41 | Developer Flow, Admin & Governance, Security, Automation & AI, Migration |
| `ghas` | GitHub Advanced Security | 9 | Admin & Governance, Developer Flow |
| `ghaw` | GitHub Agentic Workflows | 7 | Getting Started, Pull Requests & Issues, Repository Operations |
| `sre-agent` | SRE Agent | 4 | Azure SRE Agent |

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

The build script generates the site data from activity metadata and outcome journeys.
Do not copy metadata by hand.

**Edit the top bar in `docs/_partials/header.html`.** The build copies this shared
header into every site page. Keep page-specific navigation in the page content.

## Build locally

You need Node.js ≥ 18. No npm install is required.

```bash
npm run build
node --test scripts/test-catalog-grouping.js
```

The build writes to `docs/assets/data/`. The Pages site has all its files under `docs/`.

### Verified output

```
✓ built platform.json  (modules: 4, challenges: N)
✓ built dependency-graph.json  (nodes: N, edges: N)
✓ copied delivery guides → docs/assets/data/challenges/
```

The build exits with code 0 on success. For a non-zero exit code, check stderr for validation errors.

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
and describe the outcome. The skill starts **Plan**. It checks current state
and recommends changes. Review the saved plan before requesting Apply.
Each write batch needs approval; high-impact work has a separate confirmation.

The plugin replaces the Bash wizard. Legacy wizard run files remain reference
material; start a new skill plan rather than resuming them. The skill does not
run the curriculum's lab provisioners. **Live end-to-end setup validation is still
pending.** See the plugin guide for local installation and the release checks.

## External labs and submodules

Large local lab dependencies are pinned as lazy git submodules. A normal `git clone` is enough for the curriculum site; fetch each lab only when needed:

```bash
npm run setup:juice-shop
npm run setup:sre-agent-lab
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

`npm run audit:external` can probe external URLs, but reports them as warnings only to avoid flaky CI gates.

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
