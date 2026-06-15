# Contributing — Challenge Authoring Guide

This guide explains how to add or update challenges in this repository. The `meta.yml` file is the **single source of truth** for every challenge — the build script reads it exclusively.

---

## Directory Layout

Every challenge lives at:

```
modules/<moduleId>/challenges/<slug>/
  meta.yml     ← required: full field contract below
  README.md    ← required: student guide (Markdown)
  COACH.md     ← required: coach/facilitator guide (Markdown)
```

Copy `modules/_TEMPLATE/challenge/` as your starting point.

---

## `meta.yml` Field Contract

```yaml
# === Required ===
id: ghec-ch01                    # Globally unique. Convention: <module>-<local-id>
                                 # Modules: ghec | ghas | ghaw | sre-agent
title: "Issues, Labels & Project Boards"
module: ghec                     # One of: ghec | ghas | ghaw | sre-agent
track: developer-flow            # Track slug within the module (see module-track table below)
difficulty: beginner             # beginner | intermediate | advanced
duration_minutes: 180            # Estimated student time in minutes

# === Independence fields (critical for catalog filtering) ===
prerequisites:                   # Explicit challenge IDs this challenge depends on.
  - ghec-ch00                    # Empty list = no prerequisites (most challenges).
prerequisite_capabilities:       # What a student must KNOW (skills), not what they must DO.
  - "GitHub account with org access"
  - "Basic Git knowledge"

# === Descriptive ===
description: "One-sentence description shown in the catalog card."
success_criteria:
  - "Custom label taxonomy applied"
  - "All issues triaged to project board columns"
tags:
  - issues
  - labels
  - projects

# === Operational ===
app_dependency: seed             # none | juice-shop | contoso-claims | seed-repo
emu_compatible: true             # Can this run in an EMU-controlled org? true | false
min_environment: org             # org | repo | codespace
provision_creates:               # Resources the setup script creates (human-readable).
  - "repo wth-ch01-issues-labels-projects (seeded)"

# === Attribution ===
source_repo: microsoft/frontier-ghec-hackathon
source_path: challenges/ch01-issues-labels-projects/meta.yml
license: MIT

# === Optional ===
tier: core                       # core | stretch | bonus | setup
references:
  - https://docs.github.com/en/issues/tracking-your-work-with-issues/about-issues
```

---

## Module → Track Table

| Module | Track slug | Track name |
|---|---|---|
| `ghec` | `developer-flow` | Developer Flow |
| `ghec` | `admin-governance` | Admin & Governance |
| `ghec` | `security` | Security |
| `ghec` | `automation-ai` | Automation & AI |
| `ghas` | `security-fundamentals` | Security Fundamentals |
| `ghaw` | `hello-agent` | Hello Agent |
| `ghaw` | `mcp-integration` | MCP Integration |
| `ghaw` | `production-patterns` | Production Patterns |
| `ghaw` | `safe-outputs` | Safe Outputs |
| `sre-agent` | `agentic-lifecycle` | Agentic Lifecycle |

---

## Field Rules

### `id`
- Must be **globally unique** across all modules.
- Convention: `<module>-<local-id>` — e.g., `ghec-ch01`, `ghas-s00`, `ghaw-1-01`, `sre-agent-00`.
- Once published, treat as **immutable** (it is used as a foreign key in `prerequisites` lists).

### `prerequisites`
- List challenge IDs that must be completed before this challenge.
- An empty list (`prerequisites: []`) or omitting the field means no prerequisites.
- The build validates every listed ID against the full catalog — a reference to a non-existent ID fails CI.
- Tip: most challenges should have empty prerequisites to maximize cherry-picking.

### `prerequisite_capabilities`
- Human-readable skills list. Students use this to self-assess without having done prior challenges.
- Examples: `"GitHub Actions basics"`, `"YAML syntax"`, `"Python scripting"`.

### `difficulty`
- `beginner` — accessible to GitHub newcomers.
- `intermediate` — requires some GitHub platform experience.
- `advanced` — deep technical, requires prior module experience or strong background.

### `app_dependency`
- `none` — uses standard GitHub features only.
- `seed` — requires a seeded repo created by the provision script.
- `juice-shop` — requires the OWASP Juice Shop app (see `modules/ghas/setup.md`).
- `contoso-claims` — requires the Contoso Claims sample app.

### `tier`
- `core` — must-do, included in the "standard" path.
- `stretch` — extra depth for advanced students.
- `bonus` — optional enrichment.
- `setup` — environment setup (per-module, not a learning challenge).

---

## Student Guide (`README.md`)

Use the template at `modules/_TEMPLATE/challenge/README.md`. Include:
- **Goal** — one sentence.
- **Prerequisites** — matches `meta.yml` (both challenge IDs and capability strings).
- **Step-by-step instructions** — numbered.
- **Success criteria** — matches `meta.yml` success_criteria.

## Coach Guide (`COACH.md`)

Use the template at `modules/_TEMPLATE/challenge/COACH.md`. Include:
- **Expected outputs** — what a correct solution looks like.
- **Common pitfalls** — what goes wrong and how to unblock students.
- **Hints** — progressive hints without giving away the solution.
- **Timing** — how to pace the challenge in a workshop.

---

## Build & Validate

After editing content, run:

```bash
node docs/build.js
```

The build exits non-zero if validation fails (invalid prerequisite reference, etc.). Fix all errors before opening a PR.

## Attribution

When porting a challenge from a source repo:
- Set `source_repo` and `source_path` in `meta.yml`.
- Ensure your module's `ATTRIBUTION.md` credits the source repository.
- Keep `license: MIT` for all Microsoft-sourced content.
