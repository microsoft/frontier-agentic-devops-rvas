# Architecture Proposal: frontier-ghplatform-hackathon

**Author:** Mal (Lead / Architect)  
**Date:** 2026-06-15  
**Status:** Proposed — awaiting Marco's approval

---

## A. Information Architecture

Four top-level **modules**, each mapping 1:1 to a source hackathon. Modules contain **tracks**, tracks contain **challenges**. The unified site presents a single catalog with filtering by module, track, difficulty, and tags.

| Module ID | Module Name | Source Repo | Tracks | Challenges |
|-----------|-------------|-------------|--------|------------|
| `ghec` | GitHub Enterprise Cloud | retired-private-predecessor | 4 (Developer Flow, Admin/Governance, Security, Automation & AI) | 20 |
| `ghas` | GitHub Advanced Security & Copilot | retired-private-predecessor | 4 (Copilot Customization, Security, Frontend, Backend) | 15 |
| `ghaw` | GitHub Agentic Workflows | retired-private-predecessor | 4 (Hello Agent, MCP Integration, Production Patterns, Safe Outputs) | 24 (excl. setup) |
| `agentic-devops` | Agentic DevOps & Azure SRE | frontier-agentic-devops-hackathon | 1 (linear arc) | 7 |

**Total: 66 challenges across 13 tracks in 4 modules.**

### Navigation Model

```
Home → Module picker (4 cards)
     → Full catalog (filterable grid: module, track, difficulty, tags)
     → Individual challenge detail (student guide rendered, coach guide behind toggle)
```

Each module page shows its tracks and challenge sequence. The catalog page is the cross-module discovery surface.

---

## B. Challenge/Module Schema — `meta.yml`

Every challenge directory contains a `meta.yml` file as the **single source of truth**. The build step reads only this file. No implicit ordering, no magic filenames beyond the contract below.

### Field Contract

```yaml
# === Required ===
id: ghaw-01                    # Globally unique: <module>-<local-id>
title: "Morning Briefing"
module: ghaw                     # One of: ghec, ghas, ghaw, agentic-devops
track: hello-agent               # Slug within the module
difficulty: beginner             # beginner | intermediate | advanced
duration_minutes: 30            # Estimated time

# === Independence fields (critical) ===
prerequisites:                   # Explicit list; empty = no prereqs
  - ghaw-00                    # References another challenge id OR a capability string
prerequisite_capabilities:       # What a student needs to KNOW (not DO) — skills, not challenges
  - "GitHub Actions basics"
  - "YAML syntax"

# === Descriptive ===
description: "Build a scheduled workflow that creates a daily briefing issue."
success_criteria:
  - "Workflow triggers on cron schedule"
  - "Issue is created with AI-generated summary"
tags:
  - cron
  - schedule
  - ai-summarization

# === Operational ===
app_dependency: none             # none | juice-shop | contoso-claims | seed-repo
emu_compatible: true             # Can this run in an EMU-controlled org?
min_environment: org             # org | repo | codespace
provision_creates: []            # Resources the setup script creates

# === Attribution ===
source_repo: retired private predecessor repo
source_path: _challenges/01-morning-briefing.md
license: MIT

# === Optional ===
tier: core                       # core | stretch | bonus
references:
  - https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule
```

### Example — filled in (GHEC ch01)

```yaml
id: ghec-ch01
title: "Issues, Labels & Project Boards"
module: ghec
track: developer-flow
difficulty: beginner
duration_minutes: 180
prerequisites: []
prerequisite_capabilities:
  - "GitHub account with org access"
description: "Triage, label, and project-board a messy repo of issues using GitHub's built-in planning tools."
success_criteria:
  - "Custom label taxonomy applied"
  - "All issues triaged to project board columns"
  - "At least one automation rule active on the board"
tags:
  - issues
  - labels
  - projects
  - project-boards
app_dependency: none
emu_compatible: true
min_environment: org
provision_creates:
  - "repo wth-ch01-issues-labels-projects (seeded)"
  - "~26 untriaged issues"
  - "empty Projects (v2) board"
source_repo: retired private predecessor repo
source_path: challenges/ch01-issues-labels-projects/meta.yml
license: MIT
tier: core
references:
  - https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues
  - https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects
```

---

## C. Challenge-Independence Model

### Guarantees

1. **Prerequisites are data, not position.** A challenge's `prerequisites` field is an explicit list of challenge IDs (or empty). Position in a track suggests a learning order but does NOT imply dependency.

2. **Capability prerequisites are human-readable.** `prerequisite_capabilities` lists what a student must *know* (e.g., "GitHub Actions basics") — not what they must have *done* in this hackathon. This lets cherry-pickers self-assess.

3. **No shared mutable state.** Each challenge provisions its own repos/resources via setup scripts. No challenge depends on artifacts produced by a prior challenge.

4. **Setup challenge is per-module, not cross-module.** GHAW's `00-setup` and Agentic-DevOps's `Challenge-00-Setup` are flagged as `tier: setup` — they provision environment, not learning content. A student picking any challenge in that module sees "Complete the module setup first" as a prerequisite.

