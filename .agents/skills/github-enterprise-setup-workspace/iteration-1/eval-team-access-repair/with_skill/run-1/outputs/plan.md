# GitHub Enterprise setup plan

## Outcome

Repair repository access in `fabrikam-engineering`. The platform team should maintain shared infrastructure repositories. Product squads should have write access only to their own repositories.

## Target and authority

- Host: `github.com`
- Enterprise candidate: `fabrikam`
- Organization candidate: `fabrikam-engineering`
- Active actor: `admin_olivoemu`
- State: **blocked before access discovery**

The enterprise query returned `NOT_FOUND`. The organization read returned HTTP 404, and GitHub CLI reported that the operation needs `admin:org`. These results do not prove that either target is absent.

## Confirmed capability checklist

- Identity and authority
- Organization base permission and inherited policy source
- Team hierarchy, membership, and repository grants
- Direct and outside collaborator grants
- Repository visibility
- Per-person effective access

## Current effective state

Unknown. The current authorization cannot inspect the target. I will not infer access from an ambiguous 404.

## Decisions

No access decision is safe until read-only discovery succeeds. No write command has been generated.

## Proposed batches

1. **Corrective team grants:** add or fix the platform and squad grants before removing direct access.
2. **Effective-access check:** calculate the highest applicable permission for every affected person and repository.
3. **Direct-access removals:** treat each removal as high impact. Show the exact before-and-after permission, source grants, impact, and recovery command first.
4. **Acceptance checks:** confirm platform `maintain` access on shared infrastructure repositories, squad `write` access only on owned repositories, and expected denied writes using consenting non-owner accounts.

## High-impact changes

The removal batch needs separate typed approval naming the batch and targets. A generic approval is not enough. The batch must include an exact resource list and a recovery command for every removed grant.

## Billing and licenses

No billing or license change is planned.

## Manual handoffs

None yet. A manual handoff may be required if the active actor lacks enterprise or organization authority after authorization is refreshed.

## Verification

Read back organization policy, team grants, direct grants, and effective collaborator permission after each operation. Stop on stale targets, changed policy sources, or unexpected permissions.

## Resume command

After approval, run:

```bash
gh auth refresh --hostname github.com --scopes admin:org
```

Then resume this assessment with the same host, enterprise, organization, and output directory. Recheck the active actor before any discovery or write.
