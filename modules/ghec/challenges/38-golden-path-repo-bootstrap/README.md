# Ch38: Golden-path repository bootstrap

**Session outcome:** A maintained repository template contains a working application, real CI, and clear setup instructions. Organization rules protect repositories that use this baseline.

## Prerequisites

Use an existing, approved starter repository and an organization owner who can configure rulesets. Bring a working application with tests and a build; Ch04 provides the CI setup if needed. You need `gh`, Git, and an independent reviewer.

**This session prepares the template.** Ch36 installs the approved request-to-repository automation.

## Tasks

### Part A: Prepare the starter

1. Choose the customer starter application. Remove customer data and credentials before sharing it with other teams. Grubify is suitable if it is the customer's approved starting point.
2. Follow its README from a clean checkout. Run the actual tests and build. Fix missing setup instructions or dependencies.
3. Keep those commands in its CI workflow. Include `pull_request` and, if used, `merge_group` triggers. Remove hardcoded repository names.
4. Add a PR template and `.github/CODEOWNERS` naming the team that will maintain the baseline. Explain how a consuming team replaces that ownership entry. Do not copy secrets or environment credentials into the template.
5. Open a small PR that deliberately fails an existing test. Confirm CI fails, fix the test, and merge after independent review.

### Part B: Apply the baseline

With the organization owner, configure the Ch08 organization ruleset to cover the template and future application repositories:

- Require a PR with at least one independent approval.
- Require the starter's actual CI check names on the default branch.

Use a target that covers future repositories without a manual settings step, such as all repositories or the approved team-name prefixes. Keep the provisioning App out of the branch-ruleset bypass list. A repository-creation exception does not justify bypassing code review.

Inspect the rules applying to the template:

```bash
export TEMPLATE="YOUR-ORG/YOUR-TEMPLATE"
export DEFAULT_BRANCH="$(gh repo view "$TEMPLATE" --json defaultBranchRef --jq '.defaultBranchRef.name | @uri')"
gh api "repos/$TEMPLATE/rules/branches/$DEFAULT_BRANCH"
```

Have a normal contributor confirm a failing check blocks merging and a passing check still needs independent review. Restrict changes to the template through the same reviewed path.

### Part C: Publish the reviewed template

After the PR merges, mark the existing repository as a template:

```bash
gh api --method PATCH "repos/$TEMPLATE" -F is_template=true
gh repo view "$TEMPLATE" --json isTemplate,defaultBranchRef
gh api "repos/$TEMPLATE/commits/HEAD" --jq '{commit: .sha, tree: .commit.tree.sha}'
```

Record the reviewed commit and required CI check names for Ch36. Template generation copies the current default branch. Ch36 refuses creation if that branch has moved from the approved commit.

Name the template maintainer in the README. Template updates go through PR review; the maintainer then updates the approved commit in the intake configuration. Existing application repositories do not automatically receive template changes. Use a reviewed PR when they need an update.

Keep the template URL and the failing-then-passing PR as [completion evidence](../../../README.md#completion-evidence). Repository creation and team grants belong to Ch36.

## References

- [Creating a template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository)
- [Organization rulesets](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/creating-rulesets-for-repositories-in-your-organization)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
