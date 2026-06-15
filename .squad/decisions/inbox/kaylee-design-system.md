# Design System Decision: Frontier Platform Site

**Author:** Kaylee (Frontend / Site Engineer)
**Date:** 2026-06-15
**Status:** Implemented (Phase 1)

---

## Decision

The Frontier GitHub Platform Hackathon site uses a distinct visual identity that evolves — but does not copy — the GHEC site's design language. Documented here for team reference and future consistency.

---

## Palette

| Token | Dark | Light | Purpose |
|-------|------|-------|---------|
| `--c-900` | `#03050d` | `#f2f5fd` | Canvas base |
| `--c-gold` | `#e8c84a` | `#8a6800` | Brand accent (compass needle / frontier star) |
| `--c-ghec` | `#38bdf8` | `#0284c7` | GHEC module (azure sky) |
| `--c-ghas` | `#f87171` | `#dc2626` | GHAS module (security alert red) |
| `--c-ghaw` | `#a78bfa` | `#7c3aed` | GHAW module (neural violet) |
| `--c-agentic` | `#fb923c` | `#ea580c` | Agentic DevOps module (operational orange) |

**Signature:** Frontier gold is NOT lime. The gold reads as compass/navigation/exploration, which is the correct register for "Frontier." It's warmer and more intentional than a generic accent.

---

## Typography

- **Display:** Syne 700–800 — architectural, spaced, technical without being cold. Different from GHEC's Bricolage Grotesque.
- **Body:** DM Sans — humanist, highly readable. Different from GHEC's IBM Plex Sans.
- **Mono:** JetBrains Mono — developer-focused with ligature support.

Google Fonts load via `<link>` preconnect + single CSS2 URL for performance.

---

## Module Color System

All module color is applied via a `--mod-color` CSS custom property cascaded from a `.mod-<moduleId>` class on parent elements. This keeps the number of CSS rules minimal — one set of card rules, four color variants via inheritance.

```css
.mod-ghec        { --mod-color: var(--c-ghec); }
.mod-ghas        { --mod-color: var(--c-ghas); }
.mod-ghaw        { --mod-color: var(--c-ghaw); }
.mod-agentic-devops { --mod-color: var(--c-agentic); }
```

Applied by `FP.applyModuleColor(el, moduleId)` in core.js.

---

## Component Patterns

### Challenge cards
- Left border 3px = `--mod-color`. Applied via `::before` pseudo-element.
- Hover: `translateX(3px)` — suggests "step in." Intentionally directional, not vertical (avoids collision with adjacent cards).

### Module cards
- Top border 3px = `--mod-color` via `::before`.
- Icon: 44×44px SVG from `assets/img/icon-<moduleId>.svg`.

### Filter chips (catalog)
- Active module chip background = that module's accent color (not generic gold).
- Active difficulty chip background = gold (generic — not module-specific).

### Eyebrow
- Gold 18px dash before mono uppercase text. Different from GHEC's lime dash.

---

## Signature Element

The hero **compass rose** (SVG, inline in `index.html`):
- Four arcs, one per module in its accent color
- Central gold star dot
- Slow 120s CSS rotation (paused on `prefers-reduced-motion`)
- Encoded semantics: "four directions to explore"

This is the one place we spend visual boldness. Everything else is restrained.

---

## Marked.js Handling

- Vendored at `docs/assets/js/marked.min.js` (35KB, v12.0.0)
- Loaded only on `challenge.html` via `<script src="assets/js/marked.min.js">` before core.js
- `FP.renderMd(rawMd, targetEl)` in core.js handles rendering with a `<pre>` fallback if marked unavailable
- Coach guide loaded lazily on tab switch (not preloaded) — avoids fetching content coaches don't open

---

## Data Contract Notes for Wash

The site expects `platform.json` with this module shape:
```json
{ "id": "<moduleId>", "icon": "icon-<moduleId>.svg", "color": "<hex>", ... }
```

The `icon` field should be the filename only (e.g., `"icon-ghec.svg"`), not a full path or icon name. The JS prepends `assets/img/` automatically. If `icon` is absent, the `<img>` will gracefully show no image (no broken alt text — all icons use `alt="" aria-hidden="true"`).

Challenge `student_path` and `coach_path` should be relative to the `docs/` root, e.g., `"assets/data/challenges/ghec-ch01/README.md"`.

---

*Kaylee · 2026-06-15*
