# Zoe — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)


## Session Summary (2026-06-15)

**Delivered:** Phase 1 (GHEC + GHAS port, 27 challenges), Phase 2 (GHAW + SRE port, 32 challenges, linear agentic chain), Phase 3 QA fixes (D-001 YAML indentation, D-003/D-004 broken links, D-005 tier fix), track rename (agentic-arc → agentic-lifecycle), module id rename (agentic-devops → sre-agent), ch02 removal (Copilot engineering), Environment Setup template implementation (GHEC ch00 new, GHAS renumber s00..s05→s01..s06+new s00, GHAW 0-00 refresh, SRE 00 refactor), doc table updates (57→59 challenges).

**Final State:** 59 challenges (GHEC 21, GHAS 7, GHAW 25, SRE 6), 36 prerequisite edges, 0 cross-module, 0 cycles, all setup challenges tier:setup+prereqs:[], all first-real-challenges prereqs:[].

**Key Principles Established:**
- Independence rule: Setup challenges never block first-real-challenges technically (only prerequisite_capabilities).
- Overlap by design: GHEC security (enterprise governance) ≠ GHAS security (code fix on Juice Shop). Different audiences.
- Vendored resources: Contoso Claims scenario + Tools vendored; source links preserved via attribution.
- Tier semantics: setup (infrastructure/auth), core (entry content), stretch (extended learning).

## Detailed Learnings (Archived)

(See git history for detailed session-by-session notes. 12 comprehensive entries 2026-06-15.)

### 2026-06-15 — Phase 1, 2, 3 — Archived Detail Sections

Session delivered 59 challenges across 4 modules via 12 sequential decisions:
1. Phase 1 (GHEC 20/GHAS 6 port) — track/difficulty mapping, prerequisites strategy, emu_compatible flags
2. Phase 2 (GHAW 25/SRE 7 port) — track assignment, linear agentic arc prerequisites  
3. Phase 3 QA (D-001/003/004/005) — YAML indentation fix, link repair, tier correction
4. Track rename (agentic-arc → agentic-lifecycle) — eliminate Azure Arc collision
5. Ch02 removal (Copilot engineering) — scoped out, no blast radius
6. agentic-devops → sre-agent rename — module id clarity, repo brand "Agentic DevOps"
7-12. Environment Setup template (4-module implementation, doc updates) — independence guarantee, setup-first ordering

See `.squad/decisions.md` for merged decision records and git log for commit details per task.

## Session Summary (2026-06-16)

**Delivered:** Fixed confirmed internal resource 404s in generated challenge pages. The Pages build now copies module resource bundles to `docs/resources/<moduleId>/` and rewrites challenge guide resource links such as `../../resources/Agent-Ready-Issue-Template.md` to site-root-relative-in-docs links like `resources/sre-agent/Agent-Ready-Issue-Template.md` during guide generation.

**Validation:** `npm run build` passed (4 modules, 59 challenges, 35 edges). A generated-link validation script confirmed no `olivomarco.github.io/resources`, `/resources`, or parent-relative resource links remain in generated challenge guides and every `resources/...` target exists under `docs/`.

## Session Summary (2026-06-19)

**Delivered:** Embedded official GitHub documentation links naturally throughout GHEC ch05 student and coach materials, replacing a static end-of-document reference dump. All URLs verified against docs.github.com, cli.github.com, and official GitHub Actions repositories. Meta.yml references updated with 11 verified sources including CODEOWNERS, auto-merge, Actions Labeler, Actions Stale, and org ruleset guidance.

**Changes made:**
- README.md: Inline links placed in 6 task sections (Parts A–F) linking to rulesets, auto-merge, CODEOWNERS, PR templates, and org ruleset docs
- COACH.md: Concise reference links embedded in facilitation notes and common pitfalls sections to clarify rulesets vs. classic protection, auto-merge behavior, labeler permissions, and org scope matching
- meta.yml: Consolidated references list expanded from 7 to 11 items, adding CODEOWNERS docs, Actions/Stale, and gh CLI manuals
- README.md Reference links section: Consolidated to acknowledge in-text links and reserve the section for CLI references only

**Validation:** `npm run audit:content` passed (220 files, 1055 URLs, 59 challenges, 0 errors). All embedded links are official GitHub sources; no fabricated or unverified URLs added.

**Key principles reinforced:**
- Student-friendly link placement: Embed references contextually near the task they explain, not in a separate section
- Coach guidance: Provide just-in-time URLs that clarify common misconceptions (rulesets vs. protection, auto-merge prerequisites, security nuances)
- Meta accuracy: Ensure references metadata matches actual links embedded in content

