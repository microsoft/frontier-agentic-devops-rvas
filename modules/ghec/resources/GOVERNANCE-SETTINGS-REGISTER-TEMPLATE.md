# Customer-Owned GitHub Enterprise Cloud Governance Settings Register

**Purpose:** Track all approved governance settings across the customer delivery engagement. This register is the single source of truth for what is configured, why, who owns it, and what evidence validates it.

**Scope:** Enterprise, organization, and repository settings controlled by the customer delivery team. Each row tracks a single domain/setting pair.

**Usage:** Initialize this register during Ch06 (Enterprise & Organization 101). Add a row for each new setting introduced in subsequent activities. Link to customer-specific evidence (API snapshots, workflow runs, decision memos).

---

## Register Template

| Domain | Setting | Effective Level | Desired Value | Rationale | Implementation Path | Evidence | Accountable Owner | Review Cadence | Exception / Rollback | Next Decision |
|--------|---------|----------------|----|-----------|-------------------|----------|------|------|------|------|
| org-membership | `default_repository_permission` | Org | `read` or `none` | Least-privilege baseline; members get explicit team/role grants, not broad repo access | `approved pilot` (Ch06 Part B) | API snapshot: `/orgs/<org>` `default_repository_permission` field + before/after diff in `docs/POLICY.md` | Org owner | Quarterly or on membership growth | `none` blocks new repos; fallback to `read` if adoption friction detected | Document in `POLICY.md`; if reverting, require explicit risk approval from leadership |
| org-membership | `members_can_create_public_repositories` | Org | `false` | Control surface area; public repos need explicit approval and compliance review | `approved pilot` (Ch06 Part B) | API snapshot + org settings UI confirmation + test case (member cannot create public) | Org owner | Quarterly | If true: unplanned repos leak to public; if false: may block legitimate OSS projects—evaluate with eng lead | Communicate change; allow 2-week notice for existing public-repo workflows |
| org-membership | `members_can_delete_or_transfer_repositories` | Org | `false` | Prevent accidental/malicious data loss; deletions need org owner confirmation | `approved pilot` (Ch06 Part B) | API snapshot + confirmation in Member privileges UI | Org owner | Quarterly | If true: repos deleted by mistake; if false: friction on cleanup—assign owner to manage teardown | Document deletion request process; owners submit tickets |
| org-membership | `members_can_fork_private_repositories` | Org | `false` or `true` (deliberate) | Depends on team workflow; if false, prevents accidental fork-to-public leaks | `approved pilot` (Ch06 Part B) | API snapshot: `members_can_fork_private_repositories` field; test case showing member fork attempt outcome | Org owner | Quarterly | If true: risk of fork-to-public; if false: may block legitimate dev workflows | Document decision in `POLICY.md` with dev feedback loop |
| org-security | `two_factor_requirement_enabled` | Org | `true` (if not EMU) | Blocks basic auth attacks; rollout needs credential reset communication | `inspect-and-propose` (Ch06 Part D awareness) | API snapshot + org settings UI; member 2FA status report (if available) | Org owner + CISO | Before enforcement | If true: members without 2FA removed; if false: account takeover risk | Policy decision + rollout plan + exception list |
| org-security | Actions `permissions` (workflow default) | Org | `read` | No workflow can write tokens to repos by default; maintainers opt-in per workflow | `approved pilot` (Ch06 Part D) | Org Settings → Actions → Workflow permissions screenshot; test PR showing read-only token | Org owner | Quarterly | If `write`: workflows can push code; if `read`: zero-trust isolation | Audit logs of any exceptions |
| org-security | Dependency graph defaults (new repos) | Org | Enabled | Enables automated Dependabot + supply-chain visibility for all new repos | `approved pilot` (Ch06 Part D) | Code security settings screenshot showing toggle state | Org owner | Quarterly | If disabled: new repos get no automated security scanning | Audit: check new repo settings via API |
| org-policy | Visibility policy (public vs internal vs private) | Org | Approved list (e.g., internal for dev, private for commercial) | Controls blast radius and who can discover repos | `inspect-and-propose` (Ch06 Part C awareness) | API snapshot of sample repos' visibility settings; change log (e.g., public → internal transition) | Org owner | Quarterly | Internal leaks to enterprise; private leaks if shared in mistake | Document exceptions; require approval |
| org-teams | Base team structure (parent/child hierarchy) | Org | Documented hierarchy (e.g., `engineering` → `frontend`, `backend`) | Scalable access control; inherited permissions reduce per-repo admin work | `approved pilot` (Ch07 Part A–B) | API dump: `/orgs/<org>/teams?nested=true` showing parent.name, child teams, repo access; `docs/ACCESS.md` access matrix | Org owner / Platform team | Quarterly or on team changes | Flat teams become chaotic as org grows; deep nesting confuses inheritance | Document team charter; require approval for restructure |
| repo-policy | Custom repository roles | Org | Define roles (e.g., `security-maintainer`, `docs-only`) for specialized access | Fine-grained access without creating dozens of teams | `approved pilot` (Ch07 Part D) | API response: `/orgs/<org>/custom-repository-roles` + assignment to teams on specific repos | Platform team | Quarterly | If unused: overhead; if overused: governance debt | Review role catalog with org owner annually |
| repo-governance | Rulesets (org-level, property-targeted) | Org | Approved rulesets (e.g., require PR, require status check, require commit signatures) | Scalable policy: rules apply to repos matching metadata, not naming patterns | `approved pilot` (Ch08 Part B–C) | API dump: `/orgs/<org>/rulesets` + targets (property conditions); GitHub Actions workflow runs showing rule enforcement (pass/fail); bypass logs | Governance owner | Monthly | If too strict: workflow friction; if too loose: misses violations | Audit logs; disable only on documented exception |
| repo-governance | Custom repository properties | Org | Defined schema (e.g., `compliance: high/medium/low`, `team: frontend/backend`, `archived-migration: pending/done`) | Metadata-driven governance; enables rulesets and reporting at scale | `approved pilot` (Ch08 Part A) | API dump: `/orgs/<org>/properties/values` + property values set on repos; schema document in `docs/PROPERTY-SCHEMA.md` | Governance owner | Quarterly | If schema drifts: hard to govern; if too rigid: inflexible | Annual schema review; deprecate unused properties |
| workflow | Actions cache retention | Org/Repo | Clear policy (e.g., delete after 7 days of no use) | Prevents storage bloat; preserves cache hits for active workflows | `inspect-and-propose` (Ch04 Part C awareness) | Test workflow showing cache hit/miss; storage report | Repo owner | Monthly | High cache improves workflow speed; aggressive purge wastes rebuilds | Document per-repo decision |
| workflow | Self-hosted runner policy | Org/Repo | Approved runner labels, OS, compute tier, and rotation schedule | Runners are powerful; unauthorized runners leak internal networks | `inspect-and-propose` (Ch18 Part A–B awareness) | API dump: `/orgs/<org>/actions/runners` + runner labels + workflow assignments; security audit trail | Platform/Ops owner | Monthly | Rogue runner could steal secrets; missing runners block workflows | Quarterly runner audit; require approval for new runners |
| identity | SSO / SAML enforcement | Enterprise (above org) | Linked SAML IdP with attribute mappings (SCIM for automatic provisioning) | Ensures org membership matches corporate identity; outsourcer/contractor access controlled | `inspect-and-propose` (Ch14 Part A awareness; enterprise-only feature) | SAML config export (non-secret); IdP attribute report showing team mapping; audit log of provisioned/deprovisioned users | CISO + Identity team | Monthly | If misconfigured: locked-out users; if not enforced: external access uncontrolled | SAML connectivity test; document IdP owners |
| audit | Audit log retention & streaming | Org/Enterprise | Approved retention (e.g., 90 days min) and streaming (e.g., to Splunk, Azure Monitor) | Compliance / forensics: enable breach investigation and threat hunting | `inspect-and-propose` (Ch09 Part A–B; streaming is org-scoped) | Audit log export snapshot; streaming config (webhook/SIEM target) + test delivery; retention policy document | Audit/Compliance owner | Monthly | Insufficient retention blocks investigations; over-retention is cost. | Review retention with compliance team quarterly |
| audit | Audit log event capture (PR reviews, repo changes, team membership) | Org | Standard GitHub audit events (all enabled by default) | Enables tracing of who-did-what-when for governance and incident response | `approved pilot` (Ch09 Part A awareness) | Audit log filter example: `action:team.add_member` showing change history | Org owner | Quarterly | Audit logs record default events; deletions or redactions break auditing | Document retention + export cadence |
| security | Secret scanning (push protection) | Org | Enabled on all repos; patterns customized per team (e.g., company-custom secrets, Azure SPN patterns) | Blocks hardcoded credentials from entering repos; custom patterns catch internal secret formats | `approved pilot` (Ch11 Part A–B) | Alert report from GitHub; test commit showing push rejection; custom pattern test case | Security/SecOps owner | Monthly | If disabled: secrets flow to prod; custom patterns misfire: false positives. | Monthly scan audit; update patterns if detection gaps |
| security | Code scanning (CodeQL) | Org | Enabled on high-risk repos (e.g., `compliance: high`); customized query suites per language | Detects code flaws before merge; enterprise scans scale across teams | `approved pilot` (Ch12 Part A–B) | CodeQL workflow runs; alert summary (critical/high); custom query execution | AppSec/DevSec team | Weekly | If enabled on all: cost & noise; if enabled on few: coverage gap | Monthly: review alert backlog; prioritize critical findings |
| security | Dependency scanning & Dependabot | Org | Enabled on production repos; auto-merge policy for patch updates | Reduces supply-chain risk; auto-merge frees teams from busywork on safe updates | `approved pilot` (Ch13 Part A–B) | Dependabot alert report; auto-merge workflow runs; test PR showing auto-merge | AppSec/DevSec team | Weekly | If disabled: unpatched deps in prod; auto-merge: might merge bad updates (rare). | Monthly: audit outdated deps; review auto-merge success rate |
| security | Code quality gates (coverage, maintainability) | Org | Approved threshold (e.g., min 80% coverage, no new issues) | Maintains code health; gates merges on quality + test coverage | `approved pilot` (Ch27 Part A–B) | Build report showing coverage % + quality score; status check configuration | Tech lead / Platform team | Bi-weekly | Too strict: blocks legitimate code; too loose: quality degrades. | Monthly: review metric targets with teams |
| development | Prebuild strategy (Codespaces) | Org | Approved trigger (e.g., on push to main), regions, retained versions, owner | Reduces Codespace startup time; cost/freshness trade-off documented | `approved pilot` (Ch03 Part E) | Prebuild config export; successful prebuild run ID; cost analysis (Actions minutes consumed); `docs/prebuild-decision.md` | DevOps/Platform owner | Monthly | Expensive: many regions/versions; too cheap: stale dependencies | Quarterly: review prebuild hit rate + cost |
| development | Dev container standardization | Org | Approved base image (pinned), features, lifecycle commands, extensions | Reproducible dev environment; onboarding friction reduced | `approved pilot` (Ch03 Part A–C) | `.devcontainer/devcontainer.json` export; test Codespace run; `docs/devcontainer-notes.md` | Platform/DevOps owner | Quarterly | Unmanaged devcontainers: slow; over-standardized: inflexible. | Quarterly: survey team satisfaction; update base image on LTS change |
| billing | Budgets & usage alerts | Org | Approved budget cap (per product: Actions, Storage, Packages); alert thresholds at 75%, 90%, 100% | Prevents surprise spend; cost visibility by metered product | `approved pilot` (Ch10 Part A–C) | Budget configuration screenshot; alert recipient list; billing API usage export `/organizations/<org>/settings/billing/usage`; `COST-REPORT.md` with before/after reconciliation | Billing/Finance owner | Monthly | Over-budget halts workflows (if enabled); under-budget misses savings opportunity. | Quarterly: review actual spend vs budget; adjust caps with usage trends |

