# Access repair result

**No GitHub access was changed.**

On October 9, 2026, I queried `github.com` with each configured account. GitHub returned `NOT_FOUND` for `fabrikam-engineering`, and the active account can see only the enterprise `marcoolivo-msft-emu`. It cannot see enterprise `fabrikam`. The active token has `read:enterprise`, `read:org`, and `repo`, so this is not a missing read-scope error.

Because I could not read the target organization, I could not produce a reliable repository, team, collaborator, or effective-permission inventory. I will not invent an access-change list or remove access without that evidence.

## Batch status

| Batch | Purpose | Status |
|---|---|---|
| 0 | Read-only discovery and access verification | **Attempted; blocked** |
| 1 | Create or update teams and grant replacement access | Not run |
| 2 | Verify effective access before removals | Not run |
| 3 | Remove superseded direct repository grants | Not run |
| 4 | Verify, monitor, and close | Not run |

## Executable plan

Run the following with an enterprise or organization owner account that can see `fabrikam/fabrikam-engineering`. These commands are a plan only; none were executed.

### 1. Capture the current state

```bash
ORG=fabrikam-engineering

gh api "orgs/$ORG" > org.json
gh api --paginate "orgs/$ORG/repos?per_page=100&type=all" > repos.json
gh api --paginate "orgs/$ORG/teams?per_page=100" > teams.json

jq -r '.[].name' repos.json | while read -r repo; do
  gh api --paginate "repos/$ORG/$repo/collaborators?affiliation=direct&per_page=100" \
    > "direct-$repo.json"
done
```

For each repository, also capture team grants and each affected user's effective permission:

```bash
gh api "repos/$ORG/REPO/teams"
gh api "repos/$ORG/REPO/collaborators/USER/permission"
```

The required pre-removal report must contain one row per affected user and repository:

| Repository | User | Current sources | Current effective permission | Replacement team | Proposed permission | Net change | Recovery command |
|---|---|---|---|---|---|---|---|
| _Populate from API results_ | | | | | | | |

### 2. Prepare replacement teams

Use a platform team for shared infrastructure repositories and one team per product squad for squad-owned repositories.

```bash
# Create only if missing.
gh api --method POST "orgs/$ORG/teams" \
  -f name='platform' -f privacy='closed'

gh api --method POST "orgs/$ORG/teams" \
  -f name='PRODUCT-squad' -f privacy='closed'

# Add or confirm team members before changing repository grants.
gh api --method PUT "orgs/$ORG/teams/TEAM/memberships/USER" \
  -f role='member'
```

### 3. Batch 1: grant team access

Grant the platform team `maintain` on shared infrastructure repositories. Grant each product squad `push` on only its own repositories.

```bash
gh api --method PUT "orgs/$ORG/teams/platform/repos/$ORG/SHARED_REPO" \
  -f permission='maintain'

gh api --method PUT "orgs/$ORG/teams/PRODUCT-squad/repos/$ORG/PRODUCT_REPO" \
  -f permission='push'
```

**Approval gate:** review the exact additions and confirm every affected user retains the intended effective permission.

### 4. Batch 2: verify before removal

```bash
gh api "repos/$ORG/REPO/collaborators/USER/permission"
gh api "orgs/$ORG/teams/TEAM/memberships/USER"
gh api "orgs/$ORG/teams/TEAM/repos/$ORG/REPO"
```

Do not continue unless the report proves:

- platform members have `maintain` on shared infrastructure repositories;
- product squad members have `push` only on their squad repositories;
- no proposed removal lowers required access;
- repository administrators and automation identities have an explicit reviewed path.

### 5. Batch 3: remove superseded direct grants

Remove direct grants only after Batch 2 is approved.

```bash
gh api --method DELETE "repos/$ORG/REPO/collaborators/USER"
```

Use small batches grouped by repository. Re-run the effective-permission query after every batch.

### 6. Recovery path

The snapshot must record the original direct permission for every removal. Restore it with:

```bash
gh api --method PUT "repos/$ORG/REPO/collaborators/USER" \
  -f permission='ORIGINAL_PERMISSION'
```

If a team grant is wrong, restore access first, verify it, then correct the team mapping. Keep the original direct grants until replacement access has passed verification.

## Required next condition

Retry with an account that can resolve both enterprise `fabrikam` and organization `fabrikam-engineering`. Until then, the only safe result is the read-only blocked assessment above.
