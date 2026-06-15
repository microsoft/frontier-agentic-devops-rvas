# Squad Decisions

## Active Decisions

### frontier-ghplatform-hackathon: Unified Platform Architecture (2026-06-15)

**Status:** ✅ APPROVED by Marco (2026-06-15)

**Summary:** Four-module information architecture aggregating **58 challenges** (final count after GHAS scoped to security-only S00–S05) from four source hackathons (GHEC 20, GHAS 6, GHAW 25, Agentic DevOps 7). Single metadata contract (`meta.yml`) per challenge; extended GHEC build engine; no heavy assets; all content kept intact (no deduplication). Prerequisite edges: 38 (0 cross-module). Build deterministic; no cycles.

**Owner:** Mal (sign-off), Marco (approval)

**Key trade-offs:**
- Client-side Markdown rendering (40KB marked.js) vs. build-time HTML generation
- Exclude Juice Shop (61MB) by reference; students pull from source repo
- Keep overlapping content across modules (feature, not bug — different audiences, different depth)
- No Jekyll — full control, zero runtime dependencies, deterministic sub-second builds

**GHAS scope decision (Marco, 2026-06-15):** Only Security track (S00–S05, 6 challenges). Excludes Copilot frontend (F00–F03), backend (B00–B03), and setup (C00) tracks — module is GitHub Advanced Security, not Copilot app-feature work.

**Defects (all resolved):** D-001 (parser regex, fixed by Wash), D-002 (stale counts, fixed by Kaylee), D-003–D-005 (content links/tier, fixed by Zoe).

**Final state:** Build clean. 4 modules, 58 challenges, 38 prerequisite edges, 0 cross-module dependencies, 0 cycles. Ship-ready per Mal.

---

### frontier-ghplatform-hackathon: Design System (2026-06-15)

**Status:** Implemented (Phase 1)

**Summary:** Frontier site uses distinct visual identity (not copying GHEC design). Palette: dark `#03050d`/light `#f2f5fd` canvas; frontier gold `#e8c84a` (compass/navigation); module colors per track (GHEC sky-blue, GHAS security-red, GHAW neural-violet, Agentic operational-orange). Typography: Syne 700–800 display (spaced, technical), DM Sans body (humanist), JetBrains Mono code. Challenge cards: 3px left border in module color via `::before`, hover `translateX(3px)`. Compass rose SVG hero (4 arcs, gold star, 120s slow rotation). Module color applied via `--mod-color` CSS custom property from `.mod-<moduleId>` class.

**Owner:** Kaylee

**Key details:**
- Marked.js vendored at 35KB, loaded only on challenge.html
- Icons expected at `assets/img/icon-<moduleId>.svg` (filename in `platform.json`, not path)
- Challenge paths relative to `docs/` root (e.g., `assets/data/challenges/ghec-ch01/README.md`)
- All module color rules minimal (one card ruleset, four variants via inheritance)

---

### frontier-ghplatform-hackathon: Phase 2 Content Port (2026-06-15)

**Status:** Complete

**Summary:** GHAW (25 challenges, 4 tracks: hello-agent 5, repo-concierge 6, continuous-intelligence 6, production-patterns 8) and Agentic DevOps (7 challenges, linear arc 00→01,02→03→04,05→06) ported to modules. Prerequisites: GHAW all non-setup challenges require ghaw-0-00; ghaw-4-06 additionally requires ghaw-4-05 (causal consumer). Agentic-DevOps prerequisites justified by content: both SDLC and Copilot experience feed into challenge 03 (coordinate workflows), deployed infra from 04 required for 06 (SRE agent). Resources vendored (212KB). Coach guides derived from source challenge solutions. Tier mapping: source core→core, bonus/extension→stretch.

**Owner:** Zoe

**Flags:**
- GHAW 3-05 (Ship It) is capstone-style but marked `tier: stretch` (architecture supports future `capstone` tier)
- Agentic-DevOps 04 (Azure deploy) requires active Azure subscription — accessibility concern for some hackathon environments; fallback evidence packet provided in README
- GHAW 3-03 (engine swap) may need content refresh as AI engine availability changes (defer to Zoe in 6+ months)

---

### frontier-ghplatform-hackathon: Phase 3 QA & Defect Resolution (2026-06-15)

**Status:** ✅ All defects resolved