## Adding New Rows

When implementing a new governance setting:

1. **Identify the domain** (e.g., `org-membership`, `security`, `workflow`, `audit`).
2. **Fill in all columns** — leave `Next Decision` blank until first review.
3. **Evidence column:** Link to API snapshots, test results, configuration exports, or decision docs (e.g., `docs/POLICY.md`, workflow run URL, screenshot filename).
4. **Implementation path:** Mark as `approved pilot` (ready to go) or `inspect-and-propose` (needs customer decision before live deployment).
5. **Accountable owner:** Must be a real person/role; no "TBD."
6. **Add to the activity's success criteria** so evidence is collected during the delivery session.

---

## Integration with Activities

- **Ch06:** Initialize the register; add rows for org-membership and org-security settings.
- **Ch04:** Add Actions caching row.
- **Ch07:** Add teams and custom-roles rows.
- **Ch08:** Add rulesets and custom-properties rows.
- **Ch09:** Add audit log rows.
- **Ch11–15 + Ch27:** Add security (scanning, Dependabot, code quality) rows.
- **Ch03:** Add prebuild and devcontainer rows.
- **Ch17:** Add apps/webhooks row (future).
- **Ch18:** Add runner policy row.

---

## Maintenance

- **Review cadence:** Quarterly governance sync with org owner; monthly audit log review for changes.
- **Annual:** Full register audit; deprecate unused settings; align with GitHub platform updates.
- **Change control:** Any modification to a setting's desired value requires org owner approval + risk assessment + communication to affected teams.

---

## Reference

- Official: [GitHub Organizations REST API](https://docs.github.com/en/rest/orgs/orgs)
- Official: [GitHub Audit Log](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)
- Official: [Enterprise Accounts (settings above org level)](https://docs.github.com/en/enterprise-cloud@latest/admin/overview/about-enterprise-accounts)
