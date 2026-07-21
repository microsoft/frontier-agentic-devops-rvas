# Zoe — History

## Project Context

- **Project:** frontier-ghplatform-hackathon — Unified GitHub platform aggregating 4 hackathons (GHEC, GHAS, GHAW, SRE Agent) as independent modules
- **Goal:** 59 challenges (GHEC 21, GHAS 7, GHAW 25, SRE 6), 38 prerequisite edges, deterministic build, GitHub Pages site
- **Zoe role:** Content/Curriculum Engineer — Phase 2 (GHAW + SRE port), QA fixes, environment setup implementation, governance integration
- **Universe:** Firefly

## Session Summaries

### 2026-06-15 — Phase 1–3: Port GHAW/SRE, Fix QA, Environment Setup Template

**Delivered:** Phase 2 (GHAW 25 + SRE 7 port) with track assignment and linear prerequisites; Phase 3 QA fixes (YAML indentation D-001, link repair D-003/004, tier fix D-005); track rename agentic-arc → agentic-lifecycle; ch02 removal (Copilot engineering); agentic-devops → sre-agent module rename; environment setup template across 4 modules (ch00 new/refresh, GHAS renumber 01–06, doc updates).

**Final state:** 59 challenges, 36 edges, 0 cross-module, 0 cycles. All setup challenges have tier:setup + prereqs:[]. All first-real-challenges inherit no technical blockers.

**Key principles:** Independence guarantee (setup never blocks first-real-challenge technically), overlap by design (GHEC security ≠ GHAS security), vendored resources + attribution, tier semantics (setup/core/stretch).

**Validation:** `npm run build` passed; no cycles; deterministic.

### 2026-06-16 — Fix Internal Resource 404s

**Delivered:** Resolved generated challenge page resource links. Build now copies module bundles to `docs/resources/<moduleId>/` and rewrites relative links (e.g., `../../resources/...`) to site-root-relative paths during guide generation.

**Validation:** Generated-link script confirmed 0 invalid resource links remain.

### 2026-06-19 — Embed Official GitHub Docs + Content QA

**Delivered:** Added contextual official GitHub documentation links throughout GHEC ch05 (11 verified sources: CODEOWNERS, auto-merge, Labeler, Stale, rulesets, org scopes). Scored all 59 challenges against QA rubric; fixed P0/P1/P2 issues (metadata, coach guides, placeholder URLs).

**Key learning:** Embed references where students/coaches need them, not end-of-document. Verify all URLs before adding.

**Validation:** `npm run audit:content` passed (220 files, 59 challenges, 0 errors).

### 2026-06-23 — Embed GHAW Examples + Remove Dead Upstream Repos

**Delivered:** Deleted private upstream repos (retired-private-predecessor, etc.) are no longer referenced. Embedded GHAW starter example (hello-world.md) in-tree at `modules/ghaw/resources/examples/`. All setup docs (GHAW, SRE, GHAS) rewritten to reference THIS consolidated repo only. Removed `gh repo fork` steps; updated success criteria to local/Codespace checks.

**New workspace model:** Participants work in THIS repo (microsoft/frontier-agentic-devops-rvas). Devcontainer installs gh-aw. Starter examples are vendored.

**Validation:** `npm run audit:content` passed (231 files, 59 challenges, 0 errors).

### 2026-07-21 — Enterprise Governance Settings Register

**Delivered:** Implemented customer-owned governance settings register template (GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md, 14K). Initialized in Ch06; added focused governance rows to 11 GHEC activities (Ch03, Ch04, Ch06–09, Ch11–15, Ch18, Ch27). Each row: domain, setting, level, value, rationale, implementation path (approved pilot | inspect-and-propose), evidence, owner, review cadence, exceptions, next decision.

**Template design:** 25-row matrix covering org-membership, security, policy, teams, repos, workflow, identity, audit, development. Fields for evidence (API snapshots, docs, test runs), status, accountability. Integration checklist showing where each activity contributes rows.

**Customer model:** Register lives in customer repos (not samples), ensuring governance becomes a customer artifact. Links point to customer evidence. Cumulative design: activities add rows; register becomes master inventory of all governance decisions.

**Changes:** New file (template); Ch06 foundational section + success_criteria refresh; 10 contributing activities integrated with governance rows. Terminology: "challenges" → "activities" (3 places).

**Validation:** `npm run build` passed (4 modules, 59 challenges, 27 edges); `npm run audit:terminology` passed (0 new errors); no broken links.

**Key principles:** Customer ownership (register survives engagement), auditability (evidence links, not screenshots), cumulative (one register per org), honest status (approved pilot vs. needs approval), scope clarity (enterprise/org/repo levels).

## Active Patterns

- **Content strategy:** Contextual links + cumulative artifacts (register, not one-off docs)
- **Student mindset:** Shift from "check the box" to "prove it with evidence"
- **Coach facilitation:** Spot-check evidence links, verify they're real customer artifacts, not samples
- **Customer delivery:** Governance becomes a handover artifact; learners pass it forward with decision rationale and review schedule

## Remaining Coverage Gaps

- Approval/codeowner rules, branch protection beyond rulesets, SAML-driven team sync (enterprise-only), cost optimization dashboards
- Future: Ch17 (webhooks/apps governance) when scope clarified
