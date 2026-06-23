# Decision: Submodule + Symlink Pattern for Local App Provisioning

**Date:** 2026-06-23
**Author:** Wash (DevOps / Build)
**Status:** Proposed — pending team ratification

---

## Context

GHAS participants need OWASP Juice Shop running locally (port 3000) for manual exploit testing. Previously the instructions said `cd app && npm start` without a pinned, reproducible way to get `app/` — participants copy-pasted SHA references from challenge READMEs, which was error-prone.

## Decision

The **standard pattern for locally-run apps** in this curriculum is:

1. **Git submodule** registered at `external/<name>`, pinned to a specific commit SHA in the gitlink. `.gitmodules` carries the URL and `shallow = true`.
2. **Committed symlink** from a stable challenge-expected path (e.g., `app/`) to `external/<name>`, so instructions never need to reference the submodule's internal location.
3. **Lazy provisioning** — the submodule working tree is NOT fetched at container create time. Participants run `npm run setup:<name>` when they need it.
4. **`scripts/provision-app.sh`** — a single generic script driven by the app key. It reads `external-repos.json`, inits the submodule, verifies the SHA, ensures symlinks, and prints next steps.
5. **`external-repos.json` as source of truth** — each submodule-backed app carries a `provisioning` block: `{ "method": "submodule", "submodule_path": "...", "symlinks": [...], "npm_script": "..." }`.
6. **Drift check in `npm run verify:repos`** — `validateSubmodules()` asserts `.gitmodules` URL presence, gitlink SHA == `source.sha`, and (if checked out) HEAD SHA == `source.sha`.

## Applied to Juice Shop

- Submodule: `external/juice-shop` pinned at `f356a09207c7a9550eb6fc4c3945e081922cf998` (tag `v20.0.0`)
- Symlink: `app → external/juice-shop`
- NPM script: `npm run setup:juice-shop`
- The submodule is the LOCAL RUNTIME only. The org-imported repo that carries GHAS alerts is completely separate and unaffected.

## Adding a new local app

1. Register submodule: `git submodule add --depth 1 <url> external/<name>` + checkout pinned SHA.
2. Set `shallow = true` in `.gitmodules`.
3. Create committed symlink(s) if needed.
4. Add `provisioning` block to `external-repos.json`.
5. Add `setup:<name>` npm script in `package.json`.
6. Run `npm run verify:repos` to confirm drift check passes.

## Rationale

- **Pinned in-tree:** gitlink stores the exact SHA in the parent repo's tree — drift is impossible once committed.
- **Lazy = fast containers:** participants who skip GHAS don't pay the ~61 MB Juice Shop download at container create time.
- **Generic:** the provision script and drift check are key-driven; adding future apps requires only a manifest entry + npm script.
- **Symlinks work in Codespaces/Linux devcontainers:** the expected deployment environment. Windows native checkout is out of scope (documented limitation).
