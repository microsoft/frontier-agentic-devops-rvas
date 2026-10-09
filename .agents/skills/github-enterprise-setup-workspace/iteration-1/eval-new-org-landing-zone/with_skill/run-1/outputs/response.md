# GitHub Enterprise setup: assessment blocked

**Mode:** Plan  
**Target:** `contoso` on `github.com`  
**Requested organization:** `contoso-payments`  
**GitHub changes made:** None

## Live assessment

The active GitHub CLI identity is `admin_olivoemu`. Authentication to `github.com` works, and the token reports `read:enterprise`, `read:org`, `repo`, and `workflow` scopes.

The account cannot see enterprise `contoso`. Its visible enterprise list contains only `marcoolivo-msft-emu`, and a direct GraphQL lookup for `contoso` returned `NOT_FOUND`. I recorded this as **insufficient permission**, not as evidence that the enterprise is absent.

The lookup for `contoso-payments` returned HTTP 404 and reported that `admin:org` is required. That result is ambiguous: the organization may not exist, or it may be hidden from this identity. I recorded its state as **unverified**.

I stopped there. Without verified access to `contoso`, I cannot inspect inherited policy, organization-creation authority, Actions defaults, security entitlements, or Copilot billing.

The redacted assessment is saved in `assessment.json`.

## Proposed capability checklist

| Area | Why it is included | Discovery needed before planning |
|---|---|---|
| Organization | Create the `contoso-payments` boundary for about 45 engineers | Creation authority, owners, identity model, repository defaults, enterprise constraints |
| Teams and access | Add `platform`, `backend`, and `frontend` teams | IdP or enterprise-team source, membership ownership, base permission, repository grants |
| Repository factory | Create a private service repository from the golden template | Template owner/name, template access, default branch, rulesets, standard files |
| Actions | Set workflow tokens to read-only | Enterprise and organization policy source, allowed Actions, fork policy |
| Code security | Enable CodeQL and secret scanning | Product entitlements, security configurations, push protection, expected scan evidence |
| Copilot | Assign access to backend and frontend teams | Subscription, team assignment support, existing seats, estimated seat delta, billing owner |

Copilot seat assignment will be a **separate high-impact batch** because it may add recurring cost. The plan will name the recipient teams, current assignments, estimated seat change, and billing owner before requesting approval.

## Next interview question

**Is `admin_olivoemu` the intended enterprise-owner identity for `contoso`?**

**Recommended answer:** Use an account that is already an enterprise owner for `contoso`. This avoids adding broad organization administration scope to the wrong identity and lets the next assessment distinguish missing resources from hidden ones.

If `admin_olivoemu` is the correct owner, the next step would require explicit approval before running:

```bash
gh auth refresh --hostname github.com --scopes read:enterprise,read:org,admin:org
```

If another already-authenticated account owns `contoso`, the safer next step is to approve switching to that named account with `gh auth switch`, then repeat the read-only assessment.
