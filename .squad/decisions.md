# Squad Decisions

## Active Decisions

### Agentic DevOps: Challenge QA rubric and missing-candidate policy (2026-06-19)

**Status:** ✅ Implemented as repo contribution contract

**Owner:** Mal (Lead / Architect)

**Summary:** Per-challenge QA now uses a 100-point rubric covering metadata/provenance (15), independence/setup (20), student guide quality (20), coach guide quality (15), validation evidence (15), accessibility/operational safety (10), and catalog fit/coverage (5). Severity gates are P0/P1 blocking, P2 follow-up-eligible, and P3 non-blocking. The inventory format is JSON Lines compatible for PR comments, issue bodies, or generated local reports; no repo planning markdown is required.

**Catalog coverage decision:** Current catalog coverage is 59 challenges: GHEC 21, GHAS 7, GHAW 25, SRE Agent 6. GHEC and GHAW are complete for current scope. GHAS remains security-focused; excluded Copilot app/frontend/backend material is declined for this module and should become a separate module only if Marco reopens that scope. The SRE Agent id gap at `sre-agent-02` is intentional after the removed Copilot-engineering challenge; do not restore it unless the prior removal decision is reversed. A future SRE-specific bridge challenge may be proposed only if it teaches a distinct lifecycle capability between SDLC setup and agent workflow coordination.

**Repo change:** `CONTRIBUTING.md` now contains the authoritative `meta.yml` contract, QA rubric, severity policy, QA inventory object shape, and backlog-decision rules.

---

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

**Summary:** GHAW (25 challenges, 4 tracks: hello-agent 5, repo-concierge 6, continuous-intelligence 6, production-patterns 8) and Agentic DevOps (7 challenges, linear arc 00→01,02→03→04,05→06) ported to modules. Prerequisites: GHAW all non-setup challenges require ghaw-00; ghaw-22 additionally requires ghaw-21 (causal consumer). Agentic-DevOps prerequisites justified by content: both SDLC and Copilot experience feed into challenge 03 (coordinate workflows), deployed infra from 04 required for 06 (SRE agent). Resources vendored (212KB). Coach guides derived from source challenge solutions. Tier mapping: source core→core, bonus/extension→stretch.

**Owner:** Zoe

---

### frontier-ghplatform-hackathon: Featured Home Card Made Clickable (2026-06-15)

**Status:** ✅ Accepted

**Date:** 2026-06-15  
**Author:** Kaylee (Frontend / Site Engineer)

**Context:** The "A good place to start" featured challenge card on `docs/index.html` was rendered as a plain `<div class="ch-card ...">` — visually indistinguishable from other challenge cards, but clicking the card body did nothing. Only the separate "Open challenge →" button worked. This was inconsistent with every other `.ch-card` instance in the codebase (catalog and module pages both use `<a>` elements).

**Decision:** Change the featured card's outer element from `<div>` to `<a href="${FP.challengeUrl(pick.id)}">` in `docs/assets/js/home.js::renderFeaturedChallenge()`. Keep the "Open challenge →" button as a **sibling** `<a>` for explicit affordance / accessibility — not nested inside (valid HTML, no `<a>` inside `<a>`).

**Rationale:**
- **Consistency:** Every `.ch-card` in catalog.js and module.js is already an `<a>`. Featured card was the only exception.
- **UX:** Users expect the full card to be clickable (standard card-link pattern).
- **Accessibility:** Native `<a>` is keyboard-focusable. `.ch-card:focus-visible` in styles.css provides visible focus ring.
- **HTML validity:** Sibling anchors are valid; nested anchors are not.
- **No CSS changes:** `.ch-card` already designed for use as `<a>` (text-decoration:none, color:inherit, display:flex).

**Convention Established:** ALL `.ch-card` instances across the site must be `<a>` elements. A `<div class="ch-card">` is always wrong and should be treated as a bug on sight.

**Files Changed:** `docs/assets/js/home.js` — `renderFeaturedChallenge()`: `<div class="ch-card ...">` → `<a class="ch-card ..." href="...>`

**Flags:**
- GHAW 3-05 (Ship It) is capstone-style but marked `tier: stretch` (architecture supports future `capstone` tier)
- Agentic-DevOps 04 (Azure deploy) requires active Azure subscription — accessibility concern for some hackathon environments; fallback evidence packet provided in README
- GHAW 3-03 (engine swap) may need content refresh as AI engine availability changes (defer to Zoe in 6+ months)

---

### frontier-ghplatform-hackathon: Phase 3 QA & Defect Resolution (2026-06-15)

**Status:** ✅ All defects resolved

**Summary:** QA by Simon identified 5 defects (D-001 P0, D-002–D-005 P1–P2). D-001 (ship blocker): `parseMeta()` regex required leading whitespace (`\s+`), silently dropping zero-indent YAML block sequences (GHAS meta.yml), causing 5 missing prerequisite edges. Fixed by Wash (regex `\s*`) and Zoe (re-indented GHAS items to 2-space). D-002: hardcoded challenge counts in index.html stale (57→58, GHAS tracks 2→1, GHAW 24→25) — fixed by Kaylee. D-003: broken docs links in ghas-00 (source repo paths) — fixed by Zoe. D-004: broken resource links in agentic-devops (source layout paths) — fixed by Zoe. D-005: ghas-00 tier `core` not `setup` — fixed by Zoe. Build verified clean: 58 challenges, 38 edges, 0 cross-module, 0 cycles.

