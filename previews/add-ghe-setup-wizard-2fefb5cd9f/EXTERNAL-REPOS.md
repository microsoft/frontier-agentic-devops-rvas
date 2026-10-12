# External repositories and pinned references

Course content lives in this repository. You do not need access to private predecessor
repositories. Fetch external apps and labs only for activities that need them.

## Dependency rules

- Module content lives under `modules/*/resources/` and `modules/*/challenges/`.
- Juice Shop and the Azure SRE Agent starter lab are submodules pinned to exact commits. Fetch them when needed.
- Document and validate each commit SHA and tag.
- Keep only active course dependencies in `external-repos.json`.

## External dependencies

### OWASP Juice Shop

- **Source:** https://github.com/juice-shop/juice-shop
- **Pinned ref:** `v20.0.0` (tag) = commit `f356a09207c7a9550eb6fc4c3945e081922cf998`
- **Used by:** GHAS setup, developer activities, and the four admin fixture provisioners
- **Import mode (org repo):** The GHAS setup script (`setup.sh provision`) imports the repo into an org-owned GitHub repository named `ghec-ghas-00-juice-shop`. GHAS alerts run on *that* org repo.
- **Local runtime.** GHAS activities use a local Juice Shop instance for manual exploit testing. **GHAS scans the org repository, not this local instance.** See [Local app provisioning (submodules)](#local-app-provisioning-submodules).
- **Why Juice Shop is large but not vendored:** At ~61 MB it would bloat the curriculum repo and slow container creation for participants who never need it. It is registered as a git submodule and fetched on demand.

### Azure SRE Agent starter lab

- **Source:** https://github.com/microsoft/sre-agent
- **Pinned ref:** commit `673f88765b27d4a74ebc660875bf605a382b6d28`
- **Used by:** SRE Agent activities 00, 01, 03, 04, and 05
- **Local runtime:** The full upstream repo is registered as `external/sre-agent`; the lab commands use `external/sre-agent/labs/starter-lab`.
- **Why it is a submodule:** The official Microsoft lab stays tied to a specific upstream commit without vendoring the full repository into this curriculum repo.

## Import modes

### In-tree content

Module content and support assets are included in this repository.

- Participants do not need to fetch this content separately.
- Organisers run `npm run verify:repos` to confirm vendored paths are intact.

### Submodules

Fetch large external apps or labs when an activity needs them:

```bash
npm run setup:juice-shop
npm run setup:sre-agent-lab
```

The commands fetch each submodule at its pinned SHA. Juice Shop setup also creates the
`app` symlink. The SRE Agent lab helper prints the `labs/starter-lab` path.

### GHAS repository imports

GHAS setup imports Juice Shop at `v20.0.0` into an org repository named
`ghec-ghas-00-juice-shop`:

```bash
# Creates <org>/ghec-ghas-00-juice-shop with Juice Shop imported
cd modules/ghec/resources/provisioning/scripts
./setup.sh provision ghas-00 --org <org>
```

The script adds CodeQL and Dependabot configuration and attempts to enable GHAS features.
Repository admins add participants who need access. Participants clone and push to this
repository, and GitHub Advanced Security scans it. It is a disposable activity target,
not a submodule.

The Admin & Governance track uses four isolated imports under
`modules/ghas/resources/provisioning/challenges/`:

| Activities | Default repository |
| --- | --- |
| `ghas-admin-01`, `ghas-admin-06` | `ghas-admin-01-06-security-operations` |
| `ghas-admin-02` | `ghas-admin-02-secret-operations` |
| `ghas-admin-03`, `ghas-admin-04` | `ghas-admin-03-04-codeql-live-lab` |
| `ghas-admin-05` | `ghas-admin-05-dependency-visibility-fixture` |

Each provisioner imports the pinned Juice Shop tag when it needs a new repository.
Use its `status` command to inspect the fixture. The provisioners keep separate
ownership and teardown rules instead of using one broad setup command.

## Pinned references and validation

### Validate references

Organisers and curriculum maintainers run:

```bash
npm run verify:repos           # Validates challenge metadata against external-repos.json + vendored paths
npm run verify:repos:external  # Confirms Juice Shop ref is reachable; skips retired entries
npm run audit:external         # Optional content URL audit
```

`verify:repos:external` checks only active external dependencies that participants or maintainers may need to fetch.

### Update a pinned reference

If a new version of Juice Shop or another active dependency is needed:

1. Update `external-repos.json` with the new tag or full SHA.
2. For submodules, run `cd external/<name> && git fetch --depth 1 origin <new-sha> && git checkout <new-sha>`, then `git add external/<name>` in the repo root.
3. Run `npm run verify:repos` and `npm run verify:repos:external` to confirm the manifest SHA and gitlink match.
4. Document breaking changes in the activity's `README.md`.
5. Run `npm run build` to regenerate catalogs with the new references.

> **Update the tag and SHA together.** `external-repos.json` stores both.
> Git submodules track the SHA. `npm run verify:repos` checks that the gitlink SHA
> matches `source.sha`.

## Local app provisioning (submodules)

Local apps and labs use git submodules pinned in `.gitmodules` and the git index.
Participants fetch them when needed, so container creation does not wait for unused labs.

### How it works

```
external/
  juice-shop/          ← git submodule, pinned to f356a09... (v20.0.0)
  sre-agent/           ← git submodule, pinned to 673f887... (starter lab source)
app -> external/juice-shop   ← committed symlink, stable path for challenge instructions
```

`external-repos.json` carries a `provisioning` block for each submodule-backed app:
```json
"provisioning": {
  "method": "submodule",
  "submodule_path": "external/juice-shop",
  "symlinks": ["app"],
  "npm_script": "setup:juice-shop"
}
```

### Fetch Juice Shop

GHAS participants run this once after the container starts:
```bash
npm run setup:juice-shop
```

The script (`scripts/provision-app.sh`):
1. Runs `git submodule update --init --depth 1 -- external/juice-shop`.
2. Checks that the HEAD SHA matches the manifest `source.sha` and fails if it differs.
3. Creates the `app` symlink to `external/juice-shop` if needed.
4. Prints the command to install and run the app, `cd app && npm install && npm start`.

> **GHAS scans the shared org repository.** The local submodule runs the app for manual testing.
> CodeQL, Dependabot, and secret scanning alerts belong to the repository your organizer provisions.

### Fetch the SRE Agent starter lab

SRE Agent participants run this once before the live Azure lab commands:
```bash
npm run setup:sre-agent-lab
```

The npm script uses the same manifest-driven provisioner as Juice Shop:
1. Runs `bash scripts/provision-app.sh grubify-starter-lab`
2. Fetches `external/sre-agent` as a pinned lazy submodule
3. Verifies the checked-out HEAD SHA equals the manifest `source.sha`
4. Verifies the manifest `provisioning.content_path` exists

Then enter the lab:
```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
```

For automation, `modules/sre-agent/resources/scripts/ensure-starter-lab.sh` calls the same
provisioner and prints the absolute lab directory.

### Fresh clones and existing clones

For a fresh clone, participants can choose either lazy or eager submodule fetching:

```bash
# Lazy: fastest initial clone; fetch each lab/app only when needed.
git clone https://github.com/microsoft/frontier-agentic-devops-rvas.git
cd frontier-agentic-devops-rvas
npm run setup:juice-shop        # when GHAS local runtime is needed
npm run setup:sre-agent-lab     # when SRE Agent starter lab is needed

# Eager: fetch all registered submodules during clone.
git clone --recurse-submodules https://github.com/microsoft/frontier-agentic-devops-rvas.git
```

For an existing clone after pulling curriculum updates:

```bash
git pull --recurse-submodules
git submodule update --init --recursive --depth 1
```

### Drift prevention

`npm run verify:repos` asserts that, for every `provisioning.method == "submodule"` entry:
- `.gitmodules` contains a URL for the declared `submodule_path`
- The `.gitmodules` URL matches `external-repos.json`
- The gitlink SHA in the index matches `source.sha`
- If the submodule is checked out, the HEAD SHA also matches

`npm run build` and the content audit scripts validate in-tree course content.

### Adding a new local app (for maintainers)

1. Add the submodule: `git submodule add --depth 1 <url> external/<name>` then check out the pinned SHA.
2. Set `shallow = true` in `.gitmodules`.
3. Create the committed symlink(s) if activity instructions expect a stable path.
4. Add a `provisioning` block in `external-repos.json` (same schema as `juice-shop`).
5. Add an npm script `setup:<name>` in `package.json` pointing to `provision-app.sh <key>`.
6. Run `npm run verify:repos` to confirm drift check passes.
7. Document in this file and in the relevant activity's `README.md`.

## Dependencies by module

### GHAS

- Juice Shop is pinned at `v20.0.0`.
- GHAS source material lives under `modules/ghas/`. The build and content audit validate it.
- `bkimminich/juice-shop` is the fallback Docker image for local runs.

### GHAW

GHAW source material lives under `modules/ghaw/`, with provenance commit
`9f0957ed3be978b2143c7048f5396183ad189d6e`. The activities need no deployed app.

### SRE Agent

The Azure SRE Agent starter lab is a pinned submodule at `external/sre-agent`.
Use its `labs/starter-lab` directory. Delivery team members provision Azure resources
in their own subscription.

### GHEC

GHEC provisioning scripts live under `modules/ghec/resources/provisioning/`.
Some activities need no external app, such as authentication, team roles, and org governance.

## Local and shared resources

### GHAS environments

- **Local Juice Shop** (Docker or devcontainer)
  - Used for **manual exploit testing** in activities
  - Started with `cd app && npm start` or `docker run bkimminich/juice-shop`
  - Runs on port 3000
  - Does not have GHAS alerts

- **Shared org repository** (GitHub repo in the organization)
  - CodeQL, Dependabot, secret scanning run **here**
  - Customer delivery team members clone or work on branches
  - Alerts, security features, and all GHAS configuration are **org/repo-scoped**
  - "GHAS" refers to the alerts and features on this shared repo, not the local Juice Shop runtime

### SRE Agent local sample app

The app at `modules/sre-agent/resources/sample-app/` runs locally or in Codespaces.
Use it for incident simulation and agent response testing. It needs no external deployment.

## Maintenance and support

### For maintainers

- Keep pinned refs stable across a curriculum release cycle.
- Keep `external-repos.json` limited to active external repositories used by the course.
- When external projects release major versions, evaluate and document breaking changes before updating the pin.
- Test setup scripts (`setup.sh provision`) against the pinned refs in a CI/CD gate or manual verification step.
- Validate that Juice Shop ref is reachable before running a cohort (run `npm run verify:repos:external`).
- Retired Microsoft repos do not need to be reachable; the verify script skips them automatically.

### For delivery team members

- Follow setup instructions in each activity's `README.md`.
- All module content is in-tree; you do not need to clone or fork the retired upstream repos.
- If setup fails to pull Juice Shop, check your GitHub token scopes and network access.
- Report setup failures via your delivery session organizer.
- Keep other delivery team members informed if external services (GitHub, Docker Hub) have outages.

## See also

- [Build, validate, and deploy the curriculum](../README.md).
- [Author activities and edit meta.yml](../CONTRIBUTING.md).
- [Activity directory structure](../modules/README.md).
