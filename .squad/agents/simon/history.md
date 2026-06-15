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

### 2026-06-15 — Phase 3 QA (58 challenges, 4 modules)

**Build:** `node docs/build.js` exits 0, deterministic. Outputs: `platform.json` (4 modules, 58 challenges), `dependency-graph.json` (58 nodes, 33 edges), guide copies under `docs/assets/data/challenges/`.

**Critical defect found — D-001 (Wash must fix):**  
`parseMeta()` in `build.js` uses regex `^\s+-\s+` for block-list items, requiring at least one leading whitespace. GHAS `meta.yml` files use zero-indent list items (`- ghas-s00`); GHAW/agentic-devops use 2-space-indented items. Result: **5 prerequisite edges silently dropped** from `platform.json` and `dependency-graph.json` for `ghas-s01` through `ghas-s05`. Fix: change `\s+` → `\s*` in the listItem regex.

**Content defects (Zoe must fix):**
- D-003: `ghas-s00/README.md` references `../docs/prerequisites.html` (source-repo path, doesn't exist here).
- D-004: 7 broken links in `agentic-devops/resources/` pointing to original source repo layout (`../Student/...`, `../Coach/...`).
- D-005: `ghas-s00` is `tier:core` not `tier:setup` — inconsistent with GHAW and agentic-devops module entry-point pattern.

**UI defect (Kaylee must fix):**
- D-002: `index.html` has 4 stale hardcoded counts: "57 challenges" (×2), "24 challenges" for GHAW, "2 tracks" for GHAS. Actual: 58, 25, 1 track.

**Checks that passed:** Schema (all 58 meta.yml valid), no duplicate IDs, no cross-module prereqs, no cycles, all guide files exist, all JS assets exist, JS field accesses match platform.json schema, ghec-ch14/ch19 emu_compatible:false, all ghas challenges app_dependency:juice-shop, ghas/setup.md documents Juice Shop setup.

**Lesson:** The minimal YAML parser in build.js is intentionally constrained but its list-item regex is too strict. Content teams authoring meta.yml must use 2-space indented list items. Or the parser should use `\s*` to be robust. Recommend fixing the parser (more robust) AND adding a CI schema-lint step that parses with a real YAML library to catch future mismatches.

