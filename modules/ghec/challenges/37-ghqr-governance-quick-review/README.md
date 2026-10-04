# Ch37: Review and repair governance with ghqr

**Session outcome:** A verified `ghqr` finding leads to one approved configuration repair. A repeat scan and an enforcement check show that the repair works.

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
- Repair one verified gap with its owner's approval and check the result.

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

### Part A: Define scope and evidence rules

1. Record the approved organization, authorized reviewer, scan date, and evidence location. Confirm GitHub.com or GHE.com and the identity model.
2. Define the allowed scan scope:
   - **Required:** organization scan.
   - **Optional:** enterprise scan only when the customer explicitly authorizes it and provides an enterprise-capable token.
3. Record the token boundary: intended scopes and expiration/rotation owner, but never the token value.
4. Confirm where report artifacts will be stored and who may access them. Some reports can expose repository names, policy posture, users, or security gaps.

### Part B: Install or select ghqr

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

### Part C: Run the organization quick review

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

### Part D: Optional enterprise scan

11. If enterprise review is authorized, run:

   ```bash
   ghqr scan -e <enterprise>
   ```

12. Preserve the enterprise report separately from the organization report. Record token scope, evidence location, and enterprise owner approval.
13. If enterprise review is not authorized, record that the enterprise policy source is unavailable to the reviewer. Do not infer enterprise inheritance from organization-only results.

### Part E: Triage and corroborate findings

14. Review findings that need action and identify the owner and configuration level for each. Check them against settings or API evidence. Mark unavailable evidence as unverified.
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

### Part F: Repair and verify one gap

17. Choose one material finding the owner authorizes you to fix. Save the current setting and agree on rollback. Use the matching configuration chapter rather than inventing a workaround: [Ch07](../07-teams-roles-permissions/README.md) for team access, [Ch08](../08-rulesets-repo-properties/README.md) for rulesets, or [Ch04](../04-actions-ci-fundamentals/README.md) for required CI.
18. Apply the approved repair to the selected pilot. Test the behavior directly: for a review rule, an unapproved PR must stay blocked; for access, the intended user succeeds and an out-of-scope user is denied.
19. Rerun the same `ghqr scan -o <org>` command, using the same host and scope. Compare the selected finding with the before report. If the scanner still reports it, inspect the effective setting and the check's limitations instead of marking it fixed.
20. Keep the repaired setting and test result in the existing adoption issue. Agree when the owner will run the same check for the next repository cohort. An automatic schedule is optional.

If no material gap exists, test one existing control and record that it already meets the requirement. Do not create a defect to get a finding. If repair approval or direct validation is unavailable, retain the assessment and mark implementation **blocked / not tested**. Mock output is sample practice.

## Reference links

- [GitHub Quick Review (`ghqr`)](https://github.com/microsoft/ghqr)
- [Enforcing policies for your enterprise](https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise)
- [Organizations REST API](https://docs.github.com/en/rest/orgs/orgs)
- [Reviewing the audit log for your organization](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization)
- [GitHub Enterprise Cloud with data residency](https://docs.github.com/en/enterprise-cloud@latest/admin/data-residency/about-github-enterprise-cloud-with-data-residency)
