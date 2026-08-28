# Next Feature Opportunities Agent

Track: Production Patterns (Advanced)
Estimated time: 30 minutes
Tier: Core

---

## Background

Teams often have code, requests, and delivery-session feedback spread across a
repository without a repeatable way to turn that evidence into an ordered
product-improvement conversation. This workflow reviews repository evidence on
a weekly schedule and creates one current issue with only grounded,
actionable feature opportunities.

The workflow is intentionally read-only. It cannot edit the product or
backlog directly: `safe-outputs` creates a reviewable issue, and the team
decides whether to turn any recommendation into planned work.

> [!IMPORTANT]
> Bring your own repository first
>
> Select a repository where the code, documentation, and issue tracker together
> represent a product that a team actively maintains. Agree with the product
> owner that an automated recommendation issue is an appropriate input to
> backlog refinement. A sample repository is useful only to learn the mechanics;
> the intended outcome is a recommendation process the customer can continue
> using.

## What you'll do

1. Install and verify `gh aw` using the [GHAW setup guide](../../setup.md).

2. Copy the workflow into the repository you selected:

   ```bash
   gh aw add https://raw.githubusercontent.com/microsoft/frontier-agentic-devops-rvas/main/.github/workflows/next-feature-opportunities.md
   ```

3. Read `.github/workflows/next-feature-opportunities.md`. Confirm it:
   - runs weekly and can be run manually;
   - has only `contents: read` and `issues: read` permissions;
   - uses `repos`, `issues`, and `labels` GitHub toolsets;
   - creates no more than one report and closes an older report after a new one
     is created.

4. Tailor the evidence scope in the prompt to your product. Name the
   documentation, feature directories, and user-facing surfaces that are
   authoritative in your repository. Keep the instruction to cite paths and
   issue references.

5. Compile the source Markdown into the deployable GitHub Actions workflow:

   ```bash
   gh aw compile next-feature-opportunities
   ```

6. Dry-run it before enabling it:

   ```bash
   gh aw run next-feature-opportunities --dry-run
   ```

7. Run it manually from the Actions tab. Review the recommendation issue with
   the product owner. Convert only accepted opportunities into normal backlog
   issues or add them to the team's GitHub Project.

8. Commit both the source workflow and the generated lock file:

   ```bash
   git add .github/workflows/next-feature-opportunities.md \
     .github/workflows/next-feature-opportunities.lock.yml
   git commit -m "Add next feature opportunities workflow"
   ```

## Definition of done

- [ ] The source Markdown and compiled `.lock.yml` workflow files are present.
- [ ] The agent has only read access to repository contents and issues.
- [ ] Every published recommendation identifies supporting paths or issue
  references.
- [ ] The workflow publishes at most one current recommendation report and
  avoids opening a report when there is no material, untracked opportunity.
- [ ] The product owner has reviewed the first output and recorded which, if
  any, recommendations will enter the delivery backlog.

## Hints

**The recommendations are generic.** Narrow the evidence sources in the
prompt. For example: “Treat `apps/web/src/routes/` and `docs/product/` as the
authoritative feature inventory.”

**The agent suggests work already planned.** Make sure it searches open issues,
and add the labels or milestone that represent committed work to the prompt.

**A weekly issue feels noisy.** The workflow's `close-older-issues: true`
setting retains one current report. Change the schedule to monthly only after
the team has agreed that weekly review is not useful.

**The report should not create work automatically.** Keep `create-issue` as
the only safe output. A human should decide whether a recommendation becomes a
backlog item or GitHub Project entry.
