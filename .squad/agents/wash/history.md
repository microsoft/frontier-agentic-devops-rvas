# Wash — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)

## Learnings

### Phase 1 — Build & Scaffold (2026-06-15)

**Verified build command:**
```
node docs/build.js
```
Runs in <1s with Node core only. Zero npm dependencies.

**Output contract (platform.json shape):**
```json
{
  "generated_at": "<ISO8601>",
  "modules": [
    { "id": "ghec", "name": "GitHub Enterprise Cloud", "description": "...",
      "color": "#0969da", "icon": "cloud", "challenge_count": 20,
      "tracks": [ { "id": "developer-flow", "name": "Developer Flow", "description": "...", "challenge_count": 5 } ] }
  ],
  "challenges": [
    { "id": "ghec-ch01", "title": "...", "module": "ghec", "track": "developer-flow",
      "difficulty": "beginner", "duration_minutes": 180, "description": "...",
      "prerequisites": [], "prerequisite_capabilities": ["..."],
      "success_criteria": ["..."], "tags": ["..."], "app_dependency": "seed",
      "emu_compatible": true, "tier": "core", "references": ["..."],
      "source_repo": "...", "source_path": "...", "license": "MIT",
      "student_path": "assets/data/challenges/ghec-ch01/README.md",
      "coach_path": "assets/data/challenges/ghec-ch01/COACH.md" }
  ]
}
```

**Key build decisions:**

1. **Meta field normalisation**: Old GHEC meta.yml uses `requires: [org]` (env type) + `duration_hours`. Build.js maps these to the new contract: only `requires` items containing `-` are treated as challenge ID prerequisites; `org/repo/codespace` items migrate to `min_environment`. `duration_hours * 60 = duration_minutes`.

2. **Validation gates**: Build exits non-zero if any `prerequisites` entry references an unknown challenge ID or if cycles are detected. Warnings (missing fields, missing guides) are non-fatal. This means Zoe's content port will progressively unlock validation as challenges are added.

3. **Dependency graph**: `docs/assets/data/dependency-graph.json` emitted as `{ nodes, edges }` — Kaylee can render it as a visual prereq map.

4. **Module config is code**: All module/track names, colors, and icons live in a `MODULE_CONFIG` object near the top of `docs/build.js`. Kaylee can tweak accent colors there without touching any content.

5. **Module accent colors**:
   - `ghec`: `#0969da` (GitHub blue)
   - `ghas`: `#cf222e` (GitHub red / danger)
   - `ghaw`: `#8250df` (GitHub purple / AI)
   - `agentic-devops`: `#1a7f37` (GitHub green)

6. **Build test**: Temporarily copied `ch01-issues-labels-projects` + `ch02-pull-requests-code-review` from `frontier-ghec-hackathon` into `modules/ghec/challenges/`. Build ran cleanly (exit 0) with 2 warnings (expected: old meta.yml lacks `description` field). Fixtures removed after verification.

7. **Workflows**: Two GitHub Actions workflows:
   - `.github/workflows/build-deploy.yml` — pushes to `main` + `workflow_dispatch`: build + deploy to Pages via `actions/upload-pages-artifact@v3` + `actions/deploy-pages@v4`
   - `.github/workflows/validate.yml` — PRs: build only, no deploy. Non-zero exit fails the check.

**Files owned by Wash (Phase 1):**
- `README.md`, `LICENSE`, `.gitignore`, `CONTRIBUTING.md`
- `modules/README.md`, `modules/_TEMPLATE/challenge/{meta.yml,README.md,COACH.md}`
- `modules/{ghec,ghas,ghaw,agentic-devops}/ATTRIBUTION.md`
- `modules/ghas/setup.md`
- `docs/build.js`, `docs/.nojekyll`
- `.github/workflows/build-deploy.yml`, `.github/workflows/validate.yml`
- `package.json` (scripts only, no deps)

8. **Canonical track slugs (2026-06-15)**: ghas renamed `security-fundamentals` → `security` (Zoe's 6 challenges use this); ghaw replaced with faithful Track 1–4 taxonomy: `hello-agent`, `repo-concierge`, `continuous-intelligence`, `production-patterns` (internal track_ids were scrambled, so config now matches actual content hierarchy).

9. **P0 bugfix D-001 (2026-06-15)**: Fixed YAML list-item parser in `docs/build.js` line 93 — changed regex from `^\s+-\s+` to `^\s*-\s+` to accept unindented list items (e.g., `- ghas-s00` without leading spaces); restored 5 missing dependency edges (ghas-s01..s05 now correctly recognize ghas-s00 prerequisite).