**Owner:** Simon (QA), team (fixes)

**Final independence audit:** GHEC (20 independent), GHAS (6, all require 00 on disk after fix), GHAW (24 require setup + 1 causal pair), Agentic-DevOps (7-challenge linear arc). ✅

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

### frontier-ghplatform-hackathon: Module Rename agentic-devops → sre-agent + Repo Rebrand (2026-06-15)

**Status:** ✅ Implemented

**Requested by:** Marco (@olivomarco)

**Owner:** Zoe (Content), Kaylee (Frontend)

**Summary:** Two coordinated changes implemented:

**A) Module id rename:** `agentic-devops` → `sre-agent`, display name "Agentic DevOps & Azure SRE" → "SRE Agent".

**B) Repo/product rebrand:** "The Frontier GitHub Platform Hackathon" → **"Agentic DevOps"** (non-HTML/JS by Zoe, HTML/JS brand by Kaylee).

**Motivation:** The module name was confusing with the product brand. Marco decided to give the module a tighter name ("SRE Agent") and reserve "Agentic DevOps" for the product.

**Naming After Change:**
- Module id: `agentic-devops` → `sre-agent`
- Module display name: "Agentic DevOps & Azure SRE" → "SRE Agent"
- Challenge ids: `agentic-devops-NN` → `sre-agent-NN`
- Product/repo brand: "The Frontier GitHub Platform Hackathon" → **"Agentic DevOps"**

**Collision rule:** "Agentic DevOps" = product brand. "SRE Agent" (id: `sre-agent`) = module. Do not call the module "Agentic DevOps".

**Files Changed (Zoe):**
- `modules/agentic-devops/` → `modules/sre-agent/`
- `docs/build.js` — `MODULE_CONFIG` key `'agentic-devops'` → `'sre-agent'`; `name:` → `'SRE Agent'`; top comment rebranded
- 6× `modules/sre-agent/challenges/*/meta.yml` — id/module/prerequisites updated
- `README.md` — H1 rebranded; module table updated
- `CONTRIBUTING.md`, `modules/_TEMPLATE/challenge/meta.yml`, `modules/README.md` — references updated
- `package.json` — `description` rebranded
- `docs/assets/data/challenges/agentic-devops-*/` — pruned (6 orphan dirs removed)
- `docs/assets/data/platform.json`, `dependency-graph.json` — regenerated

**Intentionally Unchanged:**
- `docs/assets/img/icon-agentic-devops.svg` — asset filename kept (Kaylee coordination deferred)
- `icon: 'icon-agentic-devops.svg'` in `docs/build.js` — references the asset
- `source_repo` attribution URLs — pointing to upstream Microsoft repos
- `.squad/` historical logs

**Files Changed (Kaylee):**
- All four pages (`index.html`, `catalog.html`, `challenge.html`, `module.html`)
  - `<title>` elements: "… — Frontier …" → "… — Agentic DevOps"
  - `<meta name="description">` reworded
  - Header wordmark: "Frontier · GitHub Platform" → "Agentic DevOps"
  - Aria labels: "Frontier — Home" → "Agentic DevOps — Home"
  - Footer brand text
  - Favicon letter: `F` → `A` (inline SVG data URI)
  - Hero section (index.html): eyebrow, h1, lede rewritten
- `docs/assets/js/` — `document.title` strings, file header comments updated
- Module nav links: `m=agentic-devops` → `m=sre-agent`, label "Agentic DevOps" → "SRE Agent"

**Intentionally NOT Changed (Kaylee):**
- `docs/assets/img/icon-agentic-devops.svg` — filename and `<img src>` kept
- CSS classes like `mod-agentic-devops` — cosmetic, safe to defer

**Verification:** Build clean: 4 modules, 57 challenges, 36 edges. platform.json has module `sre-agent` (6 challenges, track agentic-lifecycle). Zero "Frontier" brand in site HTML/JS. Zero stray `agentic-devops` id (only intentional icon filename + upstream URLs remain).

---

### frontier-ghplatform-hackathon: Anti-FOUC Inline Theme Script (2026-06-15)

**Status:** ✅ Implemented

**Author:** Kaylee (Frontend / Site Engineer)

**Requested by:** Marco (@olivomarco)

**Summary:** Fixed Flash of Unstyled Content (FOUC) for theme by adding a tiny synchronous render-blocking inline `<script>` in `<head>` of all four pages, positioned **before** the stylesheet.

**Context:** Light mode users experienced a dark flash on page navigation. Root cause: all pages had `data-theme="dark"` hardcoded; `docs/assets/js/core.js` corrected the theme at the **end of `<body>`**, so the browser painted dark first, then corrected it.

**Solution:**

