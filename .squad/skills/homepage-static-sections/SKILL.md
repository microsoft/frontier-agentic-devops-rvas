# Skill: Homepage Static Sections (frontier-ghplatform-hackathon)

## What this covers
How to add a new `<section>` to `docs/index.html` that fits the site's visual language.

## Key facts
- `docs/index.html` is **hand-authored**. `docs/build.js` does NOT generate it. Edit it directly.
- `docs/build.js` only writes `docs/assets/data/platform.json` and `docs/assets/data/dependency-graph.json`.

## Section skeleton
```html
<section class="section-tight" id="my-section" aria-labelledby="myHeading">
  <div class="wrap">
    <div class="shead reveal">
      <div>
        <span class="eyebrow">Label text</span>
        <h2 id="myHeading" style="margin-top:14px">Section title.</h2>
        <p>Optional descriptor paragraph.</p>
      </div>
      <a class="link" href="...">Link text →</a>
    </div>
    <!-- content here -->
  </div>
</section>
```

## Challenge card (ch-card) in static markup
```html
<a class="ch-card" href="challenge.html?id={ID}" style="--mod-color:var(--c-{module})"
   aria-label="…">
  <div class="ch-card-top">
    <span class="ch-mod-dot"></span>
    <span class="ch-module-label">MODULE · track</span>
  </div>
  <div class="ch-title">Title</div>
  <div class="ch-desc">Description text.</div>
  <div class="ch-footer">
    <span class="badge badge-difficulty-beginner">setup</span>
  </div>
</a>
```

## Module color tokens
| Module data ID | CSS token | Note |
|---------------|-----------|------|
| ghec | `--c-ghec` | blue |
| ghas | `--c-ghas` | red |
| ghaw | `--c-ghaw` | purple |
| sre-agent | `--c-agentic` | orange — no `.mod-sre-agent` class; inline style only |
| agentic-devops | `--c-agentic` | orange |

## Badge classes
- `.badge .badge-difficulty-beginner` / `intermediate` / `advanced`
- `.badge .badge-duration` for time estimates
- `.badge .badge-tag` for keyword tags

## Rules
- ALWAYS use real `<a href="...">` anchors — never clickable divs.
- Wrap card grids in `<div class="challenge-grid reveal">`.
- Keep `aria-labelledby` on every section pointing to its `<h2 id>`.
