# Ch37: Governance Quick Review with ghqr

> Deliver a read-only GitHub governance posture review using `ghqr`, corroborate material findings, and prioritize the next actions.

| | |
|---|---|
| Track | Admin/Governance |
| Difficulty | Advanced |
| Duration | 105 min |
| Minimum input | Authorized organization review scope, reviewer token, and customer evidence location |
| App | none |
| EMU compatible | yes |

## Prerequisites

- A GitHub Enterprise Cloud organization and authorization from the customer governance owner to run a read-only posture review.
- `ghqr` installed locally, available through Docker, or approved for installation during the session.
- A `GITHUB_TOKEN` with the least privileges needed for the selected scan. Typical GitHub.com scopes are `read:org`, `repo`, `read:audit_log`, `read:user`, and only when in scope, `read:enterprise` and `copilot`.
- A customer-approved non-secret evidence location for JSON, Markdown, or XLSX output. Do not commit tokens or sensitive raw extracts.
- Optional: enterprise owner approval for `ghqr scan -e <enterprise>`. Enterprise-only findings must not be inferred from an organization-only scan.

## Customer delivery objectives

You will:

- Select `ghqr`, capture its version, and run the authorized organization scan.
- Run the optional enterprise scan only with customer authorization and the required token access.
- Preserve non-secret output and triage findings by severity, source level, and owner.
- Keep evidence and recommendations separate. Build a prioritized backlog with owners, dependencies, rollback needs, and review cadence.

## Scope and guardrails

`ghqr` checks many GitHub surfaces, including security settings, access control, branch protection, Copilot policy, audit logs, Actions policy, dependencies, repository metadata, and community-health files. Use it to speed up assessment. It does not replace customer risk decisions.

Use these guardrails throughout:

- Run read-only scans unless a separate customer change approval exists.
- Store only non-secret report artifacts in the evidence location.
- Record token scopes and reviewer role, but never store token values.
- Do not change settings without separate customer approval.
- For GitHub Enterprise Cloud with data residency, set `GH_HOST=<customer>.ghe.com` or pass `--hostname <customer>.ghe.com`.
- Synthetic `ghqr mock` output is useful for demos, but it is not customer evidence.

## Tasks

### Part A — Define scope and evidence rules

1. Record the organization, reviewer role, approval owner, scan date, evidence location, identity model, and whether the customer uses GitHub.com or GHE.com data residency. Check whether ghec-ch52 (organization topology, delegation matrix, and control register) has already been completed for this customer; if it is available, retrieve it and use its approved scope, ownership, and delegation boundaries as authoritative context, and if it is not available, define scope and ownership independently within this activity without blocking the review.
2. Define the allowed scan scope:
   - **Required:** organization scan.
   - **Optional:** enterprise scan only when the customer explicitly authorizes it and provides an enterprise-capable token.
3. Record the token boundary: intended scopes and expiration/rotation owner, but never the token value.
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

   Do not paste this value into shell history screenshots or report notes.

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
13. If enterprise review is not authorized, record that the enterprise policy source is unavailable to the reviewer. Do not infer enterprise inheritance from organization-only results.

### Part E — Triage and corroborate findings

14. Review the top findings by severity and category. Identify the effective level and source—enterprise, organization, repository, or unavailable—and the accountable owner. When the ghec-ch52 topology, delegation matrix, or register is available, cross-check each material finding's ownership and effective source against it and cite it as corroborating evidence; when it is unavailable, corroborate using GitHub API/audit evidence only and record the register as not available (not as compliant).
15. Corroborate at least one finding with a GitHub evidence surface. Examples:

   ```bash
   gh api /orgs/<org> --jq '{default_repository_permission, members_can_create_repositories, members_can_create_public_repositories, members_can_fork_private_repositories}'
   ```

   ```bash
   gh api /orgs/<org>/audit-log --paginate --jq '.[0:5]'
   ```

   ```bash
   gh api /orgs/<org>/rulesets --jq '.[] | {name, enforcement, target}'
   ```

16. Build a short remediation backlog from the material findings. Record the owner, risk, dependency, next decision date, and evidence link.

### Part F — Handover

17. Walk the governance owner through:
    - what was scanned;
    - what was unavailable and why;
    - top accepted risks and proposed changes;
    - which findings require enterprise owner involvement;
    - which remediation candidates need separate approval.
18. Confirm the next posture-review cadence. Record whether `ghqr` becomes a quarterly review input, an onboarding check for newly acquired orgs, or a one-time assessment artifact.

## Reference links

- GitHub Quick Review (`ghqr`) — https://github.com/microsoft/ghqr
- Enforcing policies for your enterprise — https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise
- Organizations REST API — https://docs.github.com/en/rest/orgs/orgs
- Reviewing the audit log for your organization — https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization
- GitHub Enterprise Cloud with data residency — https://docs.github.com/en/enterprise-cloud@latest/admin/data-residency/about-github-enterprise-cloud-with-data-residency
