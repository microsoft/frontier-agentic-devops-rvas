# SKILL: Static Site Data Conventions (frontier-ghplatform-hackathon)

## Problem solved
When a static site's build script emits data that JS templates consume directly as paths or URLs, the emitted value must be the full, resolvable path fragment — not a semantic/human-readable label. Storing bare names (e.g., `cloud`, `shield`) causes 404s whenever the JS concatenates them into a URL.

## Pattern: Data-driven asset paths

**Rule:** If a JS template renders `src="assets/img/${data.icon}"`, the `data.icon` value must be the literal filename including extension: `icon-ghec.svg`, not `cloud`.

**Why it breaks:** Bare semantic names look meaningful in config but are invisible errors at runtime (the browser just 404s the image). The mismatch lives in the gap between the config author's mental model ("cloud" is meaningful) and the JS author's expectation (the value IS the filename).

**Fix checklist:**
1. In the data-emitting build config (e.g., `MODULE_CONFIG` in `build.js`), set `icon` to `icon-<id>.svg`.
2. The JS rendering layer uses the value directly — no transform needed.
3. Any static HTML fallback must use the same convention.
4. Regenerate the built data file (`node docs/build.js`) — stale JSON will still serve the old bad value.
5. Grep for bare asset requests to verify: `grep -r "assets/img/" docs/assets/js/` should show only values ending in `.svg`/`.png`/etc.

## Pattern: Font swap verification checklist

When swapping a Google Fonts display face:

1. Update `--font-display` in `styles.css`.
2. Update ALL HTML pages that have a `<link href="https://fonts.googleapis.com/...">` — they all must request the new family.
3. Adjust heading `font-weight` and `letter-spacing` to suit the new face's design idiom. Example: a geometric face like Chakra Petch typically reads better at 700 than 800, and needs less aggressive negative tracking (-0.01em) than a wide-spaced face like Syne (-0.025em).
4. Grep for the old font name to confirm it's fully removed: `grep -r "Syne" docs/`.
5. Drop the old font from the Fonts URL — stale families waste a network request.
