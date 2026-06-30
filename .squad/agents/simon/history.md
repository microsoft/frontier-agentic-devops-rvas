# Simon — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)

## Learnings

### 2026-06-19 — External URL audit hardening

`npm run audit:external` must treat raw URL extraction as untrusted input. Markdown examples can produce malformed raw candidates such as localhost URLs with trailing Markdown delimiters; the auditor should trim/exclude those delimiters and guard `new URL()`/HTTP request creation so bad candidates become warnings, not crashes.

### 2026-06-15 — Phase 3 QA (58 challenges, 4 modules)

**Build:** `node docs/build.js` exits 0, deterministic. Outputs: `platform.json` (4 modules, 58 challenges), `dependency-graph.json` (58 nodes, 33 edges), guide copies under `docs/assets/data/challenges/`.

**Critical defect found — D-001 (Wash must fix):**  
`parseMeta()` in `build.js` uses regex `^\s+-\s+` for block-list items, requiring at least one leading whitespace. GHAS `meta.yml` files use zero-indent list items (`- ghas-00`); GHAW/agentic-devops use 2-space-indented items. Result: **5 prerequisite edges silently dropped** from `platform.json` and `dependency-graph.json` for `ghas-01` through `ghas-05`. Fix: change `\s+` → `\s*` in the listItem regex.

