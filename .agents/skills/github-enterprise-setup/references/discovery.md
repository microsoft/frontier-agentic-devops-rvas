# Discovery

Use progressive, read-only discovery. Run the smallest query that can answer the
current question.

## Request conventions and endpoint gate

Before the first API call, read the
[GitHub CLI API manual](https://cli.github.com/manual/gh_api)
and check the installed `gh api --help` for the flags you need. Before the first
REST call, choose a supported version from
[REST API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions).
Record that version in `assessment.json` and pin it on every REST request.

After confirming the host and version, declare the headers used by the REST
examples below:

```bash
GITHUB_API_VERSION=2026-03-10
REST_HEADERS=(-H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: $GITHUB_API_VERSION")
```

These are Bash snippets, not standalone scripts. Render the host and version as
explicit values in saved plan commands rather than relying on session variables.

- Use an explicit REST method. Adding `-f` or `-F` otherwise changes the default
  from `GET` to `POST`.
- Use `-f` for strings and `-F` for typed values. A value beginning with `@` in
  `-F` reads a file; use `-f` for an untrusted string that must remain literal.
- Process all required pages. `--paginate` emits separate page documents;
  use `--slurp` when the next step needs one JSON value, and check its nested shape.
- For GraphQL reads, confirm the document is a `query`, not a `mutation`.
  Pagination needs an `$endCursor` variable and `pageInfo`.

**Endpoint gate:** choose the exact operation from the
[REST reference](https://docs.github.com/en/rest) or the
[enterprise GraphQL reference](https://docs.github.com/en/enterprise-cloud%40latest/graphql/reference/enterprise-admin).
Before planning any write, verify its method or mutation, payload types, supported
token types, required permissions or scopes, actor role, host availability, and
preview or deprecation status. Validate the precondition and verification reads
too. Before unfamiliar or preview discovery calls, apply the same check.

Record the exact endpoint documentation URL and check timestamp in the operation's
`documentation` field, along with the API version, token type, required
permissions, supported host, and availability status. A category landing page
alone is not endpoint evidence. If documentation or authority cannot establish a
supported path, block the write or create a manual handoff.

## Host and authentication

Accept only:

- `github.com`
- a lowercase customer host ending in `.ghe.com`

Read the [CLI environment reference](https://cli.github.com/manual/gh_help_environment)
before checking identity. `GH_TOKEN` and `GITHUB_TOKEN` take precedence over stored
credentials for Cloud hosts. Check only whether they are set, never their values.
A stored-account switch may leave the request actor unchanged. Require approval
before changing credential sources, then recheck identity with the `user` request.

Start with the confirmed REST headers:

```bash
gh auth status --active --hostname "$HOST" --json hosts
GH_HOST="$HOST" gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" user \
  --jq '{login,id,type}'
```

Never use `--show-token`. Do not call `gh auth token`.

If the user approves an authentication change, use the narrow command needed:

```bash
gh auth login --hostname "$HOST"
gh auth switch --hostname "$HOST" --user "$LOGIN"
gh auth refresh --hostname "$HOST" --scopes read:enterprise
```

Add write scopes only when the approved plan needs them. Recheck the actor after
every login, switch, or refresh.

## Enterprise selection

List enterprises visible to the active user through GraphQL:

```bash
GH_HOST="$HOST" gh api --hostname "$HOST" graphql --paginate \
  -f query='
    query($endCursor:String) {
      viewer {
        enterprises(first:100, after:$endCursor) {
          nodes { id slug name }
          pageInfo { hasNextPage endCursor }
        }
      }
    }'
```

Verify the selected enterprise by slug. A visible enterprise does not prove the
actor has owner or write authority.

List organizations in the selected enterprise:

```bash
GH_HOST="$HOST" gh api --hostname "$HOST" graphql --paginate \
  -F slug="$ENTERPRISE" \
  -f query='
    query($slug:String!, $endCursor:String) {
      enterprise(slug:$slug) {
        organizations(first:100, after:$endCursor) {
          nodes { id login name }
          pageInfo { hasNextPage endCursor }
        }
      }
    }'
```

If the API cannot prove enterprise membership or organization ownership, record
the result as `insufficient_permission` or `unverified`.

## Organization probes

Run only for selected organizations:

```bash
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/orgs/$ORG"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/members?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/outside_collaborators?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/teams?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/repos?type=all&per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/rulesets?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/orgs/$ORG/properties/schema"
```

Filter responses before saving. Keep stable IDs, names, policy fields, and counts.
Do not save member email addresses, profile text, repository contents, or unrelated
metadata.

## Team and access probes

For selected teams and repositories:

```bash
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/orgs/$ORG/teams/$TEAM"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/teams/$TEAM/members?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/teams/$TEAM/repos?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/orgs/$ORG/teams/$TEAM/repos/$ORG/$REPO"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/repos/$ORG/$REPO/collaborators/$LOGIN/permission"
```

Inspect direct collaborators only when access repair needs them. Never infer a
member's effective permission from one team grant.

When checking a user's effective role, use `role_name` from
[repository permissions for a user](https://docs.github.com/en/rest/collaborators/collaborators#get-repository-permissions-for-a-user).
Its legacy `permission` field maps maintain to write and triage to read.

Enterprise teams use enterprise endpoints and different permissions. Detect them
before trying organization-team operations.

## Repository probes

For selected repositories:

```bash
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/repos/$ORG/$REPO"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/repos/$ORG/$REPO/rulesets?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/repos/$ORG/$REPO/actions/permissions"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/repos/$ORG/$REPO/actions/permissions/workflow"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/repos/$ORG/$REPO/code-security-configuration"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/repos/$ORG/$REPO/code-scanning/default-setup"
```

Fetch file contents only when the selected outcome requires template, CODEOWNERS,
workflow, instruction, or agent-file comparison. Limit the paths and file sizes.

## Enterprise and Actions probes

Use the selected enterprise slug:

```bash
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/enterprises/$ENTERPRISE/actions/permissions"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/enterprises/$ENTERPRISE/actions/permissions/selected-actions"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/enterprises/$ENTERPRISE/actions/permissions/workflow"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/enterprises/$ENTERPRISE/rulesets"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/enterprises/$ENTERPRISE/properties/schema"
```

Do not assume every UI control has a supported REST write. If the current official
documentation does not define a safe endpoint, create a manual handoff.

## Security probes

For selected organizations:

```bash
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/code-security/configurations?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/code-scanning/alerts?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/secret-scanning/alerts?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/dependabot/alerts?per_page=100"
```

Alert inventories can be large and sensitive. Ask before broad collection, save
counts and control state by default, and avoid alert details unless the outcome
requires triage.

## Copilot probes

Start with subscription and assignment state:

```bash
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/orgs/$ORG/copilot/billing"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" --paginate "/orgs/$ORG/copilot/billing/seats?per_page=100"
gh api --hostname "$HOST" --method GET "${REST_HEADERS[@]}" "/enterprises/$ENTERPRISE/copilot/custom-agents/source"
```

Use enterprise seat, metrics, content-exclusion, cloud-agent, and custom-agent
endpoints only after checking current official GitHub documentation. Confirm
whether the endpoint is in public preview and whether the active token type is
supported.

Save usernames or team slugs only when the approved rollout needs named
assignments. Prefer counts and groups for an assessment.

## Failure classification

Classify failures from HTTP status and API error type:

| Result | State |
|---|---|
| Successful response with expected shape | `verified` |
| Confirmed absent resource with enough authority | `missing` |
| 401, non-rate-limit 403, insufficient scopes, inaccessible resource | `insufficient_permission` |
| Rate limit, timeout, network failure, 5xx | `unavailable` |
| External setup or secret-bearing prerequisite | `manual_prerequisite` |
| Ambiguous 404, unexpected response, unsupported inference | `unverified` |

Do not hide failed discovery behind empty arrays or default values.

When a read fails, consult
[REST API troubleshooting](https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api).
Inspect safe status and permission headers such as `X-Accepted-GitHub-Permissions`;
do not print full HTTP traces or authorization headers. For rate limits, use the
pacing and recovery rules in `safety-and-approval.md`.

## Caching and freshness

Cache successful read results in `assessment.json` with timestamps. Do not cache
authentication failures, permission failures, or unavailable results as facts.

Before planning a write, refresh the target resource. Before executing it, refresh
the actor, stable target ID, effective source, and every stated precondition.

## Broad-inventory approval

Ask before:

- scanning all organizations;
- listing all repositories or members across the enterprise;
- exporting audit events;
- listing all security alerts;
- listing all Copilot seats or usage records;
- inspecting all installed applications;
- fetching repository file content at scale.

Show the target count, data categories, estimated API requests, saved fields, and
retention path.
