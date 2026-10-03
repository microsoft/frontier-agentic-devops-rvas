# Next feature opportunities agent

## Background

Product evidence often sits across code, issues, and delivery-session feedback.
This workflow reviews that evidence each week and creates one current issue with
specific feature opportunities.

The workflow has read-only access. `safe-outputs` creates a reviewable issue,
and the team decides whether a recommendation becomes planned work.

> [!TIP]
> [Bring your own repo](../../setup.md#bring-your-own-repo): pick a repository for a product the team actively maintains. Confirm with the product owner that recommendation issues will help the team plan its backlog.

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

4. Set the prompt's evidence scope for your product. Name the
   documentation, feature directories, and user-facing interfaces the agent
   should use as sources. Keep the instruction to cite paths and
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

## Hints

If the recommendations are generic, narrow the evidence sources in the
prompt. For example: "Treat `apps/web/src/routes/` and `docs/product/` as the
authoritative feature inventory."

If the agent suggests work already planned, make sure it searches open issues,
and add the labels or milestone that represent committed work to the prompt.

The workflow's `close-older-issues: true` setting retains one current report.
If weekly reports are too frequent, change the schedule to monthly only after
the team agrees.

Keep `create-issue` as
the only safe output. A human should decide whether a recommendation becomes a
backlog item or GitHub Project entry.
