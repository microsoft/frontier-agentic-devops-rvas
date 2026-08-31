# Ch37: Governance Quick Review with ghqr

> Deliver a read-only GitHub governance posture review using `ghqr`, then convert the report into customer-owned register evidence and prioritized decisions.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | ~3 hrs total, multi-session |
| Minimum input | Authorized organization review scope, reviewer token, customer evidence location, and governance register |
| App | none |
| EMU compatible | yes |

## Customer delivery target

- Objective: produce an evidence-backed view of GitHub organization settings and risks.
- Delivery target: an authorized `ghqr` organization scan, retained non-secret reports, and governance-register updates mapped to existing controls.
- Safety boundary: the review is read-only by default. Remediation belongs in an inspect-and-propose decision or a separately approved pilot/change.
- Evidence: scan target, reviewer role, token boundary, `ghqr` version, reports, finding triage, corroboration, register rows, exceptions, and next decisions.
- Owner: platform governance.
- Next decision: approve a remediation pilot, request enterprise evidence, accept an exception, or schedule the next posture review.

> [!IMPORTANT]
> Use the existing customer governance register. Do not create a parallel findings tracker. Map `ghqr` findings to the existing control catalogue where possible, and record gaps as inspect-and-propose decisions rather than inventing new control IDs.

## Prerequisites

- A GitHub Enterprise Cloud organization and authorization from the customer governance owner to run a read-only posture review.
- `ghqr` installed locally, available through Docker, or approved for installation during the session.
- A `GITHUB_TOKEN` with the least privileges needed for the selected scan. Typical GitHub.com scopes are `read:org`, `repo`, `read:audit_log`, `read:user`, and only when in scope, `read:enterprise` and `copilot`.
- A customer-approved non-secret evidence location for JSON, Markdown, or XLSX output. Do not commit tokens or sensitive raw extracts.
- The existing customer governance register created from `modules/ghec/resources/GOVERNANCE-SETTINGS-REGISTER-TEMPLATE.md`.
- Optional: enterprise owner approval for `ghqr scan -e <enterprise>`. Enterprise-only findings must not be inferred from an organization-only scan.

## Customer delivery objectives

You will:

- Select `ghqr`, capture its version, and run the authorized organization scan.
- Run the optional enterprise scan only with customer authorization and the required token access.
- Preserve non-secret output and triage findings into the existing governance register and control catalogue.
- Keep evidence, recommendations, and customer decisions separate. Build a prioritized backlog with owners, implementation path, exception/rollback, and review cadence.

## Scope and guardrails

`ghqr` checks many GitHub surfaces, including security settings, access control, branch protection, Copilot policy, audit logs, Actions policy, dependencies, repository metadata, and community-health files. Use it to speed up assessment. It does not replace customer risk decisions.

Use these guardrails throughout:

- Run read-only scans unless a separate customer change approval exists.
- Store only non-secret report artifacts in the evidence location.
- Record token scopes and reviewer role, but never store token values.
- Use `approved pilot` only for separately authorized changes. Otherwise record `inspect-and-propose`.
- For GitHub Enterprise Cloud with data residency, set `GH_HOST=<customer>.ghe.com` or pass `--hostname <customer>.ghe.com`.
- Synthetic `ghqr mock` output is useful for demos and coach preparation, but it is not customer evidence.

## Tasks

### Part A — Define scope and evidence rules

1. Record the organization, reviewer role, approval owner, scan date, evidence location, identity model, and whether the customer uses GitHub.com or GHE.com data residency.
2. Define the allowed scan scope:
   - **Required:** organization scan.
   - **Optional:** enterprise scan only when the customer explicitly authorizes it and provides an enterprise-capable token.
3. Record the token boundary. The register or evidence note should list intended scopes and expiration/rotation owner, but never the token value.
4. Confirm where report artifacts will be stored and who may access them. Some reports can expose repository names, policy posture, users, or security gaps.

### Part B — Install or select ghqr

