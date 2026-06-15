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