```html
<script>
  (function () {
    try {
      var k = 'fp-theme';
      var saved = localStorage.getItem(k);
      var pref = window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', saved || pref);
    } catch (e) {}
  })();
</script>
```

**Rationale:**
- **Inline, not external** — external scripts add a network round-trip and cannot reliably prevent FOUC.
- **Before the stylesheet** — ensures `data-theme` is set before any theme-dependent CSS is evaluated.
- **Same key as core.js** — uses `'fp-theme'` matching `core.js THEME_KEY`. If the key changes in core.js, all four inline scripts must be updated identically.
- **No change to core.js** — core.js owns the theme toggle button. The inline script and core.js share the same key; core.js re-setting the same value post-load is a harmless visual no-op.
- **`data-theme="dark"` retained on `<html>`** — valid no-JS fallback.

**Files Changed:**
- `docs/index.html`, `docs/catalog.html`, `docs/challenge.html`, `docs/module.html` — anti-FOUC script inserted after `<meta name="viewport">`, before preconnect links and stylesheet

**Conventions Established:**
- All pages (current and future) must include the anti-FOUC inline script in `<head>`, before the stylesheet.
- Script must be **identical** across all pages and **kept in sync with `core.js THEME_KEY`**.
- Do not move to an external file — that defeats the purpose.

**Verification:** Build clean: 4 modules, 57 challenges, 36 edges. Script present in `<head>` of all 4 pages, before stylesheet. Logic matches core.js. No FOUC observed in light-mode navigation.

---

### frontier-ghplatform-hackathon: Shared "Environment Setup" Challenge Template (2026-06-15)

**Date:** 2026-06-15  
**Author:** Mal (Lead / Architect)  
**Status:** APPROVED — Zoe executes  
**Requested by:** Marco (@olivomarco)

**Summary:** Defines a unified contract for all module "Environment Setup" challenges (tier: setup, first challenge of each module). Specifies locked meta.yml fields, README skeleton, COACH skeleton, and independence rules. Four setup challenges follow this template: GHEC ch00 (new), GHAS 00 (new after renumber), GHAW 0-00 (refreshed), SRE Agent 00 (refreshed).

**Key decisions:**
- All setup challenges: `tier: setup`, `prerequisites: []`, `difficulty: beginner`, `emu_compatible: true`
- Success criteria must be shell-command verifiable (not subjective observations)
- First real challenge of each module (`ghec-ch01`, `ghas-01`, `ghaw-01`, `sre-agent-01`) retains `prerequisites: []` — setup is not a hard blocker; it's a resource enabler documented via `prerequisite_capabilities`
- README sections: Objectives → Prerequisites → Option A Codespaces → Option B Dev Container → Authenticate CLI → Verify Setup → Next Step
- COACH sections: Objectives → Facilitation Hints → Common Blockers & Fixes table → Success Check list → Access-Blocked Fallback

**Files:** Specifications in `mal-setup-challenge-template.md`; implementations follow in Zoe's four separate decisions.

---

### frontier-ghplatform-hackathon: GHEC ch00 Environment Setup Challenge Created (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ DONE  
**Requested by:** Marco (@olivomarco)

**Summary:** Created `modules/ghec/challenges/ch00-environment-setup/` (three files: meta.yml, README.md, COACH.md). Follows Mal's shared template contract. Challenge ID: `ghec-ch00`, title: "Environment Setup", track: `developer-flow`, `prerequisites: []`.

**Content sources:** `retired-private-predecessor/scripts/setup.sh` (provisioning CLI commands, tool versions), `retired-private-predecessor/README.md` (setup narrative).

**Key fields:** `tier: setup`, `duration_minutes: 25`, `difficulty: beginner`, `min_environment: org`, `app_dependency: none`, `emu_compatible: true`.

**Verification:** `ghec-ch01` retains `prerequisites: []` — ch00 is not a hard blocker (participant with existing environment can skip). Build-ready; `node docs/build.js` not executed by Zoe (separate shared step).

---

### frontier-ghplatform-hackathon: GHAS Renumber (00..05 → 01..06) + New ghas-00 Environment Setup (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ Implemented  
**Requested by:** Marco (@olivomarco)

**Summary:** Part 1 — renamed all 6 existing GHAS challenges (00→01, 01→02, ..., 05→06) to free up position 00 for the new setup challenge. Updated all `id:` fields and `prerequisites:` cross-refs in meta.yml files. Part 2 — created new `modules/ghas/challenges/00-environment-setup/` with meta.yml, README.md, COACH.md. Challenge ID: `ghas-00`, `prerequisites: []`.

**Prerequisite decisions:** `ghas-01` (formerly 00, "Explore the Attack Surface") retains `prerequisites: []` — it was the original entry point. `ghas-02` through `ghas-06` updated to list `ghas-01` (not the old 00).

**Content sources:** `retired-private-predecessor/docs/getting-started.html`, `retired-private-predecessor/docs/prerequisites.html`, `retired-private-predecessor/Student/README.md`.

**Key fields:** `tier: setup`, `duration_minutes: 25`, `app_dependency: juice-shop`, `min_environment: org`.

