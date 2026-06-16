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
