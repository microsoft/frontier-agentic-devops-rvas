# Issue-Class Checklist

Concrete patterns to look for, organized by review lens. Use this as a scan list while reading each file. Not every item applies to every file — match against the file type.

## Correctness

- **Commands that won't run**: wrong CLI tool (`gh` vs `git`), invalid/renamed flags, wrong subcommand order, missing required args, placeholder values left literal (`<org>`, `YOUR_TOKEN`).
- **Broken fenced code**: YAML/JSON that won't parse, indentation errors, unbalanced quotes/braces, shell snippets with smart quotes.
- **Cron expressions**: confirm field count and meaning; `0 0 * * 1` is "weekly Monday 00:00", not "daily".
- **Paths and links**: relative paths that don't resolve, links to headings/anchors that don't exist, `source_path` pointing at a missing file.
- **Wrong product mechanics**: steps that assume behavior the product doesn't have (e.g. an Action input that isn't real, a setting in the wrong menu).

## Pacing

- **Duration vs difficulty**: a `beginner` challenge claiming 120 minutes, or an `advanced` one claiming 20, deserves scrutiny.
- **Steps vs time**: count the discrete actions a student must take; estimate realistically against `duration_minutes`.
- **Success criteria reachability**: every item in `success_criteria` must be achievable using only the steps in `README.md` plus stated prerequisites. Flag criteria that require undocumented actions.
- **Prerequisite ordering**: `prerequisites` ids must precede this challenge logically; `prerequisite_capabilities` must not contain challenge ids (those belong in `prerequisites`).
- **Track progression**: difficulty should not jump from beginner straight to advanced within a track without an intermediate bridge or explicit note.

## Hallucinations

These are the highest-value finds — content that sounds authoritative but describes things that don't exist.

- **UI labels and navigation**: button names, tab names, menu paths ("Settings → Code security → ..."). Verify the label and path exist and match current UI. Vague "click the button" is safer than a confidently wrong exact label.
- **APIs and fields**: endpoints, request/response fields, query params, webhook event names, config keys (`*.yml` schema). Confirm against the official API/reference docs.
- **Capabilities**: a product "automatically does X" claims — verify the product actually does X, not a similar-sounding thing.
- **Version numbers and flags**: invented `@v5` action tags, fabricated minimum versions, made-up CLI flags.

## Up-to-dateness

- **Renamed products/features**: e.g. branding and feature-name changes across GitHub, Copilot, Advanced Security, Actions. Match the current official name.
- **Deprecated/EOL**: deprecated Actions, set-output/save-state style deprecations, EOL runtime versions, retired API versions.
- **Action pins**: `actions/checkout@v3` etc. — flag clearly old major versions; confirm the current major before bumping.
- **Defaults that changed**: default branch names, default permissions, default-on/off security features.
- **Navigation drift**: settings that moved between menus across UI revisions.

## Provenance / Cross-file Consistency

- **Counts and totals**: module/challenge totals stated in `README.md`, `modules/README.md`, and module headers must match the actual catalog. The build prints real counts — compare.
- **Cross-file drift**: `meta.yml` `title`/`description`/`success_criteria` must align with the `README.md` body and `COACH.md` expected outputs.
- **Source provenance**: `source_repo` and `source_path` should point at the real upstream location; `ATTRIBUTION.md` should reflect actual sources.
- **Pinned external versions**: versions referenced for Juice Shop / sample apps / vendored resources should match what `external-repos.json` and setup docs pin.