**Challenge count impact:** GHAS 6 → 7 (net +1 new setup). Global 57 → 58.

---

### frontier-ghplatform-hackathon: Refresh ghaw-00 to Shared Setup Template (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ Done  
**Requested by:** Marco (@olivomarco)

**Summary:** Refreshed existing `modules/ghaw/challenges/00-setup/` (no rename; id `ghaw-00` unchanged). Applied Mal's template contract to meta.yml, README, and COACH.md. Upgraded `success_criteria` from mixed soft items to 5 verifiable shell commands: `gh auth status`, `gh --version`, `gh aw --version`, `gh aw run examples/hello-world.md --dry-run`, `gh repo view retired private predecessor repo`.

**Title decision:** Kept as `Challenge 00 — Environment Setup` (existing value, matches template for GHAW continuity).

**Prerequisite integrity:** All 24 non-setup GHAW challenges retain `ghaw-00` in prerequisites — correct because `gh-aw` CLI is a hard dependency installed by setup.

---

### frontier-ghplatform-hackathon: sre-agent-00 Refreshed to Environment Setup Template (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ DONE  
**Requested by:** Marco (@olivomarco)

**Summary:** Refreshed `modules/sre-agent/challenges/00-setup/` (no rename; id `sre-agent-00` unchanged). Changed title from "Setup and Team Launch" to "Environment Setup". Restructured README to lead with environment setup (6 explicit shell checks), then present team-launch content as a clearly-labelled second section (Contoso Claims scenario, roles, working agreements preserved). Updated `app_dependency: contoso-app` → `contoso-claims` per template. Added `tags: [setup, devcontainer, sre-agent]`. Aligned COACH.md to full skeleton.

**Independence ruling:** `sre-agent-01` retains `prerequisites: []` — Challenge 01 (GitHub SDLC Baseline) does not technically require Azure subscription from ch00.

**Files changed:** meta.yml (title, app_dependency, tags, success_criteria, prerequisite_capabilities), README.md (full restructure: env lead, Team Launch §2), COACH.md (skeleton sections).

---

### frontier-ghplatform-hackathon: README/CONTRIBUTING Tables Updated to 59 Challenges (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ Implemented  
**Requested by:** Marco (@olivomarco)

**Summary:** Updated challenge inventory counts in README.md and CONTRIBUTING.md to reflect final state after setup challenge work. Old counts: 57 total, GHEC 20, GHAS 6, GHAW 24. New counts: 59 total, GHEC 21 (+1 ch00), GHAS 7 (+1 00), GHAW 25 (+1 refresh), SRE Agent 6 (unchanged).

**Changes:** README.md tagline "57 challenges" → "59 challenges"; module table rows updated. CONTRIBUTING.md no changes required (existing `ghas-00` example now refers to setup challenge, which is canonical).

**Verification:** Source of truth `docs/assets/data/platform.json`: 4 modules, 59 challenges (ghec 21, ghas 7, ghaw 25, sre-agent 6).

---

### frontier-ghplatform-hackathon: Environment Setup Challenges — Build QA Report (2026-06-15)

**Date:** 2026-06-15T17:57:52Z  
**QA By:** Simon  
**Requested by:** Marco (@olivomarco)

**Status:** ✅ RESOLVED — Coordinator fix applied

**Summary:** QA verified all setup challenge work (Mal's template, 4 module implementations, Zoe's 7 decisions, doc updates). Build exits clean: 59 challenges, 4 modules, 36 prerequisite edges. All four setup challenges present with correct tier, prerequisites, and track position. Dependency integrity clean. One defect found and fixed by Coordinator: `sre-agent-01` initially had `prerequisites: [sre-agent-00]`; updated to `prerequisites: []` per independence rule. Stale data dirs (ghaw-ch01, ghaw-ch10) removed as cleanup.

**Checks passed:**
- ✅ Build 0 exit code, 59 challenges
- ✅ Per-module counts (ghec 21, ghas 7, ghaw 25, sre-agent 6)
- ✅ All 4 setup challenges (tier, prereqs, track position)
- ✅ Dependency integrity (no dangling edges, renumber clean)
- ✅ Independence rule (ch01/01/sre-01 all have `prerequisites: []`)
- ✅ Setup guide files (all 4 have README.md + COACH.md)
- ✅ Next-step links in setup READMEs all valid

**Defect (RESOLVED):** `sre-agent-01` independence rule violation → Coordinator fixed in meta.yml.

**Cleanup:** Stale `docs/assets/data/challenges/ghaw-ch01/`, `ghaw-ch10/` dirs removed.

**Final verdict:** SHIP-READY. 59 challenges, 4 tier:setup, all first-real-challenges have `prerequisites: []`.

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

---

### frontier-ghplatform-hackathon: Pages Resource Link Rewriting (2026-06-16)

**Status:** ✅ Implemented

**Summary:** Challenge guide markdown is rendered inside `challenge.html`, so source-valid links like `../../resources/Agent-Ready-Issue-Template.md` resolve incorrectly on GitHub Pages as `/resources/...` and 404. The build now copies each module's `resources/` bundle to `docs/resources/<moduleId>/` and rewrites generated guide resource links to `resources/<moduleId>/...`.

