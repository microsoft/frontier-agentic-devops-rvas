# Zoe — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — "The Frontier GitHub Platform Hackathon"
- **Goal:** One repo + one beautiful GitHub Pages site aggregating four hackathons as independent modules: GitHub Enterprise Cloud (frontier-ghec), GitHub Advanced Security (frontier-ghas), GitHub Agentic Workflows (frontier-ghaw), Agentic DevOps & Azure SRE (frontier-agentic-devops). GitHub Actions threads through all four. The ghcp/Copilot hackathon is intentionally excluded.
- **Key constraint:** Each challenge must be independently runnable (explicit prereqs, no hidden cross-dependencies). Students may do the full journey or cherry-pick.
- **Tech:** Static GitHub Pages site (lean toward GHEC dependency-free meta.yml -> build.js -> docs/ model, pending Phase 0 decision).
- **Requested by:** Marco (@olivomarco)
- **Created:** 2026-06-15
- **Universe:** Firefly (resonance: frontier, crew, independence)

## Learnings

### 2026-06-15 — Phase 1 Content Port: GHEC + GHAS

#### Track mapping (GHEC)
- ch01–ch05 → `developer-flow`
- ch06–ch10 → `admin-governance`
- ch11–ch15 → `security`
- ch16–ch20 → `automation-ai`

#### Difficulty mapping (GHEC)
Source uses `foundational` / `intermediate` / `advanced`. Mapped `foundational` → `beginner` to align with our schema.

#### GHEC prerequisites decision
All GHEC challenges have `prerequisites: []`. The source `requires:` field lists infrastructure (org, ghas, copilot) — not prior challenge dependencies. These map to `prerequisite_capabilities` as human-readable strings, not challenge IDs.

#### GHAS security-only scoping
Marco scoped GHAS to **S-series only** (6 challenges). B-series (backend), F-series (frontend), and C00 (Copilot setup) are explicitly excluded. The `ATTRIBUTION.md` documents this scope note.

#### GHAS restructure decisions
- Source is flat (no per-challenge meta.yml, no coach guides). Created meta.yml from scratch using challenge content.
- GHAS S00 has `prerequisites: []` (entry point). S01–S05 each list `ghas-s00` as a prerequisite since the attack-surface overview is the natural starting context, but all can technically run independently with the same Juice Shop setup.
- All GHAS challenges have `app_dependency: juice-shop`. Juice Shop is NOT vendored (61MB); students use Codespaces or Docker. `modules/ghas/setup.md` documents setup options.
- No source coach guides existed. Wrote structured stubs with objectives, blocker guidance, and validation checklists derived from challenge content.

#### emu_compatible flags
- `ghec-ch14` (SSO/SAML/SCIM): `false` — SAML/SCIM not applicable to EMU orgs (which ARE the IdP-managed identity)
- `ghec-ch19` (Copilot Cloud Agent): `false` — Copilot cloud agent not available on EMU repos
- All others: `true`

#### Overlap flagged for Mal
- `ghec-ch11–ch15` (security track) and `ghas-s00–s05` cover overlapping territory (CodeQL, Dependabot, secret scanning, security campaigns). Per Mal's architecture decision E, these are intentionally kept — GHEC security challenges are enterprise governance-framed, GHAS challenges are developer code-fix focused using Juice Shop. Different audience/depth. No deduplication needed.
- `ghec-ch15` (Security Campaigns & Overview) and `ghas-s05` (Security Campaigns Advanced) both cover security campaigns. GHEC version is an overview/configuration challenge; GHAS version is hands-on campaign creation for a real alert corpus. Cross-link tags added.

### 2026-06-15 — Phase 2 Content Port: GHAW + Agentic-DevOps

#### Track mapping (GHAW)
- `00-setup` → `hello-agent` (`tier: setup`)
- `1-01`–`1-04` → `hello-agent`
- `2-01`–`2-06` → `repo-concierge`
- `3-01`–`3-06` → `continuous-intelligence`
- `4-01`–`4-08` → `production-patterns`

#### GHAW prerequisites decision
- All non-setup GHAW challenges list `ghaw-0-00` as the only default prerequisite.
- `ghaw-4-06` additionally lists `ghaw-4-05` because it consumes the Daily Testify output chain.
- `prerequisite_capabilities` stay constant across non-setup GHAW challenges: GitHub Actions basics, YAML syntax, and `gh-aw` installed.

#### Agentic-devops chain decisions
- Linear prerequisite chain: `00 → 01,02`; `01 + 02 → 03`; `03 → 04,05`; `04 + 05 → 06`.
- Challenge 05 keeps an explicit dependency on 03 rather than 04 because workflow-safety work depends on agent-workflow concepts more than Azure deployment completion.
- Challenge 06 accumulates both deployment and agent-workflow dependencies because the incident loop needs runtime evidence and agent review discipline.

#### Vendored resources note
- Copied `frontier-agentic-devops-hackathon/Resources/` into `modules/agentic-devops/resources/` as a vendored curriculum dependency for the Contoso Claims scenario.
- Preserved resource-relative links in student guides by remapping `../Resources/...` to `../../resources/...`.

### 2026-06-15 — Phase 3 QA Fixes (Simon QA Report)

#### D-001 — YAML list indentation (P0 ship blocker)
- All list fields in `modules/ghas/challenges/s00–s05/meta.yml` (prerequisites, prerequisite_capabilities, success_criteria, tags, provision_creates, references) re-indented to 2-space block sequences to match GHAW/GHEC/agentic-devops convention and satisfy the `parseMeta()` `\s+` regex in build.js.
- After fix: dependency-graph.json edges 33 → 38 (5 GHAS prerequisite edges restored). Build exits 0.

#### D-003 — Dead links in ghas-s00 README (P1)
- Removed two `../docs/prerequisites.html#...` links (source-repo paths not present in this repo). Replaced the callout block with an inline reference to `../../setup.md` (i.e. `modules/ghas/setup.md`), which documents all three Juice Shop provisioning paths (Codespaces, local Docker, organizer-hosted).

#### D-004 — Broken relative links in agentic-devops resources (P2)
- `resources/README.md` Navigation: `../Student/Challenge-00-Setup.md` → `../challenges/00-setup/README.md`; `../Coach/Coach-Guide.md` → `../COACH.md`; link text updated ("hackathon front door" → "module front door").
- `resources/Pages-Publishing.md` Recommended Pages Entry Points: same Student/Coach path corrections.
- `resources/Agentic-SDLC-Practices.md` Related Assets: `../Student/Challenge-03-Agent-Workflows.md` → `../challenges/03-agent-workflows/README.md`.

#### D-005 — ghas-s00 tier: core → tier: setup (P2)
- Changed `tier: core` to `tier: setup` in `modules/ghas/challenges/s00-explore-attack-surface/meta.yml`. GHAS now has a formal module entry-point consistent with GHAW (`ghaw-0-00`) and agentic-devops (`agentic-devops-00`).

#### Lesson learned
- When porting YAML from a flat source with zero-indent block sequences, always normalize to the repo's 2-space indent standard immediately — parser regex assumptions will silently drop un-indented list items and corrupt the dependency graph. Confirm edge counts in dependency-graph.json after every port, not just schema validity.
