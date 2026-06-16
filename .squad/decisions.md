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

**Summary:** Defines a unified contract for all module "Environment Setup" challenges (tier: setup, first challenge of each module). Specifies locked meta.yml fields, README skeleton, COACH skeleton, and independence rules. Four setup challenges follow this template: GHEC ch00 (new), GHAS s00 (new after renumber), GHAW 0-00 (refreshed), SRE Agent 00 (refreshed).

**Key decisions:**
- All setup challenges: `tier: setup`, `prerequisites: []`, `difficulty: beginner`, `emu_compatible: true`
- Success criteria must be shell-command verifiable (not subjective observations)
- First real challenge of each module (`ghec-ch01`, `ghas-s01`, `ghaw-1-01`, `sre-agent-01`) retains `prerequisites: []` — setup is not a hard blocker; it's a resource enabler documented via `prerequisite_capabilities`
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

**Content sources:** `frontier-ghec-hackathon/scripts/setup.sh` (provisioning CLI commands, tool versions), `frontier-ghec-hackathon/README.md` (setup narrative).

**Key fields:** `tier: setup`, `duration_minutes: 25`, `difficulty: beginner`, `min_environment: org`, `app_dependency: none`, `emu_compatible: true`.

**Verification:** `ghec-ch01` retains `prerequisites: []` — ch00 is not a hard blocker (participant with existing environment can skip). Build-ready; `node docs/build.js` not executed by Zoe (separate shared step).

---

### frontier-ghplatform-hackathon: GHAS Renumber (s00..s05 → s01..s06) + New ghas-s00 Environment Setup (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ Implemented  
**Requested by:** Marco (@olivomarco)

**Summary:** Part 1 — renamed all 6 existing GHAS challenges (s00→s01, s01→s02, ..., s05→s06) to free up position s00 for the new setup challenge. Updated all `id:` fields and `prerequisites:` cross-refs in meta.yml files. Part 2 — created new `modules/ghas/challenges/s00-environment-setup/` with meta.yml, README.md, COACH.md. Challenge ID: `ghas-s00`, `prerequisites: []`.

**Prerequisite decisions:** `ghas-s01` (formerly s00, "Explore the Attack Surface") retains `prerequisites: []` — it was the original entry point. `ghas-s02` through `ghas-s06` updated to list `ghas-s01` (not the old s00).

**Content sources:** `frontier-ghas-hackathon/docs/getting-started.html`, `frontier-ghas-hackathon/docs/prerequisites.html`, `frontier-ghas-hackathon/Student/README.md`.

**Key fields:** `tier: setup`, `duration_minutes: 25`, `app_dependency: juice-shop`, `min_environment: org`.

**Challenge count impact:** GHAS 6 → 7 (net +1 new setup). Global 57 → 58.

---

### frontier-ghplatform-hackathon: Refresh ghaw-0-00 to Shared Setup Template (2026-06-15)

**Date:** 2026-06-15  
**Author:** Zoe (Content / Curriculum Engineer)  
**Status:** ✅ Done  
**Requested by:** Marco (@olivomarco)

**Summary:** Refreshed existing `modules/ghaw/challenges/0-00-setup/` (no rename; id `ghaw-0-00` unchanged). Applied Mal's template contract to meta.yml, README, and COACH.md. Upgraded `success_criteria` from mixed soft items to 5 verifiable shell commands: `gh auth status`, `gh --version`, `gh aw --version`, `gh aw run examples/hello-world.md --dry-run`, `gh repo view microsoft/frontier-ghaw-hackathon`.

**Title decision:** Kept as `Challenge 00 — Environment Setup` (existing value, matches template for GHAW continuity).

**Prerequisite integrity:** All 24 non-setup GHAW challenges retain `ghaw-0-00` in prerequisites — correct because `gh-aw` CLI is a hard dependency installed by setup.

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

**Summary:** Updated challenge inventory counts in README.md and CONTRIBUTING.md to reflect final state after setup challenge work. Old counts: 57 total, GHEC 20, GHAS 6, GHAW 24. New counts: 59 total, GHEC 21 (+1 ch00), GHAS 7 (+1 s00), GHAW 25 (+1 refresh), SRE Agent 6 (unchanged).

**Changes:** README.md tagline "57 challenges" → "59 challenges"; module table rows updated. CONTRIBUTING.md no changes required (existing `ghas-s00` example now refers to setup challenge, which is canonical).

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
- ✅ Independence rule (ch01/s01/sre-01 all have `prerequisites: []`)
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