**Rationale:** Keep module source docs repo-relative and readable while making generated Pages links resolve from the deployed site root. Generated resources remain build artifacts and are ignored by git.

**Verification:** `npm run build`; generated resource-link validation confirmed all `resources/...` targets exist and no known bad resource URL forms remain.

**Owner:** Zoe

### frontier-ghplatform-hackathon: Homepage Environment-Setup Section (2026-06-15)

**Date:** 2026-06-15  
**Author:** Kaylee (Frontend / Site Engineer)

**Status:** ✅ Implemented

**Summary:** Added a static `#setup` section to `docs/index.html` (just above `</main>`, after the "featured" section) containing four `ch-card` anchor links — one per module — pointing to the four `tier: setup` challenges.

**Implementation notes:**
- Uses existing `.ch-card`, `.challenge-grid`, `.section-tight`, `.shead`, `.eyebrow`, `.badge` classes — no new CSS added.
- Module colors applied via inline `style="--mod-color:var(--c-{token})"` since `sre-agent` has no `.mod-sre-agent` CSS class (its token is `--c-agentic`).
- All four links are real `<a>` anchors with correct `href="challenge.html?id=..."` values.
- `docs/index.html` is hand-authored; no build step needed.

**Stable IDs used:**
| Module | Challenge ID | href |
|--------|-------------|------|
| GHEC | ghec-ch00 | challenge.html?id=ghec-ch00 |
| GHAS | ghas-00 | challenge.html?id=ghas-00 |
| GHAW | ghaw-00 | challenge.html?id=ghaw-00 |
| SRE Agent | sre-agent-00 | challenge.html?id=sre-agent-00 |

---

### frontier-ghplatform-hackathon: Render Success Criteria Inline Markdown (2026-06-19)

**Date:** 2026-06-19  
**Author:** Kaylee (Frontend / Site Engineer)

**Status:** ✅ Implemented

**Summary:** Render Markdown only for challenge success criteria in the sidebar, using a focused `FP.renderInlineMd()` helper.

**Rationale:** Success criteria content is authored with simple inline Markdown and was visibly leaking syntax. Prerequisite capabilities stay plain escaped text because they are capability labels, not rich prose, and broadening Markdown rendering there would be unnecessary behavior change.

**Safety posture:** The helper uses `marked.parseInline()` when present, then sanitizes output to a small inline allowlist and safe link protocols; fallback remains `FP.esc()`.

---

### frontier-ghplatform-hackathon: Inventory Reconciliation — 59 vs 60 Challenges (2026-06-16)

**Date:** 2026-06-16  
**Author:** Mal (Lead / Architect)

**Status:** ✅ Adopted

**Summary:** Repository correctly builds **59 challenges**, not 60. The apparent missing challenge is the SRE Agent sequence gap at `02`. That gap traces to the approved removal of `agentic-devops-02` ("Build with GitHub Copilot") before the module rename to `sre-agent`; it would otherwise have become `sre-agent-02`.

**Module counts:**
| Module | Count |
|---|---:|
| GHEC | 21 |
| GHAS | 7 |
| GHAW | 25 |
| SRE Agent | 6 |

**Decision:** Do **not** restore or recreate `sre-agent-02` as part of reconciliation. The gap is intentional unless Marco explicitly reverses the prior removal decision. Preserve challenge independence:
- `sre-agent-01` remains independently runnable with `prerequisites: []`.
- `sre-agent-03` depends only on `sre-agent-01`.
- No replacement challenge should be invented only to satisfy a numeric sequence.

**Documentation cleanup applied:**
- `modules/README.md`: updated stale module counts to GHEC 21, GHAS 7, GHAW 25, SRE Agent 6.
- `README.md`: updated the GHAW track list to match the build contract.
- `CONTRIBUTING.md`: updated track slugs/names to match `docs/build.js` and `platform.json`.

---

### frontier-ghplatform-hackathon: External Audit Robustness (2026-06-19)

**Date:** 2026-06-19  
**Author:** Simon (QA / Build Engineer)

**Status:** ✅ Implemented

**Summary:** Treat externally audited URL strings as untrusted extraction candidates. Raw Markdown URL extraction should avoid common Markdown delimiters, and the external checker must catch invalid URL/request construction so malformed candidates generate warnings at most and never crash the audit.

**Rationale:** Content can legitimately include localhost examples and inline Markdown forms that expose raw URL-looking substrings. The QA gate should report bad links without blocking on a tooling crash, preserving deterministic audit behavior.

---

### frontier-ghplatform-hackathon: GHEC Ch05 Documentation — Inline Link Strategy (2026-06-19)

**Date:** 2026-06-19  
**Author:** Zoe (Content/Curriculum Engineer)

**Status:** ✅ Complete

**Scope:** GHEC Challenge 5 (Advanced PR Automation & Rulesets)

