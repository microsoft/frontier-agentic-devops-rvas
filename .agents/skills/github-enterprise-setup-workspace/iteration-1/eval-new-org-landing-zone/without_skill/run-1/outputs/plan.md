# Proposed `contoso-payments` landing zone

## Design

- Create `contoso-payments` inside the `contoso` enterprise.
- Add closed teams named `platform`, `backend`, and `frontend`.
- Assign at least two maintainers to each team. Add engineers through the enterprise identity process rather than direct invitations if the enterprise uses Enterprise Managed Users.
- Create one private service repository from the approved golden template. Confirm the template owner, repository, target repository name, and template ref before execution.
- Set the organization default `GITHUB_TOKEN` workflow permission to **read repository contents and packages**. Disable workflow approval of pull requests unless a documented exception requires it.
- Apply the enterprise-approved code security configuration. Require CodeQL default setup for supported languages and secret scanning with push protection.
- Assign GitHub Copilot seats to the `backend` and `frontend` teams only. Use team-based assignment and reconcile the requested seats against available enterprise licenses.

## Planned sequence

1. Reauthenticate with a principal that can administer the `contoso` enterprise and create organizations. Use only the minimum scopes needed for the approved change.
2. Confirm the enterprise slug, identity model, organization-creation policy, Actions policy, security configurations, Copilot plan, and available seats.
3. Confirm that `contoso-payments` remains available immediately before creation.
4. Create the organization and attach it to `contoso`.
5. Create the three teams, assign maintainers, and add the approved members.
6. Create the private repository from the named golden template and grant team access:
   - `platform`: maintain or admin, based on the operating model
   - `backend`: write
   - `frontend`: write
7. Set default workflow token permissions to read-only and disable pull-request approval by workflows.
8. Apply CodeQL, secret scanning, and push protection through a security configuration. Verify language support and initial scan status.
9. Assign Copilot to `backend` and `frontend`. Confirm seat counts and assignment status.
10. Run a read-only verification, record the final settings, and stop for acceptance.

## Required decisions

- Exact enterprise slug and proof that the execution principal can administer it
- Golden-template owner/repository and target service repository name
- Identity model: Enterprise Managed Users or personal accounts with SAML/SCIM
- Organization owners, team maintainers, and team membership lists
- Repository permission for `platform`
- Expected backend and frontend Copilot seat counts
- Enterprise-approved code security configuration, or approval to create one
- Whether third-party Actions should be blocked, allow-listed, or permitted

## Acceptance checks

- The organization belongs to the correct enterprise.
- All three teams exist with approved maintainers and members.
- The service repository is private and retains the template content and required configuration.
- Organization workflow permissions report `read`, and workflows cannot approve pull requests.
- CodeQL is enabled for supported languages.
- Secret scanning and push protection are enabled.
- Copilot is assigned only to approved backend and frontend users.
- No credentials, tokens, or secret values appear in the implementation record.
