# Plan: `contoso-payments`

**No changes were made.** I used read-only GitHub API calls against `github.com` on October 9, 2026.

## Live assessment

The current GitHub CLI session is authenticated, but it cannot see an enterprise with the slug `contoso`. Both the enterprise lookup and enterprise-organization lookup returned `NOT_FOUND`/HTTP 404. The authenticated principal's visible-enterprise list also does not include `contoso`.

The current token does not have the enterprise and organization administration permissions needed to inspect all requested policies or perform the later setup. GitHub can return 404 for resources hidden by authorization, so this result **does not prove that the enterprise is absent**.

Other findings:

- `contoso-payments` does not resolve to a visible GitHub user or organization. Treat this only as a preliminary name check, not a guarantee that GitHub will allow creation.
- A public organization named `contoso` exists on GitHub. I could not establish any relationship between that organization and the requested enterprise account.
- I could not assess the `contoso` enterprise's organizations, Actions policy, code security configuration, Copilot entitlement, available seats, or identity model.
- No golden-template repository was identified in the request, so template readiness could not be checked.

**Assessment status: blocked by account visibility and authorization.** Do not create the organization until an enterprise owner confirms the exact enterprise slug and provides a session that can administer it.

## Proposed landing zone

After access is corrected and the plan is approved:

1. Create `contoso-payments` inside the confirmed `contoso` enterprise.
2. Create closed teams: `platform`, `backend`, and `frontend`. Assign at least two maintainers per team.
3. Create a private service repository from the approved golden template.
4. Give `platform` maintain or admin access, and give `backend` and `frontend` write access. Confirm the platform permission before execution.
5. Set the organization default `GITHUB_TOKEN` workflow permission to **read repository contents and packages**. Disable workflow pull-request approval.
6. Apply the approved code security configuration. Enable CodeQL default setup for supported languages, secret scanning, and secret-scanning push protection.
7. Assign GitHub Copilot through the `backend` and `frontend` teams only. Reconcile the final member count with available seats first.
8. Verify every setting with read-only calls and save a redacted implementation record.

## Inputs required before implementation

- Confirmed enterprise slug and an enterprise-owner execution principal
- Golden-template owner/repository and target service repository name
- Identity model: Enterprise Managed Users or personal accounts with SAML/SCIM
- Organization owners, team maintainers, and membership lists
- Backend and frontend Copilot seat counts
- Approved code security configuration
- Policy for third-party Actions: block, allow-list, or permit

The redacted evidence is in `assessment.json`, and the detailed implementation sequence and acceptance checks are in `plan.md`.