**Rationale:** Student-facing challenge documentation should embed official references **contextually near the task they support**, not in a static reference dump at the end. This approach:
- **Reduces cognitive load:** Students see the link at the moment they need it, not later.
- **Improves retention:** Context + reference together = better learning.
- **Supports scanning:** Inline links signal "this concept has official backing."

**Decision:**
1. **README.md (student guide):** Embedded verified docs.github.com links in 6 task sections (Parts A–F)
   - Part A: Link to "Creating rulesets for a repository" 
   - Part B: Link to "About code owners"
   - Part C: Link to "Automatically merging a pull request"
   - Part D: Link to "Creating a pull request template"
   - Part E: Links to `actions/labeler` and `actions/stale` official repos
   - Part F: Link to "Managing rulesets for organizations"

2. **COACH.md (facilitation guide):** Added just-in-time references in facilitation notes and common pitfalls sections

3. **meta.yml (metadata):** Updated `references` list from 7 to 11 items with verified official sources

4. **README.md "Reference links" section:** Consolidated to avoid redundancy, with CLI manual links only

**URL Verification Strategy:**
- Searched docs.github.com for official Rulesets, Auto-Merge, CODEOWNERS, PR Templates, Merge Queue docs
- Confirmed GitHub Actions org repository URLs (actions/labeler, actions/stale)
- Verified cli.github.com/manual paths (gh_pr_merge, gh_ruleset)
- No hallucinated URLs: All 11 references are official, resolvable sources

**Validation:**
- `npm run audit:content` passed (220 files, 1055 URLs, 59 challenges, 0 errors)
- Build generated platform.json and dependency-graph.json successfully
- No structural, grammar, or formatting issues introduced

**Files Changed:**
1. `modules/ghec/challenges/ch05-advanced-pr-automation/README.md` — 6 inline links + consolidated reference section
2. `modules/ghec/challenges/ch05-advanced-pr-automation/COACH.md` — 7 inline references
3. `modules/ghec/challenges/ch05-advanced-pr-automation/meta.yml` — 11 verified references

---

### frontier-ghplatform-hackathon: Global Official References Are Contextual (2026-06-19)

**Date:** 2026-06-19  
**Owner:** Zoe (Content/Curriculum Engineer)

**Status:** ✅ Approved

**Context:** Marco clarified that documentation-link improvements apply across all modules, not only GHEC Ch05. The goal is verified, natural official references in both student and coach material without changing seed repositories or adding generic resource dumps.

**Decision:** Add official references at point of use in `README.md` and `COACH.md`, then mirror the final verified URL set in each changed challenge's `meta.yml`. Prioritize sparse challenges and obvious official docs topics. Prefer docs.github.com, learn.microsoft.com, cli.github.com, official GitHub/Azure repositories, and OWASP where relevant.

**Implications:**
- New links should explain the task immediately around the sentence where the learner needs the reference.
- Metadata references should stay aligned with actual content links and source links.
- External-audit warnings from inherited placeholder/source-attribution links should be reported separately from newly added verified references.

---

### frontier-ghplatform-hackathon: Content QA Normalization (2026-06-19)

**Date:** 2026-06-19  
**Owner:** Zoe (Content/Curriculum Engineer)

**Status:** ✅ Implemented

**Decision:** Use the existing GHEC-style quality pattern as the normalization target: every challenge needs complete metadata, visible student validation, coach assessment/verification support, clear provisioning assumptions, and no fabricated placeholder URLs. Setup challenges may remain lightweight, but non-setup security challenges should include coach-facing assessment detail.

**Implications:**
- GHAS coach guides now include concise point-weighted assessment rubrics rather than only facilitation notes.
- SRE module references must refer to the intentional 00, 01, 03, 04, 05, 06 sequence; do not reintroduce Challenge 02 wording unless the removed challenge is restored.
- External audit warnings are acceptable only when they are expected local/private/source references; placeholder and stale-doc warnings should be fixed in content.

---

### Submodule + Symlink Pattern for Local App Provisioning (2026-06-23)

**Date:** 2026-06-23  
**Author:** Wash (DevOps / Build)  
**Status:** Proposed — pending team ratification

**Context:** GHAS participants need OWASP Juice Shop running locally (port 3000) for manual exploit testing. Previously the instructions said `cd app && npm start` without a pinned, reproducible way to get `app/` — participants copy-pasted SHA references from challenge READMEs, which was error-prone.

**Decision:** The **standard pattern for locally-run apps** in this curriculum is:

1. **Git submodule** registered at `external/<name>`, pinned to a specific commit SHA in the gitlink. `.gitmodules` carries the URL and `shallow = true`.
2. **Committed symlink** from a stable challenge-expected path (e.g., `app/`) to `external/<name>`, so instructions never need to reference the submodule's internal location.
3. **Lazy provisioning** — the submodule working tree is NOT fetched at container create time. Participants run `npm run setup:<name>` when they need it.
4. **`scripts/provision-app.sh`** — a single generic script driven by the app key. It reads `external-repos.json`, inits the submodule, verifies the SHA, ensures symlinks, and prints next steps.
5. **`external-repos.json` as source of truth** — each submodule-backed app carries a `provisioning` block: `{ "method": "submodule", "submodule_path": "...", "symlinks": [...], "npm_script": "..." }`.
6. **Drift check in `npm run verify:repos`** — `validateSubmodules()` asserts `.gitmodules` URL presence, gitlink SHA == `source.sha`, and (if checked out) HEAD SHA == `source.sha`.