### Verification (CI)

The build step will validate:
- Every `prerequisites` entry references a valid challenge `id` in the catalog.
- No circular dependencies.
- Every challenge with `app_dependency != none` documents how to obtain that app.
- Graph visualization (optional, emitted as `docs/assets/data/dependency-graph.json`) lets the site render a visual prereq map.

---

## D. Site Engine Decision

### Recommendation: Extend the GHEC `meta.yml → build.js → docs/` model.

| Option | Pros | Cons |
|--------|------|------|
| **GHEC build.js (chosen)** | Zero runtime dependencies; fully self-contained Pages deploy from `docs/`; already proven for 20 challenges; trivial to extend to 66; no Ruby/Python/gem version drama; builds in <1s; Marco's team already owns it | Needs multi-module awareness added; no built-in Markdown rendering (client-side is fine) |
| Jekyll (GHAW model) | GitHub-native; good for content sites | Collection routing is rigid; gem version conflicts; slow builds at scale; harder to customize |
| MkDocs | Marco has used it before; good for docs | Adds Python dependency; plugin ecosystem is fragile; not ideal for catalog-style navigation |

### What we extend

1. **build.js** gains a `modules/` config (reads from `modules/<id>/challenges/` instead of a single `challenges/` dir).
2. **Output shape** becomes `challenges.json` → `platform.json` with top-level `modules[]` and `challenges[]` arrays.
3. **Site pages**: `index.html` (landing), `catalog.html` (full filterable grid), `module.html?m=ghec` (module detail), `challenge.html?id=ghec-ch01` (challenge detail with Markdown rendering via marked.js — a 40KB client-side lib, or raw `.md` link).
4. **CSS/JS**: Evolve GHEC's existing design system. Kaylee extends it for multi-module nav + new color palette per module.
5. **No server, no build tools beyond Node.js core + the single `build.js` script.**

### Deploy

GitHub Actions workflow: on push to `main`, runs `node docs/build.js`, commits output to `docs/`, Pages serves from `docs/` on the default branch. Same pattern GHEC already uses.

---

## E. Overlap / Dedupe Strategy

### Decision: Keep all modules intact. Cross-link, do NOT deduplicate.

**Rationale:**
- GHEC ch11–15 (security track) overlaps GHAS in *topic* but not in *approach*. GHEC challenges use GHAS features within an enterprise governance context; GHAS challenges go deep on Juice Shop exploitation and fix cycles. Different audience, different depth.
- GHEC ch16–20 (automation/AI) overlaps GHAW in topic but GHEC focuses on enterprise automation (REST/GraphQL, webhooks, apps, runners) while GHAW focuses on AI-agent-driven workflows. Minimal actual content duplication.
- Deduplication would break the independence guarantee — students who only do GHEC would lose challenges.

**Implementation:** Each challenge's `tags` and a `related_challenges` field (optional) enable the UI to show "Related challenges in other modules" as a cross-link sidebar. Build.js computes related suggestions based on shared tags.

---

## F. Heavy-Asset Strategy

### Decision: Do NOT vendor heavy assets. Reference source repos.

| Asset | Size | Decision |
|-------|------|----------|
| GHAS `app/` (Juice Shop) | 61 MB | **Exclude.** Document in GHAS module setup: "Fork/clone the Juice Shop from the source repo or use the provided Codespace." Add a `setup.md` with exact steps. |
| Agentic-DevOps `Resources/` | 212 KB | **Include.** Small enough to vendor. Copy into `modules/agentic-devops/resources/`. |
| GHEC seed scripts | Tiny | **Include.** Already self-contained. |
| GHAW examples | Tiny | **Include.** Copy into module. |

**Why:** A 61MB app directory bloats the repo, slows clones, and the Juice Shop source is upstream-maintained anyway. Students need a running instance, not the source in this repo. The module's setup challenge documents how to get it.

---

## G. Licensing & Attribution

All four source repos are **MIT License, Copyright (c) Microsoft Corporation.**

### Implementation:
1. Root `LICENSE` file: MIT, covering all original content in this repo.
2. Each challenge's `meta.yml` carries `source_repo` and `source_path` — machine-readable provenance.
3. The site footer includes: "Content sourced from four Microsoft hackathon repositories under MIT license."

---

## H. Proposed Repo Directory Layout

