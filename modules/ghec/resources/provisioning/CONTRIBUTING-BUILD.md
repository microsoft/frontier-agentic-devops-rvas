# CONTRIBUTING — Build Guide (Linus · Yen · Basher)

This is the **foundation contract**. It tells each builder exactly where content goes and how the
pieces fit. Rusty (Lead/Architect) owns this structure; propose changes via a decision in
`.squad/decisions/inbox/` before deviating.

## The one canonical structure

```
challenges/
  _TEMPLATE/                          ← DO NOT delete; copy, never edit in place
    README.md   (student guide)
    COACH.md    (coach guide)
    meta.yml    (machine-readable contract)
  ch##-<slug>/                        ← one per challenge, numbers ch01..ch20
    README.md   ← copied from _TEMPLATE, all sections filled
    COACH.md    ← copied from _TEMPLATE, all sections filled
    meta.yml    ← copied from _TEMPLATE, all fields filled
    provision.sh (optional, Yen)      ← per-challenge provisioning logic, if not centralised
scripts/                              ← shared CLI engine (Yen)
docs/                                 ← GitHub Pages site source (Basher)
```

### Folder + file naming (HARD RULES)
- Challenge folder = `ch##-<slug>` where `##` is zero-padded (`ch01`, …, `ch20`) and `<slug>` is
  **kebab-case**, matching `slug:` in `meta.yml` exactly.
- The canonical slugs are fixed (see table below). **Do not rename** — the site, scripts, and links
  all key off them.
- Inside each folder: `README.md` (student), `COACH.md` (coach), `meta.yml` (data). Exact filenames.
- Any dates written in content use ISO format `YYYY-MM-DD`.

### Canonical challenge slugs (locked)
| id | folder |
|---|---|
| ch01 | `ch01-issues-labels-projects` |
| ch02 | `ch02-pull-requests-code-review` |
| ch03 | `ch03-codespaces-dev-containers` |
| ch04 | `ch04-actions-ci-fundamentals` |
| ch05 | `ch05-advanced-pr-automation` |
| ch06 | `ch06-enterprise-org-101` |
| ch07 | `ch07-teams-roles-permissions` |
| ch08 | `ch08-rulesets-repo-properties` |
| ch09 | `ch09-audit-log-streaming` |
| ch10 | `ch10-billing-cost-centers` |
| ch11 | `ch11-secret-scanning-push-protection` |
| ch12 | `ch12-codeql-code-scanning` |
| ch13 | `ch13-dependabot-dependency-review` |
| ch14 | `ch14-sso-saml-scim` |
| ch15 | `ch15-security-campaigns-overview` |
| ch16 | `ch16-rest-graphql-automation` |
| ch17 | `ch17-webhooks-github-apps` |
| ch18 | `ch18-self-hosted-runners` |
| ch19 | `ch19-copilot-coding-agent` |
| ch20 | `ch20-automation-capstone` |

## `meta.yml` is the contract between everyone

`meta.yml` is the **single machine-readable source of truth**. Both the site and the scripts read it.
Never duplicate this data in prose — render or read it from here.

| Field | Type | Used by | Notes |
|---|---|---|---|
| `id` | `ch01..ch20` | site, scripts | Must match folder number. |
| `slug` | kebab-case | site, scripts | Must match folder slug. |
| `title` | string | site | Matches README H1. |
| `track` | enum | site (grouping/filter) | `developer-flow\|admin-governance\|security\|automation-ai`. |
| `difficulty` | enum | site (badge) | `foundational\|intermediate\|advanced` (per-track ramp). |
| `duration_hours` | int (3–8) | site | Total, multi-session. |
| `min_input` | `org` | scripts (`doctor`) | **Always `org`.** Never stricter. |
| `app` | enum | scripts (setup) | `juice-shop\|seed\|none`. |
| `juice_shop_ref` | `v20.0.0` | scripts | Only when `app: juice-shop`. Pinned for reproducibility. |
| `requires` | list | scripts (`doctor` preflight) | Always includes `org`; add `ghas`/`copilot`. |
| `emu_compatible` | bool | site (badge), scripts (`doctor` warn) | `false` **only** for ch19. |
| `provision_creates` | list | site (Setup summary), scripts | All artifacts `ghec-ch##-*`. |
| `references` | list of URLs | site | Official docs.github.com links. |

## Who owns what

### 📚 Linus — challenge content (student + coach guides)
- For each `ch##-<slug>/`: copy `_TEMPLATE/README.md` → `README.md` and `_TEMPLATE/COACH.md` → `COACH.md`.
- Fill **every** section; keep all headings in the template order (the site + coach filter depend on them).
- Use the **exact titles/tracks** from the table in the root `README.md`.
- Keep `meta.yml` in sync with the guide (title, app, requires, emu_compatible).
- Apply Marco's decisions: org-scoped framing everywhere; GHAS challenges target Juice Shop at `v20.0.0`;
  ch19 carries the EMU prerequisite and is N/A for pure GHEMU.

### ⚙️ Yen — provisioning scripts (`scripts/`)
- Own `scripts/setup.sh` + `scripts/setup.ps1` (and `teardown`, `doctor`, `status`) over one shared gh/jq core.
- Per-challenge logic reads `challenges/ch##-<slug>/meta.yml` for `app`, `requires`, `provision_creates`.
- Command surface: `setup.sh` / `setup.ps1` `<doctor|setup|status|teardown> ch## --org <org> [--dry-run] [--yes]`.
- Namespace **everything** `ghec-ch##-*`; teardown refuses to touch anything without that prefix.
- `doctor` verifies tooling (`gh`/`git`/`jq`), auth, and the `requires` capabilities; warns on EMU for ch19.
- Juice Shop: pull pinned `v20.0.0` release tarball → fresh git init → push to `ghec-ch##-juice-shop`. Never vendor.

### 🌐 Basher — GitHub Pages site (`docs/`)
- Source of truth for cards/filters/badges is each `meta.yml` — read it, don't hand-copy.
- Render student `README.md` per challenge; **exclude `COACH.md`** from the public student view (coach view separate).
- Group by `track`; show `difficulty`, `app`, and `emu_compatible` badges; surface `references`.
- Link the site from the root `README.md` and back.

## Independence guarantee (everyone upholds)
- No challenge depends on another's output. Each `setup` creates all of its own `ghec-ch##-*` state.
- Soft-links are optional only and must be re-created by provisioning, never assumed.

## Changing the contract
The structure, slugs, and `meta.yml` schema are **locked**. To change them, write a decision to
`.squad/decisions/inbox/` and get Rusty's sign-off so the site and scripts stay in lockstep.