**Content defects (Zoe must fix):**
- D-003: `ghas-00/README.md` references `../docs/prerequisites.html` (source-repo path, doesn't exist here).
- D-004: 7 broken links in `agentic-devops/resources/` pointing to original source repo layout (`../Student/...`, `../Coach/...`).
- D-005: `ghas-00` is `tier:core` not `tier:setup` — inconsistent with GHAW and agentic-devops module entry-point pattern.

**UI defect (Kaylee must fix):**
- D-002: `index.html` has 4 stale hardcoded counts: "57 challenges" (×2), "24 challenges" for GHAW, "2 tracks" for GHAS. Actual: 58, 25, 1 track.

**Checks that passed:** Schema (all 58 meta.yml valid), no duplicate IDs, no cross-module prereqs, no cycles, all guide files exist, all JS assets exist, JS field accesses match platform.json schema, ghec-ch14/ch19 emu_compatible:false, all ghas challenges app_dependency:juice-shop, ghas/setup.md documents Juice Shop setup.

**Lesson:** The minimal YAML parser in build.js is intentionally constrained but its list-item regex is too strict. Content teams authoring meta.yml must use 2-space indented list items. Or the parser should use `\s*` to be robust. Recommend fixing the parser (more robust) AND adding a CI schema-lint step that parses with a real YAML library to catch future mismatches.

### 2026-06-15 — Phase 4 QA (59 challenges, 4 modules, setup-challenge refresh)

**Build:** `node docs/build.js` exits 0. Output: `modules: 4, challenges: 59, nodes: 59, edges: 36`. ✅

**QA Checklist Used:**
1. Build exit code + output counts (modules:4, challenges:59)
2. platform.json per-module counts: ghec:21, ghas:7, ghaw:25, sre-agent:6
3. Setup challenge validation: tier:setup, prerequisites:[], first in module's first track (×4 IDs)
4. Exactly 4 `tier: setup` in meta.yml files (grep)
5. Dependency integrity: no dangling prerequisites (all 36 edges resolve)
6. GHAS renumber integrity: 00=setup, 01..06=core, no old ID references
7. Independence rule: ghec-ch01, ghas-01, sre-agent-01 must have prerequisites:[]
8. Stale data dirs: docs/assets/data/challenges/ dirs vs platform.json IDs
9. Guide files: README.md + COACH.md present for all 4 setup challenge dirs
10. Next-step links: setup README "Next Step" links point to real dirs

**Critical defect found — D-001 (Zoe must fix):**
`modules/sre-agent/challenges/01-github-sdlc/meta.yml` — `sre-agent-01` has `prerequisites: [sre-agent-00]`. Mal's independence rule requires the first real challenge of each module to have `prerequisites: []`. sre-agent-01 violates this. Fix: remove `- sre-agent-00` from prerequisites, leaving `prerequisites: []`.

**Cleanup applied (trivial artifact):** Removed stale dirs `docs/assets/data/challenges/ghaw-ch01/` and `docs/assets/data/challenges/ghaw-ch10/` — no matching IDs in platform.json.

**Checks that passed:** Build counts, per-module counts (all match spec), all 4 setup challenges correct (tier, prereqs, position, guides, next-step links), no dangling prerequisites, no stale agentic-devops refs, GHAS chain clean (00 setup + 01..06 core), ghec-ch01 and ghas-01 independence rule satisfied.

**Final counts:** 4 modules, 59 challenges (ghec:21, ghas:7, ghaw:25, sre-agent:6), 36 edges.


---

### 2026-06-15 — Environment Setup QA: Full verification of setup challenges across all 4 modules (Mal template + Zoe implementations + doc updates). Found 1 defect (sre-agent-01 independence rule), routed to Coordinator. Final verdict: ship-ready (59 challenges, 4 tier:setup, all first-real-challenges prereqs:[]).

### 2026-06-19 — External audit robustness improvements

Fixed scripts/audit-content.js to handle untrusted URL extraction gracefully. Malformed URL candidates from Markdown examples (e.g. localhost URLs with trailing delimiters) are now trimmed and excluded safely; invalid URL/request construction generates warnings instead of crashes. npm run audit:content and npm run audit:external both pass successfully with warnings only. This ensures audit determinism across all content including edge cases like code examples and inline references.

### 2026-06-19 — Deterministic content-audit guardrails

Added deterministic QA checks for folded YAML scalars, required meta fields, unresolved placeholders, README title consistency, guide assessment surfaces, and documented numbering gaps. Fixed the shared minimal YAML parser in `docs/build.js`, `scripts/audit-content.js`, and `scripts/verify-external-repos.js`; four setup descriptions now render as real text instead of literal `>`. Current audit and repo verification pass cleanly.

---

### 2026-06-23 — Submodule provisioning QA: git-submodule + symlink + lazy provision for OWASP Juice Shop

## Learnings

Reviewed Wash's submodule+symlink+lazy-provisioning implementation (juice-shop v20.0.0 / SHA f356a09207c7a9550eb6fc4c3945e081922cf998).

**Verified clean (no defects):**
- Drift check (`validateSubmodules` in verify-external-repos.js): gitlink SHA mismatch → `addError` → process exit 1. Hard fail on drift. ✓
- Not-yet-checked-out graceful: gitlink check runs from git index (independent of working tree); HEAD check only fires if working tree is populated. ✓
- Symlink is relative (`external/juice-shop`), not absolute — portable across Codespaces/Linux. ✓
- Manifest scope: ONLY juice-shop carries a `provisioning` block; seed/contoso-*/source_repo entries untouched. ✓
- GHAS 00 README flow: `npm run setup:juice-shop` appears before `cd app && npm install && npm start`. ✓
- Pin-update workflow: documented in EXTERNAL-REPOS.md (update manifest + bump gitlink + verify:repos). ✓
- Idempotency: provision-app.sh skips fetch if `.git` already present; skips symlink creation if already a symlink. ✓
- SHA mismatch exits non-zero: loud box + exit 1. ✓
- bash -n syntax check: passes. ✓
- postCreate.sh does NOT auto-provision (lazy design preserved): prints tip only. ✓
- gitlink SHA in index confirmed == f356a09... by `git ls-files --stage`. ✓
- `npm run verify:repos` passes: submoduleChecks: 1, 0 errors. ✓
- LOCAL runtime vs. org-alerts distinction: clearly documented in EXTERNAL-REPOS.md and devcontainer README. ✓

**Defects found (REJECTED):**

- D1 (P1): `package.json` — `"setup:app": "bash scripts/provision-app.sh"` always exits 1 (missing required `<app-key>` argument). Broken exposed npm script; should be removed or given an explicit key.
- D2 (P2): `scripts/provision-app.sh` lines ~125–127 — when a declared symlink path exists as a real directory (not a symlink), the script skips with a yellow warning but still exits 0 and prints "✓ juice-shop is ready." Misleading success when setup is actually incomplete.
- D3 (P3/theoretical): `scripts/provision-app.sh` node fallback (no jq) — `.join(' ')` space-joins multiple symlinks onto one string; the `while IFS= read -r` loop then treats the whole string as a single symlink target name. Broken for apps with >1 symlink in the node-fallback path. No immediate impact (jq installed by postCreate.sh; juice-shop has only one symlink).
- D4 (trivial): `scripts/provision-app.sh` line 68 — `ENTRY_SCRIPT` variable set but never referenced. Dead code.

**Verdict: REJECTED — D1 + D2 must be fixed before ship.**

---

### 2026-06-23 — Submodule provisioning QA RE-REVIEW (Mal's fixes for D1–D4)

Re-reviewed `scripts/provision-app.sh` and `package.json` after Mal applied fixes for all four defects.

**D1:** `setup:app` confirmed absent from `package.json`. Node assertion passes. ✓  
**D2:** `SYMLINK_BLOCKED=0` flag introduced before symlink loop; real-dir branch sets `SYMLINK_BLOCKED=1`; post-loop check exits 1 and prints error — no success banner emitted. Simulation confirmed exit code 1. ✓  
**D3:** Node fallback now uses `(p.symlinks||[]).join('\n')` (line 78) — one entry per line, matching jq's `.[]` path. ✓  
**D4:** `ENTRY_SCRIPT` variable fully removed. ✓  

**Regression checks:**
- `bash -n scripts/provision-app.sh` — syntax OK ✓
- `npm run setup:juice-shop` (idempotent) — exits 0, correct banner ✓
- `npm run verify:repos` — exits 0, no errors ✓

**Verdict: APPROVED — all four defects correctly fixed, no new defects introduced.**

**KEY DECISION:** This repo's origin = microsoft/frontier-agenticdevops-hackathon = the LIVE consolidated repo (KEPT). Only frontier-ghas/ghaw/ghec-hackathon + private Contoso sources deleted. The agenticdevops slug must never be presented as archived.
