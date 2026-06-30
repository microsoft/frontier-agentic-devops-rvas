# Kaylee — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)

## Session Summary (2026-06-15)

**Delivered:** Complete site UI design system, component patterns, and bug fixes. Design: frontier gold compass brand with module-specific accent colors (sky-blue GHEC, red GHAS, violet GHAW, orange Agentic DevOps). Chakra Petch display + DM Sans body + JetBrains Mono code. Vendored marked.js (35KB) for Markdown rendering. Fixed 5 UI defects: icon paths, title font, track card anchors, featured card clickability, theme FOUC flash, global rebrand (product "Agentic DevOps" vs module "SRE Agent"), and setup challenge ordering. All 4 setup challenges render first per module via lexicographic sort. Challenge cards must be `<a>` elements (no plain divs).

**Detailed phase notes (12+ decisions, 2026-06-15):** Archived in git history for reference. Key archived learnings:
1. Design system palette, typography, component patterns (Phase 1)
2. Icon convention: `icon-<moduleId>.svg` in `MODULE_CONFIG` (Phase 2)
3. Track card anchor pattern with scroll-margin-top (Phase 4)
4. Featured card: all `.ch-card` must be `<a>` elements (Phase 5)
5. Brand collision rule: product "Agentic DevOps" ≠ module "SRE Agent" (Phase 5)
6. Anti-FOUC inline script in `<head>` using `fp-theme` storage key (Phase 6)
7. Challenge ordering: lexicographic slug sort, no JS secondary sort (Phase 7)

**Files owned:** `docs/*.html` (index, catalog, module, challenge), `docs/assets/css/styles.css`, `docs/assets/js/*.js` (core, home, catalog, module, challenge), `docs/assets/img/icon-*.svg`, mock data fixtures.

**Build & UI defects resolved:** D-002 (stale fallback counts → fixed), stale archive notes above refer to resolved Phase 2–7 defects.

## Learnings

### 2026-06-15 — Homepage setup-challenges section

**docs/index.html is hand-authored** — `docs/build.js` only writes `docs/assets/data/platform.json` and `docs/assets/data/dependency-graph.json`. Edit `docs/index.html` directly; no rebuild needed.

**Setup-challenge IDs (tier: setup in platform.json):**
- GHEC: `ghec-ch00` → `challenge.html?id=ghec-ch00` (module color `--c-ghec`)
- GHAS: `ghas-00` → `challenge.html?id=ghas-00` (module color `--c-ghas`)
- GHAW: `ghaw-00` → `challenge.html?id=ghaw-00` (module color `--c-ghaw`)
- SRE Agent: `sre-agent-00` → `challenge.html?id=sre-agent-00` (module color `--c-agentic` — the data module ID is `sre-agent` but the CSS color token is `--c-agentic`; no `.mod-sre-agent` class exists)

**Anchor convention:** All challenge links are real `<a>` elements with `href="challenge.html?id=..."`. Never use clickable divs.

**Badge class pattern:** Difficulty/tier badges use `.badge .badge-difficulty-{level}` (e.g. `badge badge-difficulty-beginner`), not `.diff-badge`.

### 2026-06-19 — Challenge sidebar success criteria Markdown

**Inline Markdown helper:** `FP.renderInlineMd(rawMd)` in `docs/assets/js/core.js` is the narrow helper for sidebar/list-item Markdown. It uses `marked.parseInline()` when available, sanitizes to a small inline tag allowlist (`a`, `strong`, `em`, `code`, `del`, `br`), validates link protocols, and falls back to `FP.esc()`.

**Scope decision:** Challenge success criteria render with inline Markdown via `challenge.js`; prerequisite capabilities intentionally remain plain escaped text to avoid broad sidebar behavior changes.

**ch-card pattern for static markup:** Use `<a class="ch-card" href="..." style="--mod-color:var(--c-{module})">` with `.ch-card-top`, `.ch-mod-dot`, `.ch-module-label`, `.ch-title`, `.ch-desc`, `.ch-footer` children to match the dynamic catalog cards.
