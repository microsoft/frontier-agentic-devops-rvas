# External Repositories & Pinned References

This guide explains how this delivery session curriculum manages external dependencies, source apps, and third-party tools. Course content lives in this repository; private predecessor repositories are not required or referenced by the course.

## Philosophy

- **Content lives in-tree** — course modules are embedded under `modules/*/resources/` and `modules/*/challenges/`; no participant or organiser needs a private upstream repo.
- **Local app dependencies managed as lazy submodules** — Juice Shop and the Azure SRE Agent starter lab are registered at exact commits but fetched only when needed.
- **Explicit pinning** — all refs (commit SHAs, tags) are documented and validated.
- **External repo references stay current** — `external-repos.json` lists only active external repositories required by the course.

## External Dependencies

### OWASP Juice Shop

- **Source:** https://github.com/juice-shop/juice-shop
- **Pinned ref:** `v20.0.0` (tag) = commit `f356a09207c7a9550eb6fc4c3945e081922cf998`
- **Used by:** GHEC challenges (ch11–ch15), GHAS setup
- **Import mode (org repo):** Challenge setup scripts (`setup.sh provision`) import the repo into org-owned GitHub repositories — each challenge gets its own isolated, disposable copy (e.g., `ghec-ch11-juice-shop`, `ghec-ghas-00-juice-shop`). GHAS alerts run on *that* org repo.
- **Local runtime (GHAS participants):** GHAS challenges also run Juice Shop locally for manual exploit testing. This local instance has **no GHAS alerts** — it is the app only, not the security-scanning target. See *[Local app provisioning (submodules)](#local-app-provisioning-submodules)* below for how to get it running.
- **Why Juice Shop is large but not vendored:** At ~61 MB it would bloat the curriculum repo and slow container creation for participants who never need it. It is registered as a git submodule and fetched on demand.

### Azure SRE Agent starter lab

- **Source:** https://github.com/microsoft/sre-agent
- **Pinned ref:** commit `673f88765b27d4a74ebc660875bf605a382b6d28`
- **Used by:** SRE Agent challenges 00, 01, 03, 04, and 05
- **Local runtime:** The full upstream repo is registered as `external/sre-agent`; the lab commands use `external/sre-agent/labs/starter-lab`.
- **Why it is a submodule:** The official Microsoft lab stays tied to a specific upstream commit without vendoring the full repository into this curriculum repo.

## Import Modes

### In-Tree (Vendored)

**When:** Module content and support assets are included directly in this repository.

- No participant action required — content is already in this repo.
- Organisers run `npm run verify:repos` to confirm vendored paths are intact.

### Submodule (Lazy / On-Demand)

**When:** A large external app or lab repo is needed at runtime but should not bloat the repo.

- **Flow:**
  ```bash
  npm run setup:juice-shop
  npm run setup:sre-agent-lab
  ```
- **Outcome:** The submodule is fetched at the pinned SHA. Juice Shop also creates the `app` symlink; the SRE Agent lab helper prints the `labs/starter-lab` path.

### Import (One-Time Setup — GHEC/GHAS)

**When:** A challenge setup script creates a GitHub repository with external content imported.

- **Example:** GHEC/GHAS challenges — setup scripts import Juice Shop at `v20.0.0` into a new org repo (e.g., `ghec-ch11-juice-shop` or `ghec-ghas-00-juice-shop`).
- **Flow:**
  ```bash
  # Creates <org>/ghec-ch11-juice-shop with Juice Shop imported
  cd modules/ghec/resources/provisioning/scripts
  ./setup.sh provision ghas-00 --org <org>
  ```
- **Outcome:** New repo exists in the student's/team's/organizer's org; for GHAS S00 the script also seeds CodeQL/Dependabot config and attempts to enable GHAS features. Repo admins manually add any participants who need access.
- **Not a submodule:** These repos are disposable challenge targets that participants clone and push to, and that GitHub Advanced Security scans. They intentionally remain normal GitHub repositories.

## Pinned References & Validation

### How to Validate Refs

Organisers and curriculum maintainers run:

```bash
npm run verify:repos           # Validates challenge metadata against external-repos.json + vendored paths
npm run verify:repos:external  # Confirms Juice Shop ref is reachable; skips retired entries
npm run audit:external         # Optional content URL audit
```

`verify:repos:external` checks only active external dependencies that participants or maintainers may need to fetch.

### Updating a Pinned Reference

If a new version of Juice Shop or another active dependency is needed:

1. **Coordinate with curriculum**: Update `external-repos.json` with the new ref (tag and/or full SHA).
2. **Bump the submodule pointer** (for submodule-backed apps): `cd external/<name> && git fetch --depth 1 origin <new-sha> && git checkout <new-sha>`, then `git add external/<name>` in the repo root.
3. **Test**: Run `npm run verify:repos` and `npm run verify:repos:external` to confirm the manifest SHA and gitlink are in sync.
4. **Document**: Add a note to the challenge's `COACH.md` if the new ref introduces breaking changes.
5. **Rebuild**: Run `npm run build` to regenerate catalogs with the new refs.

> **Tag vs. SHA nuance:** `external-repos.json` stores both the friendly tag (`v20.0.0`) and the exact commit SHA. Git submodules track the SHA only — the tag is purely for human reference. The drift check (`npm run verify:repos`) asserts the gitlink SHA equals `source.sha`; always update both together.

## Local App Provisioning (Submodules)

Locally-run apps and labs (things participants start in their Codespace or dev container) are managed as **lazy git submodules**. Each submodule is *registered* (`.gitmodules` + gitlink) in this repo at the pinned commit, but the actual clone is deferred to when a participant first needs it. This keeps container creation fast for participants who don't use that module.

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

### Fetching Juice Shop (participants)

GHAS participants run this once after the container starts:
```bash
npm run setup:juice-shop
```

The script (`scripts/provision-app.sh`):
1. Runs `git submodule update --init --depth 1 -- external/juice-shop` (shallow, fast)
2. Verifies the checked-out HEAD SHA equals the manifest `source.sha` (fails loudly on drift)
3. Ensures the `app → external/juice-shop` symlink exists
4. Prints next steps: `cd app && npm install && npm start`

> **This submodule is the LOCAL RUNTIME only.** It does NOT replace the org-imported repository that carries the GHAS alerts (CodeQL, Dependabot, secret scanning). Those run on the shared org repo your organizer provisions. Never confuse the two.

### Fetching the SRE Agent starter lab (participants)

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

For automation that needs to capture the lab path, `modules/sre-agent/resources/scripts/ensure-starter-lab.sh` is a thin wrapper around the same provisioner and prints the absolute lab directory.

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

In-tree course content is validated by `npm run build` and the content audit scripts.

### Adding a new local app (for maintainers)

1. Add the submodule: `git submodule add --depth 1 <url> external/<name>` then check out the pinned SHA.
2. Set `shallow = true` in `.gitmodules`.
3. Create the committed symlink(s) if challenge instructions expect a stable path.
4. Add a `provisioning` block in `external-repos.json` (same schema as `juice-shop`).
5. Add an npm script `setup:<name>` in `package.json` pointing to `provision-app.sh <key>`.
6. Run `npm run verify:repos` to confirm drift check passes.
7. Document in this file and in the relevant challenge's `README.md`.

## Dependency Families

### GHAS Dependency Family

- **Juice Shop** (OWASP app) — pinned at `v20.0.0`
- **GHAS source material** — vendored in-tree at `modules/ghas/resources/`; provenance commit `4abc7439f0cab329b659263845e20139fbbe5359`
- **Local Docker image** — `bkimminich/juice-shop` (used as fallback for quick local runs)

### GHAW Dependency Family

- **GHAW source material** — vendored in-tree at `modules/ghaw/`; provenance commit `9f0957ed3be978b2143c7048f5396183ad189d6e`
- **No app** — challenges focus on workflow authoring, not a deployed service

### SRE Agent Dependency Family

- **Azure SRE Agent starter lab** — pinned lazy submodule at `external/sre-agent`, lab path `labs/starter-lab`
- **Azure** (runtime target) — students provision their own (not pinned, varies by subscription)

### GHEC Dependency Family

- **Juice Shop** (for ch11–ch15) — pinned at `v20.0.0`
- **GHEC provisioning machinery** — vendored in-tree at `modules/ghec/resources/provisioning/`
- **Varies** — some challenges use no external app (auth, team roles, org governance)

## Local Runtime vs. Shared/Remote Resources

### GHAS: Two Environments

- **Local Juice Shop** (Docker or devcontainer)
  - Used for **manual exploit testing** in challenges
  - Started with `cd app && npm start` or `docker run bkimminich/juice-shop`
  - Runs on port 3000
  - No GHAS alerts here — it's just the app

- **Shared org repository** (GitHub repo in the organization)
  - CodeQL, Dependabot, secret scanning run **here**
  - Students clone or work on branches
  - Alerts, security features, and all GHAS configuration are **org/repo-scoped**
  - "GHAS" refers to the alerts and features on this shared repo, not the local Juice Shop runtime

### SRE Agent: Local Sample App

- **Runs locally** in the student environment (or Codespaces)
- **No external deploy needed** — included at `modules/sre-agent/resources/sample-app/`
- **Used for incident simulation** and agent response testing

## Maintenance & Support

### For Maintainers

- Keep pinned refs stable across a curriculum release cycle.
- Keep `external-repos.json` limited to active external repositories used by the course.
- When external projects release major versions, evaluate and document breaking changes before updating the pin.
- Test setup scripts (`setup.sh provision`) against the pinned refs in a CI/CD gate or manual verification step.

### For Students

- Follow setup instructions in each challenge's `README.md` or `COACH.md`.
- All module content is in-tree; you do not need to clone or fork the retired upstream repos.
- If setup fails to pull Juice Shop, check your GitHub token scopes and network access.
- Report setup failures via your delivery session organizer so coaches can investigate.

### For Coaches

- Validate that Juice Shop ref is reachable before running a cohort (run `npm run verify:repos:external`).
- Retired Microsoft repos do not need to be reachable; the verify script skips them automatically.
- Keep students informed if external services (GitHub, Docker Hub) have outages.

## See Also

- [README.md](../README.md) — Build, validate, and deploy the curriculum.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — Authoring challenges and meta.yml field reference.
- [modules/README.md](../modules/README.md) — Challenge directory structure.