**Summary:** QA by Simon identified 5 defects (D-001 P0, D-002–D-005 P1–P2). D-001 (ship blocker): `parseMeta()` regex required leading whitespace (`\s+`), silently dropping zero-indent YAML block sequences (GHAS meta.yml), causing 5 missing prerequisite edges. Fixed by Wash (regex `\s*`) and Zoe (re-indented GHAS items to 2-space). D-002: hardcoded challenge counts in index.html stale (57→58, GHAS tracks 2→1, GHAW 24→25) — fixed by Kaylee. D-003: broken docs links in ghas-s00 (source repo paths) — fixed by Zoe. D-004: broken resource links in agentic-devops (source layout paths) — fixed by Zoe. D-005: ghas-s00 tier `core` not `setup` — fixed by Zoe. Build verified clean: 58 challenges, 38 edges, 0 cross-module, 0 cycles.

**Owner:** Simon (QA), team (fixes)

**Final independence audit:** GHEC (20 independent), GHAS (6, all require s00 on disk after fix), GHAW (24 require setup + 1 causal pair), Agentic-DevOps (7-challenge linear arc). ✅

---

### frontier-ghplatform-hackathon: Design System Implementation Reference

This standalone decision (in `.squad/decisions/wash-build-contract.md`) documents the build engine data contract and module ID scheme. Retained for technical reference; no action required.

---

### frontier-ghplatform-hackathon: Icon Convention + Title Font (2026-06-15)

**Status:** ✅ Implemented

**Summary:** Two visual refinements to fix bugs and improve readability.

**Icon Convention:** Module icon filenames in `MODULE_CONFIG` (docs/build.js) must be the full filename `icon-<moduleId>.svg`, not bare semantic names. Bare names (`cloud`, `shield`, `hubot`, `gear`) caused 404s in home.js and module.js because the JS renders `assets/img/${m.icon}` directly. The deterministic mapping `icon-${id}.svg` is the single source of truth.

- `MODULE_CONFIG.icon` values in docs/build.js = `icon-<moduleId>.svg`
- home.js renders `<img src="assets/img/${m.icon}">` ✓
- module.js fallback: `'assets/img/' + (mod.icon || 'icon-' + mod.id + '.svg')` ✓
- docs/index.html static fallback = `assets/img/icon-<moduleId>.svg` ✓
- All new modules: add icon SVG as `docs/assets/img/icon-<newModuleId>.svg`

**Title Font: Chakra Petch replaces Syne** (docs/assets/css/styles.css, all 4 HTML pages).

Rationale: Syne too futuristic and hard to read. Chakra Petch is geometric, technical, legible — matches reference site and "frontier platform" brand.

Typography adjustments:
- Heading `font-weight`: 800 → 700 (Chakra Petch 700 already strong)
- Heading `letter-spacing`: -0.025em → -0.01em (geometric forms need less aggressive tracking)
- Google Fonts: `Chakra+Petch:wght@500;600;700` (replaces `Syne:wght@700;800`)
- Body (DM Sans) and mono (JetBrains Mono) unchanged

**Owner:** Kaylee

**Verification:** platform.json has resolvable icons. No Syne references remain. Chakra Petch loaded on all 4 pages.

---

### frontier-ghplatform-hackathon: Track Cards as In-Page Navigation Anchors (2026-06-15)

**Status:** ✅ Implemented

**Summary:** Module pages "Learning paths" track cards were non-interactive `<div>` elements. Converted to anchor links (`<a href="#track-${id}">`) with smooth in-page navigation to challenge-group sections.

**Implementation:**

- **`docs/assets/js/module.js` — `renderTracks()`:** Tag choice — `<a>` when track has challenges (count > 0), `<div>` when empty (count === 0) to avoid dead anchors. No CSS changes; `.track-item` styling already supports both.
- **`docs/assets/js/module.js` — `renderChallenges()`:** Added `id="track-${trackId}"` to each `.group-head` div.
- **`docs/assets/css/styles.css` — `.group-head`:** Added `scroll-margin-top: 72px` (58px navbar + 14px breathing room) to prevent sticky nav overlap. Native `scroll-behavior: smooth` on `html` handles scroll animation.

**Edge cases:** Zero-challenge tracks render as `<div>` (no dangling anchors). Challenge card links (`renderChallenges()`) unaffected. Keyboard accessibility: `<a>` elements natively focusable; `:focus-visible` styling already present.

