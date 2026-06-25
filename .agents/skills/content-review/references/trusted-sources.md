# Trusted Sources

When a claim can't be verified from the repo itself, check it against these authoritative hosts. Prefer the canonical documentation domain for the product in question. Treat blogs, Stack Overflow, Medium, and forum posts as **leads, not proof** — confirm on an official source before changing content.

## Canonical domains by topic

| Topic | Authoritative sources |
|---|---|
| GitHub product, UI, repos, orgs, Enterprise Cloud | `docs.github.com` |
| GitHub REST/GraphQL API | `docs.github.com/en/rest`, `docs.github.com/en/graphql` |
| GitHub Actions, workflow syntax, runners | `docs.github.com/en/actions` |
| GitHub Advanced Security, code scanning, secret scanning | `docs.github.com/en/code-security` |
| CodeQL queries and CLI | `docs.github.com/en/code-security/codeql-cli`, `codeql.github.com` |
| GitHub Copilot (chat, agents, coding agent, CLI) | `docs.github.com/en/copilot` |
| GitHub CLI (`gh`) | `cli.github.com/manual` |
| OWASP vulnerabilities and prevention | `owasp.org`, `cheatsheetseries.owasp.org` |
| OWASP Juice Shop | `pwning.owasp-juice.shop`, `github.com/juice-shop/juice-shop` |
| Azure services, CLI, SRE | `learn.microsoft.com` |
| Node.js runtime/APIs | `nodejs.org/docs` |

## Verification rules

1. **Match the version/date context.** Docs change; confirm the page reflects current product state, not an archived version.
2. **Prefer reference pages over tutorials** for API fields, flags, and exact labels.
3. **Start from `meta.yml` `references`.** Each challenge already lists source-backed URLs — check those first, and confirm they still resolve and still support the claim.
4. **One authoritative source is enough to fix a factual error**; cite it. If two authoritative sources conflict, flag for author rather than picking one.
5. **If nothing authoritative confirms it, mark it unverified** — do not substitute a different guess.

## Anti-sources

- Marketing/landing pages for exact technical detail (use docs instead).
- AI-generated summaries or cached snippets as the sole basis for a change.
- Old blog posts for current UI labels or version numbers.