**Applied to Juice Shop:**
- Submodule: `external/juice-shop` pinned at `f356a09207c7a9550eb6fc4c3945e081922cf998` (tag `v20.0.0`)
- Symlink: `app → external/juice-shop`
- NPM script: `npm run setup:juice-shop`
- The submodule is the LOCAL RUNTIME only. The org-imported repo that carries GHAS alerts is completely separate and unaffected.

**Adding a new local app:**
1. Register submodule: `git submodule add --depth 1 <url> external/<name>` + checkout pinned SHA.
2. Set `shallow = true` in `.gitmodules`.
3. Create committed symlink(s) if needed.
4. Add `provisioning` block to `external-repos.json`.
5. Add `setup:<name>` npm script in `package.json`.
6. Run `npm run verify:repos` to confirm drift check passes.

**Rationale:**
- **Pinned in-tree:** gitlink stores the exact SHA in the parent repo's tree — drift is impossible once committed.
- **Lazy = fast containers:** participants who skip GHAS don't pay the ~61 MB Juice Shop download at container create time.
- **Generic:** the provision script and drift check are key-driven; adding future apps requires only a manifest entry + npm script.
- **Symlinks work in Codespaces/Linux devcontainers:** the expected deployment environment. Windows native checkout is out of scope (documented limitation).

---

### Deterministic Content-Audit Guardrails (2026-06-19)

**Date:** 2026-06-19  
**Owner:** Simon (QA / Tester)  
**Status:** Proposed follow-up

**Context:** The content audit now fails on structural P0/P1 issues: folded YAML parser regressions, empty required meta fields, unresolved production placeholders, missing guide files, stale catalog data, and undocumented numbering gaps.

**Follow-up candidates:**
- Decide whether SRE Agent challenge tags should be required and backfill tags for `sre-agent-01`, `03`, `04`, `05`, and `06`.
- Decide whether GHAS coach guides should add an explicit expected-output, verification, or rubric section so the new warning becomes a future hard gate.

**Current validation:** `npm run audit:content`, `npm run verify:repos`, and the sample app `npm test` pass.

---

### QA Rubric and Catalog Backlog Gates (2026-06-19)

**Date:** 2026-06-19  
**Owner:** Mal (Lead / Architect)  
**Status:** Proposed

**Context:** The catalog has reached a full current-scope inventory of 59 challenges. Future changes need a consistent way to score challenge readiness, classify defects, and decide whether omitted source material should become backlog.

**Decision:** Use the `CONTRIBUTING.md` QA rubric as the challenge-readiness gate: 100 points, P0/P1 blocking severity, P2 tracked follow-up severity, and P3 polish severity. Use JSON Lines-compatible inventory objects for per-challenge review records in PR comments, issue bodies, or generated reports rather than creating planning markdown files in the repo.

**Backlog stance:**
- GHEC and GHAW are complete for the current scope.
- GHAS remains security-focused; excluded Copilot app/frontend/backend material is declined for this module unless Marco reopens scope as a separate module/track.
- `sre-agent-02` remains intentionally absent after the removed Copilot-engineering challenge. A future replacement must be SRE-lifecycle-specific and pass the same rubric before content work starts.

**Final missing-candidate classification:** Current catalog review covers 59 challenges: GHEC 21, GHAS 7, GHAW 25, and SRE Agent 6. The catalog is complete enough to ship now; no new challenge is required before release.

---

### Global Official References Are Contextual, Not Resource Dumps (2026-06-19)

**Date:** 2026-06-19  
**Owner:** Zoe (Content/Curriculum Engineer)  
**Status:** Proposed

**Context:** Marco clarified that documentation-link improvements apply across all modules, not only GHEC Ch05. The goal is verified, natural official references in both student and coach material without changing seed repositories or adding generic resource dumps.

**Decision:** Add official references at point of use in `README.md` and `COACH.md`, then mirror the final verified URL set in each changed challenge's `meta.yml`. Prioritize sparse challenges and obvious official docs topics. Prefer docs.github.com, learn.microsoft.com, cli.github.com, official GitHub/Azure repositories, and OWASP where relevant.

**Implications:**
- New links should explain the task immediately around the sentence where the learner needs the reference.
- Metadata references should stay aligned with actual content links and source links.
- External-audit warnings from inherited placeholder/source-attribution links should be reported separately from newly added verified references.

---

### Provisioning Defect Fixes — Ready for Simon Re-Review (2026-06-23)

**Status:** ✅ APPROVED by Simon (2026-06-23)

**Date:** 2026-06-23  
**Author:** Mal (Lead / Architect)  
**Reviewer:** Simon (Tester/QA)