**Verification:** `node docs/build.js` clean (58 challenges, 4 modules); track navigation tested (GHEC: developer-flow, admin-governance, security, automation-ai all link correctly).

**Owner:** Kaylee

**Files:** `docs/assets/js/module.js`, `docs/assets/css/styles.css`

### frontier-ghplatform-hackathon: Rename Track agentic-arc → agentic-lifecycle (2026-06-15)

**Status:** ✅ Implemented

**Summary:** The `agentic-devops` module's single track was renamed from id `agentic-arc` / display "Agentic Arc" to id `agentic-lifecycle` / display "Agentic Lifecycle".

**Rationale:** "Agentic Arc" collides with **Azure Arc** (a Microsoft product family). The agentic-devops module is Azure-heavy (challenge 04 deploys to Azure, challenge 06 is the Azure SRE agent). Using "Arc" in a track name inside an Azure-focused module misleads participants into thinking of the Azure Arc product. "Agentic Lifecycle" conveys the same meaning (a lifecycle of agent-driven DevOps: plan → build → deploy → monitor → recover) without the Azure Arc ambiguity.

**Owner:** Zoe (content/curriculum)

**Requested by:** Marco (@olivomarco)

**Files Changed:**
- `docs/build.js` — Track key `agentic-arc` → `agentic-lifecycle`; `name:` field updated
- 7× `modules/agentic-devops/challenges/*/meta.yml` — `track: agentic-arc` → `track: agentic-lifecycle`
- `README.md` — Track display name updated in module table
- `CONTRIBUTING.md` — Track id and display name updated in track reference table
- `docs/assets/data/platform.json` — regenerated by `node docs/build.js`
- `docs/assets/data/dependency-graph.json` — regenerated by `node docs/build.js`

**Verification:** Build clean (4 modules, 58 challenges, 38 edges). Zero `agentic-arc` id hits. All 7 challenge meta.yml files contain `track: agentic-lifecycle`. `platform.json` carries new id+name. One grep hit "agentic arc" is false positive (substring of "agentic architecture" in research-links, not the track).

---

### frontier-ghplatform-hackathon: Remove agentic-devops-02 ("Build with GitHub Copilot") (2026-06-15)

**Status:** ✅ Implemented

**Requested by:** Marco (@olivomarco)

**Owner:** Zoe (content/curriculum)

**Summary:** Removed challenge `agentic-devops-02` ("Build with GitHub Copilot") from the `agentic-devops` module entirely. The challenge was the second in the original linear arc (00 → 01, 02 → 03 → 04, 05 → 06).

**Rationale:** Marco requested removal. The challenge is out of scope for this curriculum pass.

**Blast Radius:** Contained. Only one challenge listed `agentic-devops-02` as a prerequisite: `modules/agentic-devops/challenges/03-agent-workflows/meta.yml` — had `prerequisites: [agentic-devops-01, agentic-devops-02]`. Updated to `prerequisites: [agentic-devops-01]`. Linear chain preserved. No other challenge, README, CONTRIBUTING, or module doc referenced the removed id or folder.

**Files Changed:**
- **Deleted:** `modules/agentic-devops/challenges/02-copilot-engineering/` (README.md, meta.yml, COACH.md)
- **Deleted:** `docs/assets/data/challenges/agentic-devops-02/` (stale build copy: README.md, COACH.md)
- **Edited:** `modules/agentic-devops/challenges/03-agent-workflows/meta.yml` — removed `- agentic-devops-02` from prerequisites
- **Regenerated:** `docs/assets/data/platform.json` and `docs/assets/data/dependency-graph.json` via `node docs/build.js`

**New Chain:** `00 → 01 → 03 → 04, 05 → 06` (gap at 02 is intentional; ids are stable, not positional)

**Verification:** Build clean: 57 challenges (was 58), 36 edges (was 38). Zero `agentic-devops-02` grep hits (excluding binary `.git/index`). Zero `02-copilot-engineering` grep hits. Zero `Build with GitHub Copilot` grep hits. `agentic-devops-03` prerequisites = `[agentic-devops-01]` in platform.json ✓. No dangling prerequisites across all 57 challenges ✓. No orphan `docs/assets/data/challenges/agentic-devops-02/` directory ✓

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
