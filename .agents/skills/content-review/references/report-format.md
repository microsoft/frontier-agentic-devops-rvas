# Review Report Format

Produce a concise report at the end of every review. The goal is traceability: an author should see exactly what changed, why, and what still needs their judgment — with no silent edits.

## Structure

```markdown
## Content Review — <scope>

**Baseline:** `npm run audit:content` → <exit 0 | N errors, M warnings>

### Fixed (N)
| File | Issue | Lens | Fix | Source |
|---|---|---|---|---|
| modules/ghas/.../README.md | `actions/checkout@v3` outdated | up-to-dateness | bumped to current major | docs.github.com/en/actions/... |
| modules/ghas/.../meta.yml | success criterion unreachable from steps | pacing | reworded to match step 4 | — (internal consistency) |

### Needs author judgment (M)
| File | Issue | Lens | Recommendation |
|---|---|---|---|
| .../meta.yml | 90 min feels long for beginner + 4 steps | pacing | consider 60 min or add depth |

### Unverified (K)
| File | Claim | Why unverified |
|---|---|---|
| .../README.md | "Copilot auto-labels the PR" | no authoritative source confirms exact behavior |

### Re-verification
`npm run audit:content` after edits → <exit 0 | details>
```

## Rules

- **Every Fixed row that changed a fact cites a source.** Consistency-only fixes (cross-file alignment) may cite "internal consistency."
- **Never put a guess in Fixed.** If you couldn't verify it, it goes in Unverified.
- **Pacing/judgment changes go in Needs author judgment**, not Fixed, unless the user explicitly asked you to rebalance timings.
- Keep the report short — tables over prose. Omit empty sections.
