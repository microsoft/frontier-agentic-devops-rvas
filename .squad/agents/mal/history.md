# Mal — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)

## Learnings

### 2026-06-15 — Setup Challenge Template Contract

**Setup challenge meta.yml locked fields:**
- `tier: setup`, `prerequisites: []`, `difficulty: beginner`, `duration_minutes: 20–30`
- Track = module's FIRST track: ghec→developer-flow, ghas→security, ghaw→hello-agent, sre-agent→agentic-lifecycle
- `tags` must include `setup` and `devcontainer` + one module-specific tag
- `emu_compatible: true` for all; `min_environment: org` for GHEC/GHAS/SRE Agent, `repo` for GHAW
- `app_dependency: none` (GHEC/GHAW), `juice-shop` (GHAS), `contoso-claims` (SRE Agent)
- `success_criteria`: 4–6 items, each a concrete shell command or unambiguous observable

**ID and title conventions:**
- GHEC: `ghec-ch00` / "Environment Setup"
- GHAS: `ghas-s00` / "Environment Setup"
- GHAW: `ghaw-0-00` / "Challenge 00 — Environment Setup" (keep existing)
- SRE Agent: `sre-agent-00` / "Environment Setup" (rename from "Setup and Team Launch")

**Ordering / renumber rules:**
- GHEC: new ch00; ch01–ch20 unchanged; ch01 keeps `prerequisites: []` (no hard dep on ch00)
- GHAS: rename s00→s01, s01→s02, s02→s03, s03→s04, s04→s05, s05→s06 (folders + ids + all cross-refs); then create new s00. Update prerequisites in s02–s06 to reference new ids. ghas-s01 keeps `prerequisites: []`.
- GHAW: no rename; refresh meta.yml/README/COACH to template; keep `ghaw-0-00` in all track challenge prerequisites (hard dep — CLI install)
- SRE Agent: no rename; refactor README to lead with env setup, team-launch becomes clearly-labelled second section; sre-agent-01 keeps `prerequisites: []`

**Independence rule:** List setup challenge in downstream `prerequisites:` only when there is a hard technical artifact that downstream literally cannot proceed without. GHAW: keep (CLI install). GHEC/GHAS/SRE Agent ch01: keep `[]`.

**Superseded expected counts:** GHEC 21, GHAS 7, GHAW 25, SRE Agent 7 = 60 total. See 2026-06-16 reconciliation below: SRE Agent 02 was intentionally removed, so the current source-of-truth total is 59.

**Full template spec at:** `.squad/decisions/inbox/mal-setup-challenge-template.md`

### 2026-06-16 — Inventory Reconciliation

- Current source-of-truth inventory is 59 challenges: GHEC 21, GHAS 7, GHAW 25, SRE Agent 6.
- The missing 60th challenge is not a build bug. It is the intentionally removed `agentic-devops-02` / would-be `sre-agent-02` ("Build with GitHub Copilot"), documented in `.squad/decisions.md`.
- Preserve the SRE Agent sequence gap at 02 unless Marco explicitly reverses that removal decision; do not invent replacement content just to close the count.
- Setup challenge independence still holds: `sre-agent-01` keeps `prerequisites: []`; `sre-agent-03` depends only on `sre-agent-01`.
- Keep docs count/track tables aligned with `docs/build.js` / generated `platform.json`, especially GHAW track ids (`repo-concierge`, `continuous-intelligence`) and GHAS track id (`security`).

### 2026-06-15 — Phase 0 Architecture Analysis

**Source repo structures discovered:**
- **GHEC**: 20 challenges in `challenges/ch01..ch20/`, each with `meta.yml` + `README.md` + `COACH.md`. Best-in-class build engine: `docs/build.js` (zero-dep Node.js, custom minimal YAML parser, emits `challenges.json` + copies guides). Site: hand-crafted HTML/CSS/JS in `docs/`, ~544 lines CSS, dark/light theme, catalog with filters. 4 tracks.
- **GHAS**: 15 challenges as flat `Student/Challenge-{B,C,F,S}##.md` files. 4 tracks (Copilot Customization, Security, Frontend, Backend). 61MB `app/` (Juice Shop source). HTML docs site in `docs/`. No structured metadata — all in prose.
- **GHAW**: 24 challenges + setup in `_challenges/` as Jekyll collection with front-matter (title, description, number, order, difficulty, time, tier, track, track_name, tags). 4 tracks (ai-workflows, mcp-integration, production-patterns, safe-outputs). Jekyll site with `_layouts/`, `_includes/`, Gemfile. Separate `_student_guides/` and `_coach_guides/` collections.
- **Agentic-DevOps**: 7 challenges in `Student/Challenge-00..06.md`. What The Hack format (Scenario/Goals/Tasks/Success Criteria). `Resources/` at 212KB (sample-app, runbooks, infra). Simple `index.html`. Single linear track.

**Key decisions made:**
1. Engine: Extend GHEC's `meta.yml → build.js → docs/` (zero-dep, proven, fast).
2. Schema: Unified `meta.yml` with global IDs (`<module>-<local-id>`), explicit `prerequisites[]` + `prerequisite_capabilities[]` for independence.
3. Dedupe: Keep all modules intact, cross-link via tags. No deduplication.
4. Heavy assets: Exclude Juice Shop (61MB) by reference; vendor Agentic-DevOps Resources (212KB).
5. Layout: `modules/<id>/challenges/<slug>/` as input; `docs/` as output served by Pages.
6. All sources are MIT © Microsoft — unified LICENSE + per-module ATTRIBUTION.md.

**Architecture proposal written to:** `.squad/decisions/inbox/mal-architecture.md`

### 2026-06-15 — Final Review Gate

**Verified:**
- Build clean: 4 modules, 58 challenges, 38 edges, 0 cycles, 0 cross-module prereqs
- All Simon defects (D-001..D-005) confirmed fixed and re-verified
- Independence model holds across all 4 modules — spot-read 6 challenges
- Schema conformance: tiers are clean (core/stretch/setup only), IDs prefix-correct, all ATTRIBUTION.md + GHAS setup.md present
- Cross-linking tags work correctly between GHEC security and GHAS modules
- Agentic-devops linear chain justified (not over-coupled)

**Small corrective edit made:**
- Added Azure subscription to `prerequisite_capabilities` in agentic-devops-04 meta.yml

**Decisions recorded:**
- `extension` tier → `stretch` mapping is correct, no new tier needed
- Engine-swap freshness: no caveat needed now; route to Zoe if engines change materially
- Architecture doc delta (66→58 challenges) is acceptable scope refinement, not a doc bug

**Verdict:** APPROVE — ship-ready. Written to `.squad/decisions/inbox/mal-final-review.md`
