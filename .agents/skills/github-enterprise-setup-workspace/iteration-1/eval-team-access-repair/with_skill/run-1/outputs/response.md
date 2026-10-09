# Access repair status

**Blocked before planning. No GitHub writes or access removals ran.**

I verified the active `github.com` identity as `admin_olivoemu`. Its token has `read:enterprise`, `read:org`, and `repo`, but the `fabrikam` enterprise query returned `NOT_FOUND`. Reading `fabrikam-engineering` returned HTTP 404, and GitHub CLI reported that `admin:org` is required. An ambiguous 404 does not prove the target is missing.

I saved a redacted assessment and a blocked plan. The eventual order is: add corrective team grants, verify effective access, remove approved direct grants as a separate high-impact batch, then run acceptance checks. Before any removal, the plan will show every person and repository, current permission sources, exact effective permission before and after, impact, and the command that restores the removed grant. Each removal batch needs separate typed approval.

**Recommended next step:** approve a scope refresh for the current account, then rerun read-only discovery. This adds the broad `admin:org` OAuth scope to the active GitHub CLI authorization; it does not itself change organization access.

**Do you approve running `gh auth refresh --hostname github.com --scopes admin:org` for `admin_olivoemu`, followed by read-only discovery of `fabrikam` and `fabrikam-engineering`?**

Artifacts:

- `assessment.json`
- `plan.md`
- `plan.json`