**Summary:** Mal applied four targeted fixes to `scripts/provision-app.sh` and `package.json` after the initial review rejection by Simon. The fixes address: (D1) removal of broken `setup:app` npm script, (D2) conversion of symlink-collision silent failure to hard error exit, (D3) node-fallback multi-symlink join fix, (D4) removal of dead `ENTRY_SCRIPT` variable. All fixes validated and approved by Simon. Regression tests pass.

**Key fixes:**
- **D1 (P1):** `setup:app` script removed from `package.json`; only `setup:juice-shop` remains.
- **D2 (P2):** Real-directory collision now exits non-zero with clear error; no success banner.
- **D3 (P3):** Node fallback symlinks now joined with `\n` not space.
- **D4 (trivial):** Dead `ENTRY_SCRIPT` variable removed.

**Validation:** bash -n pass, idempotent test pass, regression tests pass. Ready to merge.

---

### Decision: `retired` / `vendored_in` Manifest Convention for Retired Source Repos (2026-06-23)

**Status:** ✅ Adopted

**Owner:** Mal (Lead / Architect)

**Summary:** Four private Microsoft repositories (`retired-private-predecessor`, `retired-private-predecessor`, `retired-private-predecessor`, `frontier-agenticdevops-hackathon`) are being deleted after content vendoring in-tree. The `external-repos.json` manifest now supports optional `retired: true` and `vendored_in: "modules/.../"` fields to record provenance without breaking verify scripts or challenge rendering.

**Key decision:** This repo's origin = `microsoft/frontier-agenticdevops-hackathon` = the **LIVE consolidated repo (KEPT)**. Only the private `frontier-ghas/ghaw/ghec-hackathon` repos (+ private contoso sources) are being deleted. The `agenticdevops` slug must never be presented to participants as a dead/archived repo.

**Schema rules:**
- `retired: true` — optional boolean; upstream repo is private/deleted, no network access.
- `vendored_in: "modules/..."` — repository-relative path to in-tree content.
- `source.url` and `source.sha` **must be preserved** as provenance.
- `attribution` text preserved.

**Verify script:**
- Skip network checks for `retired: true` entries.
- Validate `vendored_in` paths exist locally.
- New counters: `retiredVendored`, `vendoredChecks`.

**Challenge rendering:**
- Hardcoded slug allowlist `RETIRED_SOURCE_REPOS` in `challenge.js`.
- If slug in allowlist → render plain text: "Source: <slug> (archived) · MIT License"
- Otherwise → render live hyperlink.

**7 entries marked retired** with `vendored_in` paths specified in external-repos.json.

---

### wash-embed-provisioning — Embedded Provisioning Assets In-Tree (2026-06-23)

**Status:** ✅ Complete

**Agent:** Wash (DevOps / Build)

**Summary:** Provisioning and scanning-config assets from private upstream repos embedded in-tree: GHEC provisioning machinery (60 files: scripts, libs, challenge provision shells) → `modules/ghec/resources/provisioning/`; GHAS scanning configs (3 YAML files) → `modules/ghas/resources/`.

**GHEC changes:**
- 27 `.sh` scripts copied; all passed `bash -n`.
- GHEC challenge READMEs (21 files) updated to use new in-tree paths: `bash modules/ghec/resources/provisioning/scripts/setup.sh <ch##> --org <org>`.
- Path computation at runtime handles the embed transparently (REPO_ROOT resolves correctly).

**GHAS changes:**
- 3 YAML fixtures copied to `modules/ghas/resources/github/`.
- New `modules/ghas/resources/README.md` documents source and usage.

**Validation:** No upstream-repo references remain; all scripts validated; challenge READMEs updated.

---

### Decision: Embed GHAW examples and remove dead upstream-repo setup steps (2026-06-23)

**Status:** ✅ Implemented

**Author:** Zoe (Content / Curriculum Engineer)

**Summary:** Removed all participant instructions that fork/clone private upstream repos (`retired-private-predecessor`, `frontier-agenticdevops-hackathon`, `retired-private-predecessor`). Embedded GHAW starter example in-tree at `modules/ghaw/resources/examples/hello-world.md`. All setup workflows (GHAW 4 files, SRE Agent 2 files, GHAS setup.md) rewritten to reference THIS consolidated repo only.

**Changes:**
- **GHAW setup:** Option A opens THIS repo's Codespace; Option B clones THIS repo. Smoke-test path → `modules/ghaw/resources/examples/hello-world.md`. Removed `gh repo view retired private predecessor repo` step.
- **SRE Agent setup:** Removed `gh repo view microsoft/frontier-agenticdevops-hackathon` success criterion.
- **GHAS setup:** Option A now uses THIS repo's devcontainer + `npm run setup:juice-shop` + Juice Shop v20.0.0 from public upstream.

**Canonical workspace model:** Participants work directly in Codespace of `microsoft/frontier-agenticdevops-hackathon` (this repo). Devcontainer auto-installs `gh-aw`. Starter example embedded. No upstream fork required.

**Attribution:** `source_repo:` fields in `meta.yml` files preserved as provenance per plan.

**Validation:** `npm run audit:content` passed: 231 files, 59 challenges, 0 errors.

