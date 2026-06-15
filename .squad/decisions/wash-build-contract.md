# Build Contract: platform.json Shape & Build Pipeline

**Author:** Wash (DevOps / Build Engineer)  
**Date:** 2026-06-15  
**Status:** Implemented — verified with `node docs/build.js`

---

## Summary

`docs/build.js` is the sole bridge between `modules/<moduleId>/challenges/<slug>/meta.yml` (source of truth) and the rendered site. It emits two JSON files consumed by Kaylee's frontend.

---

## Output Files

### `docs/assets/data/platform.json`

Full catalog data. **This is the contract Kaylee renders against.**

```json
{
  "generated_at": "2026-06-15T14:00:00.000Z",
  "modules": [
    {
      "id": "ghec",
      "name": "GitHub Enterprise Cloud",
      "description": "...",
      "color": "#0969da",
      "icon": "cloud",
      "challenge_count": 20,
      "tracks": [
        {
          "id": "developer-flow",
          "name": "Developer Flow",
          "description": "...",
          "challenge_count": 5
        }
      ]
    }
  ],
  "challenges": [
    {
      "id": "ghec-ch01",
      "title": "Issues, Labels & Project Boards",
      "module": "ghec",
      "track": "developer-flow",
      "difficulty": "beginner",
      "duration_minutes": 180,
      "description": "...",
      "prerequisites": [],
      "prerequisite_capabilities": ["GitHub account with org access"],
      "success_criteria": ["Custom label taxonomy applied"],
      "tags": ["issues", "labels", "projects"],
      "app_dependency": "seed",
      "emu_compatible": true,
      "tier": "core",
      "references": ["https://docs.github.com/..."],
      "source_repo": "microsoft/frontier-ghec-hackathon",
      "source_path": "challenges/ch01-issues-labels-projects/meta.yml",
      "license": "MIT",
      "student_path": "assets/data/challenges/ghec-ch01/README.md",
      "coach_path": "assets/data/challenges/ghec-ch01/COACH.md"
    }
  ]
}
```

### `docs/assets/data/dependency-graph.json`

Prereq graph for optional visual rendering.

```json
{
  "nodes": [{ "id": "ghec-ch01", "title": "...", "module": "ghec", "track": "developer-flow", "tier": "core" }],
  "edges": [{ "from": "ghec-ch00", "to": "ghec-ch01" }]
}
```

### `docs/assets/data/challenges/<id>/README.md` + `COACH.md`

Copied verbatim from `modules/<moduleId>/challenges/<slug>/`. Pages serves them at the paths listed in `student_path` / `coach_path` above.

---

## Module Accent Colors

| Module | Color | Rationale |
|---|---|---|
| `ghec` | `#0969da` | GitHub blue |
| `ghas` | `#cf222e` | GitHub danger red |
| `ghaw` | `#8250df` | GitHub AI purple |
| `agentic-devops` | `#1a7f37` | GitHub success green |

---

## Validation Rules (CI exits non-zero)

- Every `prerequisites[]` item must reference a real `id` in the catalog.
- No circular dependencies (DFS cycle detection).
- Warnings (non-fatal): missing `description`, missing `README.md`/`COACH.md`, unknown track slug.

---

## Field Normalisation (legacy GHEC compat)

| Old field | New field | Rule |
|---|---|---|
| `requires: [org]` | `min_environment: org` | Items without `-` → env type |
| `requires: [ghec-ch00]` | `prerequisites: [ghec-ch00]` | Items containing `-` → challenge prereq |
| `duration_hours: 3` | `duration_minutes: 180` | × 60 |
| `difficulty: foundational` | `difficulty: beginner` | Renamed |
| `app: seed` | `app_dependency: seed` | Renamed |
| `id: ch01` (no module prefix) | `id: ghec-ch01` | Prefixed with `moduleId` |

---

## Commands

```bash
node docs/build.js          # build + validate (exit 0 = OK, exit 1 = errors)
npm run build               # alias (package.json scripts)
```

**Verified on 2026-06-15:** Exit 0 with 2 GHEC challenges as test fixtures.
