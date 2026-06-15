# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Architecture, IA, schema, decisions | Mal | Module/challenge schema, site-engine choice, dedupe strategy, challenge-independence model |
| Site UI / Pages frontend | Kaylee | Landing, module cards, catalog, filters, per-challenge pages, search, styling |
| Challenge content / curriculum | Zoe | Port & harmonize challenges, prereqs, success criteria, attribution |
| Build & deploy / Actions | Wash | Build script, Pages deploy workflow, validation CI, scaffolding |
| Testing / QA | Simon | Strict build, link checks, independence verification, prereq sanity |
| Code review | Mal (primary), Simon (content/site quality) | Review work, check quality, enforce reviewer gate |
| Scope & priorities | Mal | What to build next, trade-offs, decisions |
| Session logging | Scribe | Automatic — never needs routing |
| Work queue / backlog | Ralph | Monitor issues/PRs, keep the pipeline moving |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Mal (Lead) |
| `squad:{name}` | Pick up issue and complete the work | Named member |

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn for trivia.
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** Spawn Simon to draft checks from acceptance criteria while others build.
7. **Reviewer gate:** Mal and Simon may reject; on rejection a *different* agent revises.