5. Install `ghqr` through the customer-approved method, or select an existing binary/container.

   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/ghqr/main/scripts/install.sh)"
   ```

   Docker alternative:

   ```bash
   docker pull ghcr.io/microsoft/ghqr:latest
   ```

6. Capture tool evidence:

   ```bash
   ghqr -h
   ```

7. Set the token in your shell for the scan session only:

   ```bash
   export GITHUB_TOKEN=<token-value>
   ```

   Do not paste this value into the register, shell history screenshots, or report notes.

### Part C — Run the organization quick review

8. Run the organization scan:

   ```bash
   ghqr scan -o <org>
   ```

   For GHE.com data residency:

   ```bash
   ghqr scan -o <org> --hostname <customer>.ghe.com
   ```

   or:

   ```bash
   export GH_HOST=<customer>.ghe.com
   ghqr scan -o <org>
   ```

9. Preserve the generated JSON plus Markdown or XLSX report in the customer-approved evidence location. Record the filename, timestamp, target, reviewer, and `ghqr` version.
10. If the scan returns degraded or unavailable checks, record why: missing token scope, unavailable license/feature, enterprise-only setting, rate limiting, or authorization boundary.

### Part D — Optional enterprise scan

11. If enterprise review is authorized, run:

   ```bash
   ghqr scan -e <enterprise>
   ```

12. Preserve the enterprise report separately from the organization report. Record token scope, evidence location, and enterprise owner approval.
13. If enterprise review is not authorized, add a register note or evidence record that enterprise policy source is unavailable to the reviewer. Do not infer enterprise inheritance from organization-only results.

### Part E — Triage findings into governance decisions

14. Review the top findings by severity and category. For each material finding, map it to an existing control in `modules/ghec/resources/GOVERNANCE-CONTROL-CATALOGUE.md` where possible.
15. Update the customer governance register. Each row should include:
    - Control ID and domain.
    - Effective level and source: enterprise, org, repo, or unavailable.
    - `ghqr` report link and any corroborating setting/API/audit evidence.
    - Selected path: `inspect-and-propose`, `approved pilot`, `exception`, `adopted`, or `not applicable`.
    - Accountable owner, review cadence, exception/rollback, and next decision.
16. Corroborate at least one finding with a GitHub evidence surface. Examples:

   ```bash
   gh api /orgs/<org> --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_fork_private_repositories}'
   ```

   ```bash
   gh api /orgs/<org>/audit-log --paginate --jq '.[0:5]'
   ```

   ```bash
   gh api /orgs/<org>/rulesets --jq '.[] | {name, enforcement, target}'
   ```

17. Build a short remediation backlog from the register rows. Record the owner, risk, dependency, path, next decision date, and evidence link.

### Part F — Handover

18. Walk the governance owner through:
    - what was scanned;
    - what was unavailable and why;
    - top accepted risks and proposed changes;
    - which findings require enterprise owner involvement;
    - which remediation candidates need separate approval.
19. Confirm the next posture-review cadence. Record whether `ghqr` becomes a quarterly review input, an onboarding check for newly acquired orgs, or a one-time assessment artifact.

## Validation / Definition of Done

You are done when all of the following are true:

- [ ] Authorized organization scope, reviewer role, token boundary, evidence location, and report-retention decision are recorded before the scan.
- [ ] `ghqr` is installed or selected through Docker, and its help/version output is captured as execution evidence.
- [ ] An organization scan completes with `ghqr scan -o <org>` and produces retained JSON plus Markdown or XLSX evidence.
- [ ] Enterprise scan applicability is explicitly recorded: completed with approval and `read:enterprise`, or marked not authorized/not applicable without inferring enterprise settings.
- [ ] Top `ghqr` findings are triaged to existing governance catalogue controls, with effective source level, objective evidence link, severity, accountable owner, implementation path, exception/rollback, and review date.
- [ ] At least one finding is corroborated with a GitHub setting, audit, or API evidence surface where available.
- [ ] No production setting is changed by default; remediation is captured as inspect-and-propose or a separately approved pilot/change.
- [ ] The governance owner can name the highest-priority risk, its owner, the evidence link, and the next decision.
- [ ] Record the governance owner, posture-review cadence, accepted exceptions, and next approved remediation or enterprise-evidence request.

## Operational extensions

- Replay a previous scan JSON with `ghqr scan --from-json <file>` to re-render reports without re-querying GitHub. Label replay output clearly and keep the original scan timestamp.
- Use `ghqr mock --render` only for coach demos or report-template walkthroughs. Do not use mock output as customer evidence.
- Schedule an approved recurring posture review and compare register changes over time.
- Pair this activity with Ch09 to preserve audit-log query/export evidence for material governance changes found during the review.

## Reference links

- GitHub Quick Review (`ghqr`) — https://github.com/microsoft/ghqr
- Enforcing policies for your enterprise — https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise
- Organizations REST API — https://docs.github.com/en/rest/orgs/orgs
- Reviewing the audit log for your organization — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization
- GitHub Enterprise Cloud with data residency — https://docs.github.com/en/enterprise-cloud@latest/admin/data-residency/about-github-enterprise-cloud-with-data-residency