## Learnings

### 2026-06-19 — Global official documentation links

- Official references should be placed where students or coaches need them, then mirrored in `meta.yml`; avoid end-of-file resource dumps and avoid linking every repeated noun.
- The highest-value gaps were sparse challenge sets (`ghaw` Track 4 and `sre-agent` 01/03/04/05/06), while GHEC/GHAS already had broad metadata coverage.
- Verify added URLs before editing; `npm run audit:external` may still report inherited source-attribution 404s and placeholder/local URLs, so distinguish pre-existing warnings from new official links.
- Coach guides need the same factual support as student guides. A short, coach-facing reference line is enough; reuse challenge README/meta references only after checking they are real URLs and not placeholders.

### 2026-06-19 — Content QA workstream

- Scored all 59 challenges with the saved QA rubric and fixed high-confidence P0/P1/P2 content issues surfaced by the pass.
- Normalized GHAS coach assessment with point-weighted rubrics, added missing SRE metadata tags, repaired SRE Challenge 02 references after the intentional numbering gap, and removed concrete placeholder URLs from GHAW examples/templates.
- Validation: `npm run audit:content` passed; `npm run audit:external` passed with warnings only for unresolved external/private/source or localhost references.

### 2026-06-23 — Embed GHAW example content + remove dead upstream-repo dependencies

**Context:** Private upstream repos (`retired-private-predecessor`, `frontier-agenticdevops-hackathon`, `retired-private-predecessor`) are being deleted. Setup instructions and success criteria still pointed at those repos for clone/fork/`gh repo view` steps.

**What changed:**

- **`modules/ghaw/resources/examples/hello-world.md`** — NEW FILE. Faithful copy of `examples/hello-world.md` from `retired-private-predecessor`. This is the canonical gh-aw smoke-test workflow used by all setup docs.
- **`modules/ghaw/resources/examples/README.md`** — NEW FILE. Copy of the examples README from the upstream repo.
- **`modules/ghaw/challenges/0-00-setup/README.md`** — Option A now opens THIS repo's Codespace (not upstream). Option B clones this repo (not `gh repo fork retired private predecessor repo`). Smoke test updated: `gh aw run modules/ghaw/resources/examples/hello-world.md --dry-run` (embedded path). `gh repo view retired private predecessor repo` success step removed (5→4 checks).
- **`modules/ghaw/challenges/0-00-setup/COACH.md`** — Troubleshooting table: removed "Fork not created / `gh repo fork`" row; replaced with "confirm Codespace is for this repo" row. Access-blocked fallback section: removed fork-access paragraph, replaced with "work directly in this repo" guidance. Success checklist: updated dry-run path.
- **`modules/ghaw/challenges/0-00-setup/meta.yml`** — Success criteria: replaced `gh repo view retired private predecessor repo` with `ls modules/ghaw/resources/examples/hello-world.md` (local existence check). Updated dry-run path.
- **`modules/ghaw/setup.md`** — Options 1 and 2 now reference this repo entirely; no more upstream clone or fork.
- **`modules/sre-agent/challenges/00-setup/README.md`** — Option A and B already pointed at this repo by name; clarified "this repository" language. Success criteria: removed `gh repo view microsoft/frontier-agenticdevops-hackathon` (3rd check); added `npm install` before `npm test` for freshness. 4→3 checks.
- **`modules/sre-agent/challenges/00-setup/meta.yml`** — Success criteria: removed `gh repo view microsoft/frontier-agenticdevops-hackathon`; updated sample-app check to include `npm install`.
- **`modules/ghas/setup.md`** — Option A: replaced "open `retired private predecessor repo` source repo and create Codespace" with "open THIS repo in a Codespace + `npm run setup:juice-shop` + `cd app && npm install && npm start`". Preserves Option B (Docker) and Option C (organizer-hosted) unchanged.

**New GHAW workspace model:** Participants work in a Codespace (or local dev container) of THIS consolidated repo (`microsoft/frontier-agenticdevops-hackathon`). The devcontainer's `postCreate.sh` already installs `gh-aw`. The starter example workflow is vendored at `modules/ghaw/resources/examples/hello-world.md` and all setup docs reference that path.

**Validation:** `npm run audit:content` passed (231 files, 59 challenges, 0 errors).

**KEY DECISION:** This repo's origin = microsoft/frontier-agenticdevops-hackathon = the LIVE consolidated repo (KEPT). Only frontier-ghas/ghaw/ghec-hackathon + private Contoso sources deleted. The agenticdevops slug must never be presented as archived.
