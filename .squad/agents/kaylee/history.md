# Kaylee — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)

## Learnings

### Phase 1 — Site UI (2026-06-15)

**Design system decisions:**

- **Palette:** Deep-space canvas (`#03050d` base, deeper than GHEC's `#070a10`). Brand accent: **frontier gold** (`#e8c84a`) — a compass needle / north star. This replaces GHEC's lime, giving the multi-module site its own brand identity.
- **Module accent colors:** GHEC = `#38bdf8` (azure sky / cloud), GHAS = `#f87171` (security red / alert), GHAW = `#a78bfa` (neural violet / AI), Agentic DevOps = `#fb923c` (operational orange / Azure nod). Each encoded into a CSS custom property (`--c-ghec` etc.) and applied via a `--mod-color` context variable on parent elements — so cards, borders, and pills inherit color without duplicating selectors.
- **Typography:** Syne 700–800 (display) + DM Sans (body) + JetBrains Mono (code/labels). Intentionally distinct from GHEC's Bricolage Grotesque + IBM Plex. Syne has an architectural, spacious quality that fits "frontier navigation."
- **Signature element:** An SVG compass rose in the hero — four arcs in module colors, radiating from a central gold star. It slow-rotates (120s, `prefers-reduced-motion` respected). This encodes the "four directions to explore" narrative directly in the hero art.
- **Background atmosphere:** Radial gradient glows per module + a subtle dot-grid instead of GHEC's line grid. Gives depth without noise.

**Component patterns:**
- `--mod-color` CSS variable cascades from `.mod-<id>` classes — allows reusable card/border styling across all modules from one CSS rule.
- Module icon naming: `icon-<moduleId>.svg` in `assets/img/`. Four custom SVGs, each uses its module's accent color and a semantic icon concept (cloud + nodes for GHEC, shield + scan lines for GHAS, neural network for GHAW, gear + waveform for Agentic DevOps).
- Challenge cards: left border = module color (3px, absolute positioned). Hover = translateX(3px) — a subtle "entering" motion metaphor.
- Filter chips: when active for a module chip, background becomes that module's accent color, not the generic gold.

**Markdown rendering:**
- Vendored `marked.min.js` (35KB) locally at `assets/js/marked.min.js` — no CDN required at runtime.
- Rendered via `FP.renderMd(rawMd, targetEl)` in core.js. Fallback to `<pre>` if marked fails to load.
- Coach guide fetched and rendered on view switch (lazy, not preloaded) to avoid unnecessary requests.
- All Markdown URLs are relative paths like `assets/data/challenges/<id>/README.md` — these work from `docs/` as the Pages root.

**Mock data strategy:**
- `docs/assets/data/platform.json` — updated with `_mock: true` flag, 4 modules with real icon/color values, 6 representative challenges across all modules.
- `docs/assets/data/challenges/<id>/README.md` + `COACH.md` — mock content for all 6 challenges. Long enough to test Markdown rendering (code blocks, tables, blockquotes).
- Wash's `build.js` will overwrite `platform.json` on real builds (the `_mock` flag makes this obvious). Challenge Markdown files under `docs/assets/data/challenges/` will also be overwritten.
- The site JS is written to handle both the mock and real data contracts identically.

**Files owned:**
- `docs/index.html`, `docs/catalog.html`, `docs/module.html`, `docs/challenge.html`
- `docs/assets/css/styles.css`
- `docs/assets/js/core.js`, `home.js`, `catalog.js`, `module.js`, `challenge.js`
- `docs/assets/js/marked.min.js` (vendored)
- `docs/assets/img/icon-ghec.svg`, `icon-ghas.svg`, `icon-ghaw.svg`, `icon-agentic-devops.svg`
- `docs/assets/data/platform.json` (mock fixture only — Wash owns the real build output)
- `docs/assets/data/challenges/*/README.md` + `COACH.md` (mock fixtures only)

### Phase 2 — Bug fixes: icon paths + title font (2026-06-15)

**Icon path convention (SETTLED — do not regress):**
- `MODULE_CONFIG` in `docs/build.js` must set `icon` to the full filename: `icon-<moduleId>.svg`.
- `docs/assets/data/platform.json` (built) emits this as-is; JS renders `assets/img/${m.icon}`.
- Physical files live at `docs/assets/img/icon-{ghec,ghas,ghaw,agentic-devops}.svg`.
- The fallback in `module.js` (`'icon-' + mod.id + '.svg'`) is also correct, but the data should always carry the real filename.
- Any new module: add `docs/assets/img/icon-<newModuleId>.svg` + set `icon: 'icon-<newModuleId>.svg'` in MODULE_CONFIG.

**Title font: Chakra Petch replaces Syne:**
- `--font-display: 'Chakra Petch', 'Space Grotesk', system-ui, sans-serif`
- Heading weight: 700 (was 800 — Chakra Petch 700 reads as strong; 800 was unnecessary)
- Heading letter-spacing: -0.01em (was -0.025em — Chakra Petch's geometry doesn't need heavy negative tracking)
- Google Fonts axis: `Chakra+Petch:wght@500;600;700` (Syne dropped entirely)
- Body (`DM Sans`) and mono (`JetBrains Mono`) unchanged.

**Pages that load fonts (must stay consistent):**
- `docs/index.html`
- `docs/catalog.html`
- `docs/module.html`
- `docs/challenge.html`

**Stale fallback counts fix:**
- Updated `index.html` fallback text: meta description and hero text from "57 challenges" → "58", GHAS card "2 tracks" → "1 track", GHAW card "24 challenges" → "25". The real stats are computed by `home.js::renderStats()` from `platform.json` at runtime; HTML fallbacks are now aligned.

### Phase 4 — Bug fix: track cards as in-page navigation anchors (2026-06-15)

**Track card → in-page anchor pattern:**
- Track cards in `renderTracks()` were plain `<div class="track-item">` — visually clickable (pointer cursor) but non-interactive. Fix: dynamically choose tag (`a` vs `div`) based on whether the track has challenges. When `count > 0`, render `<a class="track-item" href="#track-${t.id}">`. When `count === 0`, keep `<div>` — avoids dead anchor links.
- In `renderChallenges()`, each `.group-head` now carries `id="track-${trackId}"` matching the anchor `href`. Track IDs are already URL-safe slugs (e.g. `developer-flow`, `admin-governance`), no escaping needed for the id attribute.
- The CSS `.track-item` already had `text-decoration: none; color: inherit; display: flex;` — changing to `<a>` required zero CSS changes for layout/appearance.

**Scroll-margin-top / nav offset:**
- The sticky nav is `height: 58px`. Added `scroll-margin-top: 72px` to `.group-head` (58px nav + 14px breathing room). This prevents the group heading from landing behind the navbar when the native anchor scroll fires.
- `scroll-behavior: smooth` is already set on `html` — no JS scroll handler needed; native anchor `href="#track-..."` gives smooth scroll for free.

**Edge case guarded:** tracks with 0 challenges are rendered as non-interactive `<div>` (no `href`) — no dead anchor targets.

### Phase 5 — Bug fix: featured home card made clickable (2026-06-15)

**ALL `.ch-card` instances MUST be `<a>` elements — do not regress:**
- `home.js renderFeaturedChallenge()`: was `<div class="ch-card ...">` (broken — not clickable). Fixed to `<a class="ch-card ..." href="${FP.challengeUrl(pick.id)}">`.
- `catalog.js` and `module.js renderChallenges()`: already correctly used `<a href="...">` — no changes needed.
- **Convention (settled):** every `.ch-card` across all pages must be an `<a>` element. Plain `<div class="ch-card">` is wrong — it breaks keyboard navigation and makes the card non-clickable.
- The "Open challenge →" button is kept as a SIBLING `<a>` (explicit affordance) — valid HTML; the two `<a>` elements are siblings inside `#featuredChallenge`, not nested. No CSS changes needed: `.ch-card` already sets `text-decoration: none; color: inherit; display: flex` and has `:focus-visible` styling.



### Phase 5 — Global rebrand: Agentic DevOps + SRE Agent module relabel (2026-06-15)

**Brand collision rule (CRITICAL — do not blanket-replace):**
- The PRODUCT is now branded **"Agentic DevOps"** — header wordmark, `aria-label`, `<title>`, meta descriptions, hero eyebrow/h1/lede, footer brand, JS file header comments, JS `document.title` strings.
- The former MODULE named "Agentic DevOps" / "Agentic DevOps & Azure SRE" is now **"SRE Agent"** with id `sre-agent`. Nav links, footer links, and hero card all use `module.html?m=sre-agent` and label "SRE Agent".
- These are two distinct entities. A blanket find/replace of "Agentic DevOps" → anything would break the brand or the module label. Always reason about each occurrence's context before editing.

**Icon file intentionally kept:**
- `docs/assets/img/icon-agentic-devops.svg` retains its original filename. The `<img src>` in the module card points to this exact path. Do not rename it — the data layer references it by name and it would break icon loading.

**Files changed (Kaylee's scope):**
- `docs/index.html`, `docs/catalog.html`, `docs/challenge.html`, `docs/module.html` — title, meta, favicon (F→A), header wordmark, aria-labels, nav links, footer brand + nav links.
- `docs/index.html` hero — eyebrow, h1, lede all rebranded; module card href + name updated.
- `docs/assets/js/challenge.js` — header comment + `document.title` string.
- `docs/assets/js/module.js` — header comment + `document.title` string.
- `docs/assets/js/home.js`, `catalog.js`, `core.js` — header comments only.

**Verification performed:**
- Zero "Frontier" in docs/*.html and docs/assets/js/*.js ✓
- Zero `m=agentic-devops` in docs/*.html ✓
- Zero module label "Agentic DevOps" / "Agentic DevOps & Azure SRE" in nav/cards ✓
- icon-agentic-devops.svg src unchanged ✓

### Phase 6 — Bug fix: theme FOUC on navigation (2026-06-15)

**Anti-FOUC inline script pattern (SETTLED — do not regress):**

- **Problem:** Every page's static HTML had `data-theme="dark"` baked into the `<html>` tag. `core.js` (loaded at end of body) corrects the theme via `initTheme()` reading `localStorage('fp-theme')` — but not before first paint. Users with light mode saw a dark flash on every navigation.
- **Fix:** Add a tiny synchronous render-blocking inline `<script>` in `<head>`, placed **before** the `<link rel="stylesheet">`, on all four pages: `index.html`, `catalog.html`, `challenge.html`, `module.html`.
- **Pattern:**
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
- **Key rule:** Must be **inline** (not an external file) — external scripts can't reliably prevent FOUC. Must run **before the stylesheet** so the correct theme is used from the first paint.
- **Key rule:** Uses storage key `'fp-theme'` — **must stay in sync with `core.js` `THEME_KEY`**. If the key ever changes in core.js, update all four inline scripts identically.
- **Keep `data-theme="dark"` on `<html>`** — it's a valid no-JS fallback; the inline script overrides it pre-paint.
- **Do NOT remove core.js `initTheme()`** — it owns the toggle button and click handling. The inline head script + core.js share the same key; re-setting the same value post-load is harmless.
- **Any new page added to the site must include this snippet in its `<head>`, before the stylesheet.**

### Phase 7 — Ordering verification: setup challenges render first (2026-06-15)

**How challenge ordering within a module/track is determined (SETTLED — do not regress):**

- **Track order:** `module.js renderChallenges()` iterates `mod.tracks.map(t => t.id)` from `platform.json`. Track array order comes from `MODULE_CONFIG` key/property insertion order in `docs/build.js`. The first track in `MODULE_CONFIG.tracks` is rendered first on the module page.
- **Within-track challenge order:** `renderChallenges()` pushes challenges into `byTrack[key]` in the exact order they appear in the `data.challenges` array from `platform.json`. There is NO secondary sort in JS. The challenge array order in `platform.json` is determined by `build.js` doing an alphabetical `.sort()` on challenge folder slug names (`modules/<id>/challenges/*.sort()`).
- **Why setup challenges render first:** Setup challenge folders are named `00-...` / `s00-...` / `0-00-...` — they sort lexicographically before all other slugs. The build emits them first in the `challenges` array; JS renders them first within their track.

**Verified (2026-06-15) — all four modules correct, no code changes needed:**
| Module | First track | Setup challenge | Renders first? |
|--------|-------------|-----------------|----------------|
| ghec | developer-flow | ghec-ch00 | ✓ |
| ghas | security | ghas-s00 | ✓ |
| ghaw | hello-agent | ghaw-0-00 | ✓ |
| sre-agent | agentic-lifecycle | sre-agent-00 | ✓ |

**home.js featured challenge:** `renderFeaturedChallenge()` picks the first `ghaw` challenge with `difficulty === 'beginner'`. That resolves to `ghaw-0-00` (the GHAW setup challenge) — correctly points at the entry point.

**Side-note (out of scope):** `ghas-s01` (s01-explore-attack-surface) has `tier: setup` in its meta.yml — appears to be a content error (should be `tier: core`). Does NOT affect rendering order (ordering is slug-alphabetical, not tier-based). Zoe owns `modules/**` content fixes.

---

### 2026-06-15 — Environment Setup: Verified setup challenges render first per module (ordering check). No code changes required.
