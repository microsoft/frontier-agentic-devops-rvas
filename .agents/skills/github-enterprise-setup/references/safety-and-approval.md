# Safety and approval

## Risk tiers

### Routine

Examples:

- create an approved organization, team, or repository;
- add standard labels or repository properties;
- update reversible repository settings;
- grant an approved team access to a named repository;
- open a branch or pull request with standard content.

Routine work still needs batch approval.

### High impact

Examples:

- change enterprise or organization policy;
- change base permissions or broad repository visibility;
- add or remove owners;
- change team membership at scale;
- enforce two-factor authentication;
- change PAT or application policy;
- change Actions allowlists, runner access, or fork policy;
- attach security configurations broadly;
- assign paid Copilot seats;
- enable a feature with recurring cost;
- remove access or disable a service.

Before approval, show:

- exact target count;
- current and desired effective state;
- policy source;
- affected users, teams, repositories, or workflows;
- disruption and billing impact;
- prerequisites;
- rollback or recovery;
- acceptance checks.

Require a separate typed confirmation that names the batch and target. A generic
"yes" is not enough.

### Manual or unsupported

Examples:

- enterprise account purchase, invoicing, or data-residency contracting;
- SAML, SCIM, or identity-provider secret setup;
- recovery-code handling;
- audit-stream or webhook receiver credentials;
- cloud-side OIDC trust creation;
- unsupported or undocumented API writes;
- destructive deletion without a safe recovery path.

Create a handoff with an owner, required inputs, official settings location,
verification, and evidence field. Do not turn a manual control into an improvised
API or browser automation.

## Batch approval

Build batches around one purpose and one accountable owner. Do not combine a low
risk repository create with a high-impact enterprise policy change.

Use this approval summary:

```text
Batch:
Purpose:
Targets:
Risk:
Current effective state:
Proposed changes:
Cost or license effect:
Disruption:
Preconditions:
Rollback or recovery:
Acceptance checks:
Commands:
```

Ask for approval only when every field is known. Show blocked batches for review,
but keep them ineligible for execution until their blockers are resolved.

## Execution rules

1. Recheck the active host and actor.
2. Resolve targets by stable ID where the API supports it.
3. Re-read every precondition.
4. Compare the refreshed state with the approved plan.
5. Stop if the target, source policy, recipient set, cost, or permissions changed.
6. Run one write at a time.
7. Capture the HTTP result and a redacted response summary when available.
8. Verify the effective result.
9. Record the acceptance result; use `outcome_unknown` when the write's effect
   cannot be established, and otherwise mark failed or blocked checks explicitly.

Never use broad catches, `|| true`, silent defaults, or success-shaped fallbacks
around write commands.

## Pacing and recovery

Before applying a multi-request batch, read
[REST API best practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api).
Make API requests serially and wait at least one second between mutating requests
in a multi-write batch.

For a rate-limit response, pause the batch. Honor `Retry-After`; if
`X-RateLimit-Remaining` is zero, also wait until `X-RateLimit-Reset`. Otherwise wait
at least one minute, then use exponential backoff. Allow at most three retries
per request and record the waits. A `403` alone does not establish a rate limit.

**Uncertain write:** a timeout, lost connection, or server error after sending a
write does not prove failure. Record `outcome_unknown`, stop the batch, and reread
the target through a separate request before any retry. Apply this rule to
in-progress operations found during Resume too.

- If the desired state exists, run all acceptance checks and record the evidence.
- If the approved pre-write state still exists, retry only after rechecking all
  preconditions and confirming that the operation is safe to repeat. Renew
  approval when its scope or effect changed.
- If the read is inconclusive or shows a partial change, keep dependent
  operations blocked and request recovery or manual evidence.

Use bounded verification reads for asynchronous changes, with the interval and
deadline defined in the plan. Never replay a write merely because verification
has not caught up.

## Idempotence

Prefer:

- get, compare, then create or update;
- conditional creation when the named resource is absent;
- exact patches containing only approved fields;
- explicit recipient lists;
- stable resource IDs;
- repeatable verification.

Avoid:

- replacing whole objects when a narrow update exists;
- using list position as identity;
- commands that depend on shell history or ambient variables;
- unbounded loops;
- deleting and recreating a resource to change it.

## Removal and deletion

Treat every removal as a separate high-impact batch. This includes:

- organization, repository, team, or ruleset deletion;
- member, owner, collaborator, or team removal;
- Copilot seat removal;
- runner or application removal;
- disabling security or Actions controls;
- clearing content exclusions or agent sources.

Require the exact resource list, reason, downstream impact, recovery path, and
verification. If recovery is not credible, use a manual handoff.

## Billing

Separate paid changes from technical configuration. Before assigning seats or
enabling a paid product:

- read the current subscription and seat mode;
- list the named recipients or target groups;
- calculate the expected seat delta when the API exposes enough data;
- identify the billing owner;
- state when price or proration is unknown;
- require high-impact approval.

Never represent an unknown charge as zero.

## Repository content

For new repositories, the approved create batch may include initial content.

For existing repositories:

- inspect the default branch and protection rules;
- create a branch;
- write only approved paths;
- open a pull request;
- leave merge approval to the repository's normal controls.

Do not bypass rulesets, required reviews, status checks, signed-commit policy, or
CODEOWNERS.

## Verification

Verify through a separate read when possible. For access controls, verify the
effective permission rather than the configured grant alone.

Use a consenting non-owner account for allowed and denied access tests. Do not
switch to that account without approval, and do not ask for its token.

If only manual verification can prove the result, record
`manual_evidence_required` with an owner and exact evidence request.