```
frontier-ghplatform-hackathon/
├── docs/                           # GitHub Pages root (served as-is)
│   ├── index.html                  # Landing page
│   ├── catalog.html                # Full challenge catalog
│   ├── module.html                 # Module detail (query-param driven)
│   ├── challenge.html              # Challenge detail (query-param driven)
│   ├── build.js                    # THE build script (single source of truth bridge)
│   ├── .nojekyll
│   └── assets/
│       ├── css/styles.css
│       ├── js/{core,catalog,challenge,home,module}.js
│       ├── img/                    # Module icons, hero images
│       └── data/                   # Generated by build.js
│           ├── platform.json       # Full catalog data
│           └── challenges/         # Copied student/coach guides per challenge
│               ├── ghec-ch01/
│               │   ├── README.md
│               │   └── COACH.md
│               ├── ghas-00/
│               │   ├── README.md
│               │   └── COACH.md
│               └── ...
├── modules/                        # Source content (input to build.js)
│   ├── ghec/
│   │   └── challenges/
│   │       ├── ch01-issues-labels-projects/
│   │       │   ├── meta.yml
│   │       │   ├── README.md       # Student guide
│   │       │   └── COACH.md        # Coach guide
│   │       └── ...
│   ├── ghas/
│   │   ├── setup.md                # How to get Juice Shop running
│   │   └── challenges/
│   │       ├── 00-explore-attack-surface/
│   │       │   ├── meta.yml
│   │       │   ├── README.md
│   │       │   └── COACH.md
│   │       └── ...
│   ├── ghaw/
│   │   └── challenges/
│   │       ├── 00-setup/
│   │       │   ├── meta.yml
│   │       │   ├── README.md
│   │       │   └── COACH.md
│   │       └── ...
│   └── agentic-devops/
│       ├── resources/              # Vendored (small, 212KB)
│       └── challenges/
│           ├── 00-setup/
│           │   ├── meta.yml
│           │   ├── README.md
│           │   └── COACH.md
│           └── ...
├── scripts/                        # Utility scripts (validation, etc.)
├── .github/
│   └── workflows/
│       └── build-deploy.yml        # Runs build.js, deploys Pages
├── LICENSE
├── README.md
├── CONTRIBUTING.md
└── .squad/                         # Squad scaffolding (existing)
```

---

## I. Phased Build Plan

### Phase 1: Engine & Scaffold (Days 1–2) — PARALLEL START
| Owner | Task |
|-------|------|
| **Wash** | Extend `build.js` for multi-module support; set up GitHub Actions `build-deploy.yml`; validate build produces correct `platform.json` |
| **Kaylee** | Design multi-module landing page + catalog UI; extend CSS for module color coding; create `module.html` template |
| **Mal** | Write `CONTRIBUTING.md` with meta.yml contract; create `_TEMPLATE/` challenge skeleton; review Wash's build.js changes |

### Phase 2: Content Port (Days 2–4) — PARALLEL
| Owner | Task |
|-------|------|
| **Zoe** | Port all 66 challenges: create `meta.yml` for each, copy/adapt student+coach guides into canonical `README.md`/`COACH.md` format. Priority order: GHEC (already has meta.yml — fast copy), Agentic-DevOps (7, small), GHAS (15, needs restructure from flat files), GHAW (24, needs extract from Jekyll front-matter) |
| **Kaylee** | Build challenge detail page with Markdown rendering; implement module page; responsive polish |
| **Wash** | Add CI validation (prereq graph check, meta.yml schema lint); set up PR preview deploys |

### Phase 3: Polish & QA (Days 4–5)
| Owner | Task |
|-------|------|
| **Simon** | Independence audit: pick 10 random challenges, verify each is runnable from cold start with only stated prereqs. File issues for failures. Test all filters/nav paths on the site. Cross-browser check. |
| **Kaylee** | Fix UI issues from Simon's audit; add search/filter polish; dark/light theme |
| **Zoe** | Fix content issues from Simon's audit; ensure coach guides exist for all challenges |
| **Wash** | Performance check; ensure Pages deploy is clean; add build caching |

### Phase 4: Ship (Day 5)
| Owner | Task |
|-------|------|
| **Mal** | Final review gate; merge to main; verify live site |
| **All** | Celebrate 🎉 |

### Parallelism Notes
- Phase 1 Wash + Kaylee run fully in parallel (build vs. UI are independent).
- Phase 2 Zoe's content port is independent of Kaylee's UI work — they converge at build time.
- Simon cannot start QA until Phase 2 delivers at least one complete module.

---

## Key Trade-offs Acknowledged

1. **Client-side Markdown rendering** adds ~40KB (marked.js) but avoids a build-time HTML generation step that would complicate the self-contained model. Acceptable.
2. **No Juice Shop in-repo** means GHAS module students need an extra setup step. Documented clearly; far better than a 61MB repo.
3. **No Jekyll** means we lose GitHub's built-in build — but we gain speed, zero dependencies, and full control. The Actions workflow is a 3-line script.
4. **Keeping overlapping content** (GHEC security vs. GHAS) means ~5 challenges cover similar ground from different angles. This is a feature, not a bug — different audiences, different depth.

---

## Decision Record

**Decision:** Adopt the extended GHEC `meta.yml → build.js → docs/` engine as the unified site platform. Keep all four modules intact without deduplication. Exclude heavy assets (Juice Shop) by reference. Use the schema defined in Section B as the single source of truth contract.

**Decided by:** Mal  
**Date:** 2026-06-15  
**Reversibility:** Medium — the meta.yml contract is the hardest thing to change once content is ported. Engine and UI are easily swappable since they consume the JSON output.
