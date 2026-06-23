---
name: "submodule-lazy-provisioning"
description: "Manifest-driven git submodule pattern for large, optional locally-run apps: register the gitlink at a pinned SHA, defer the actual clone to a lazy helper script, expose via npm script, and drift-check on every CI run."
domain: "devops, build, scaffolding"
confidence: "high"
source: "earned — implemented for OWASP Juice Shop (GHAS local runtime), 2026-06-23"
---

## Context

Use when a curriculum or tooling repo needs to pin a large external app at a specific commit
for local participant use, but:
- The app is too large to vendor in-tree
- Most users don't need it (lazy fetch is preferred)
- The exact commit must be guaranteed (drift check required)
- Participants need a stable path regardless of internal submodule layout

## Patterns

### 1. Register submodule without cloning

```bash
# Create empty working-tree placeholder
mkdir -p external/<name>

# Write gitlink directly into git index at the pinned SHA (no network)
git update-index --add --cacheinfo 160000,<sha>,external/<name>

# Register URL + shallow=true in .gitmodules
cat >> .gitmodules << EOF
[submodule "external/<name>"]
    path = external/<name>
    url = <url>
    shallow = true
EOF

git add .gitmodules
```

This produces a valid submodule registration (gitlink + URL) without any network access.
The gitlink object in the parent repo's tree stores the exact SHA.

### 2. Committed symlink for stable paths

```bash
ln -s external/<name> app   # or whatever stable path challenges expect
git add app                  # git tracks as mode 120000
```

Challenge instructions reference `app/` — the submodule's internal path is hidden.

### 3. Manifest provisioning block (external-repos.json)

```json
{
  "key": "<name>",
  "provisioning": {
    "method": "submodule",
    "submodule_path": "external/<name>",
    "symlinks": ["app"],
    "npm_script": "setup:<name>"
  }
}
```

The `method` field is the hook for both the drift check and the provision script.

### 4. Generic provision script (scripts/provision-app.sh)

Takes app key as argument. Pattern:
1. Read manifest entry via `jq` (fall back to `node -e`)
2. `git submodule update --init --depth 1 -- <submodule_path>`
3. Verify `git rev-parse HEAD` == `source.sha` — loud error on mismatch
4. Ensure symlinks exist
5. Print next steps

Key idiom — idempotency check:
```bash
if [[ -f "${ABS_SUB}/.git" || -d "${ABS_SUB}/.git" ]]; then
  echo "already initialised — skipping fetch"
else
  git submodule update --init --depth 1 -- "${SUBMODULE_PATH}"
fi
```

### 5. Drift check in verify script (Node, no deps)

```js
function parseGitmodules() { /* pure string parse of .gitmodules */ }

function readGitlink(submodulePath) {
  // git ls-files --stage <path> → parse 160000 <sha> line
}

function validateSubmodules(entries) {
  for (const entry of entries.filter(e => e.provisioning?.method === 'submodule')) {
    // 1. .gitmodules has URL for submodule_path
    // 2. gitlink SHA in index == source.sha (hard error on drift)
    // 3. if checked out: HEAD SHA == source.sha (hard error)
    // 4. declared symlinks exist (warning if missing)
  }
}
```

Add to `state.counts.submoduleChecks` for reporting.

### 6. npm scripts (package.json)

```json
"setup:<name>": "bash scripts/provision-app.sh <key>",
"setup:app":    "bash scripts/provision-app.sh"
```

### 7. Pin-update workflow

When bumping to a new version:
1. `cd external/<name> && git fetch --depth 1 origin <new-sha> && git checkout <new-sha>`
2. `cd ../.. && git add external/<name>` (updates gitlink)
3. Update `source.sha` (and `source.tag`) in `external-repos.json`
4. `npm run verify:repos` — confirms gitlink == manifest SHA
5. Commit both together in one atomic commit

## Examples

- `external/juice-shop` — OWASP Juice Shop at `v20.0.0` / `f356a09...`
- `app → external/juice-shop` — stable symlink for `cd app && npm start`
- `scripts/provision-app.sh juice-shop` — invoked by `npm run setup:juice-shop`

## Anti-Patterns

- **Never auto-pull in postCreate:** defeats the lazy design; forces all participants to download large apps they may not need.
- **Never fake a gitlink SHA:** `git update-index --cacheinfo` writes the real SHA; don't invent one. If you don't know the SHA, look it up first.
- **Never update `source.sha` without updating the gitlink (or vice versa):** they must match — the drift check will catch it, but best to keep them in sync atomically.
- **Don't use absolute symlinks:** `ln -s external/<name> app` (relative) works inside the container; absolute paths break across environments.
- **Symlinks are not for Windows native checkouts:** document that participants must use the devcontainer/Codespace (Linux). Symlinks work fine there.
