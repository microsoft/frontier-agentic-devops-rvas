# External Repositories & Pinned References

This guide explains how this hackathon curriculum manages external dependencies, source apps, and third-party tools without vendoring them into the main repository.

## Philosophy

- **No vendoring of third-party apps** — we pull external projects at pinned references when needed.
- **Explicit pinning** — all refs (commit SHAs, tags) are documented and validated.
- **Three import modes** — clone (shared org branches), fork (student copies), and import (one-time setup).
- **Maintainability** — pinned refs stay stable; updates are deliberate and tracked.

## External Dependencies

### OWASP Juice Shop

- **Source:** https://github.com/juice-shop/juice-shop
- **Pinned ref:** `v20.0.0` (tag) = commit `f356a09207c7a9550eb6fc4c3945e081922cf998`
- **Used by:** GHEC challenges (ch11–ch15), GHAS setup
- **Import mode:** Challenge setup scripts (`wth setup`) import the repo into org-owned GitHub repositories
- **Why:** Juice Shop is a large, intentionally vulnerable app; we don't embed it. Each challenge provisions its own imported instance (e.g., `wth-ch11-juice-shop`), so students work against isolated, disposable copies.
- **Local runtime:** GHAS module runs Juice Shop locally (Docker or devcontainer) for manual exploit testing; the shared org repo (governed by GHAS alerts) is separate.

### GitHub Advanced Security Source Hackathon

- **Source:** https://github.com/microsoft/frontier-ghas-hackathon
- **Pinned ref:** HEAD commit `4abc7439f0cab329b659263845e20139fbbe5359` (as of curriculum freeze)
- **Used by:** GHAS challenges reference setup guide, alert corpus
- **Import mode:** Read-only reference at the pinned commit

### GitHub Agentic Workflows Source Hackathon

- **Source:** https://github.com/microsoft/frontier-ghaw-hackathon
- **Pinned ref:** HEAD commit `9f0957ed3be978b2143c7048f5396183ad189d6e` (as of curriculum freeze)
- **Used by:** GHAW challenges reference source material
- **Import mode:** Fork/clone by students (they work from their own copy); maintainers use the pinned commit for reproducibility checks

### SRE Agent Sample App

- **Source:** Vendored locally at `modules/sre-agent/resources/sample-app/`
- **Origin:** Contoso Claims demo application (first-party curriculum resource, included in-tree)
- **Used by:** SRE Agent challenges
- **Import mode:** Local; no external clone needed
- **Why:** Small enough to vendor; students run it locally as the target for agent automation

### Frontier Agentic DevOps Hackathon (This Repository)

- **URL:** https://github.com/microsoft/frontier-agenticdevops-hackathon
- **Pinned ref:** commit `08edbed4eee3ab185ebd5772bd1b48783ba83882`

## Import Modes

### Clone (Shared Org Branch)

**When:** A challenge uses a shared org repository that all students contribute to.

- **Example:** GHAS module — students clone the shared org repo and work on personal branches (`participant/{handle}` or `team-{team-name}/challenge-work`).
- **Flow:**
  ```bash
  git clone https://github.com/<org>/<repo>.git
  cd <repo>
  git checkout -b participant/{your-handle}
  ```
- **Outcome:** Each student has an isolated branch; the app/environment is shared.

### Fork (Student Copies)

**When:** A challenge needs each student to own a copy (for PRs, Actions workflows, or org settings).

- **Example:** GHAW module — students fork the `frontier-ghaw-hackathon` repo so they have an org context.
- **Flow:**
  ```bash
  gh repo fork microsoft/frontier-ghaw-hackathon --clone
  cd frontier-ghaw-hackathon
  ```
- **Outcome:** Student owns their fork; workflows run in their org context.

### Import (One-Time Setup)

**When:** A challenge setup script creates a GitHub repository with external content imported.

- **Example:** GHEC/GHAS challenges — setup scripts import Juice Shop at `v20.0.0` into a new org repo (e.g., `wth-ch11-juice-shop`).
- **Flow:**
  ```bash
  wth setup ch11 --org <org>
  # Creates <org>/wth-ch11-juice-shop with Juice Shop imported
  ```
- **Outcome:** New repo exists in the student's org; challenges work against it.

## Pinned References & Validation

### How to Check a Pinned Reference

Each challenge documents the dependency family in its `meta.yml`; exact refs live in `external-repos.json`:

```yaml
app_dependency: juice-shop
```

### How to Validate Refs

When a new curriculum version is needed, Wash (the tooling engineer) runs:

```bash
npm run verify:repos           # Validates challenge metadata against external-repos.json
npm run verify:repos:external  # Confirms pinned repo refs are reachable through git
npm run audit:external         # Optional content URL audit
```

This confirms all URLs and refs exist and are accessible.

### Updating a Pinned Reference

If a new version of Juice Shop or another dependency is needed:

1. **Coordinate with curriculum**: Update `external-repos.json` with the new ref (tag and/or full SHA).
2. **Test**: Run `npm run verify:repos` and `npm run verify:repos:external` to confirm the manifest and refs are valid.
3. **Document**: Add a note to the challenge's `COACH.md` if the new ref introduces breaking changes.
4. **Rebuild**: Run `npm run build` to regenerate catalogs with the new refs.

## Dependency Families

### GHAS Dependency Family

- **Juice Shop** (OWASP app) — pinned at `v20.0.0`
- **GHAS source hackathon** (reference material) — pinned at commit `4abc7439f0cab329b659263845e20139fbbe5359`
- **Local Docker image** — `bkimminich/juice-shop` (used as fallback for quick local runs)

### GHAW Dependency Family

- **GHAW source hackathon** (primary source) — pinned at commit `9f0957ed3be978b2143c7048f5396183ad189d6e`; students fork it
- **No app** — challenges focus on workflow authoring, not a deployed service

### SRE Agent Dependency Family

- **Sample app** (Contoso Claims) — vendored locally, no external dependency
- **Azure** (runtime target) — students provision their own (not pinned, varies by subscription)

### GHEC Dependency Family

- **Juice Shop** (for ch11–ch15) — pinned at `v20.0.0`
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
- When external projects release major versions, evaluate and document breaking changes before updating the pin.
- Test setup scripts (`wth setup`) against the pinned refs in a CI/CD gate or manual verification step.

### For Students

- Follow setup instructions in each challenge's `README.md` or `COACH.md`.
- If setup fails to pull an external repo, check your GitHub token scopes and network access.
- Report setup failures via your hackathon organizer so coaches can investigate.

### For Coaches

- Validate that pinned refs are reachable before running a cohort (run `npm run verify:repos:external`).
- If a ref becomes unreachable, update it in coordination with the curriculum team.
- Keep students informed if external services (GitHub, Docker Hub) have outages.

## See Also

- [README.md](../README.md) — Build, validate, and deploy the curriculum.
- [CONTRIBUTING.md](../CONTRIBUTING.md) — Authoring challenges and meta.yml field reference.
- [modules/README.md](../modules/README.md) — Challenge directory structure.
