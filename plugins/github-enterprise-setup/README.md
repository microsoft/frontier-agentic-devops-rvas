# GitHub Enterprise setup

An Agent Plugins 1.0 package for setting up an existing GitHub Enterprise Cloud
account on `github.com` or a customer `ghe.com` host. The skill uses GitHub CLI
directly. It has no MCP server or setup script.

**Preview:** packaging and offline workflow checks are tested. A controlled live
setup journey is still required before production use.

## Install

You need GitHub Copilot CLI installed and signed in, GitHub CLI (`gh`), and `jq`.
Authenticate `gh` to your target host with an account that can read the selected
resources. Planned changes may need enterprise or organization owner permissions.

After this package is published to the repository:

```bash
copilot plugin marketplace add microsoft/frontier-agentic-devops-rvas
copilot plugin install github-enterprise-setup@frontier-agentic-devops
copilot skill list
```

Check that `github-enterprise-setup` appears under the plugin source. Start a new
Copilot session in the directory where you want to work:

```bash
copilot
```

Replace the placeholders and send this prompt:

```text
Use the github-enterprise-setup skill to set up enterprise <enterprise-slug>
on <host>, covering organizations <org-slugs>.
My goal is <outcome>. Assess current state and recommend changes.
Ask only for unresolved decisions. Save a plan without changing GitHub.
```

**This starts Plan.** The agent gathers scoped evidence and asks one decision at
a time. It saves recommendations and proposed changes in a private run directory
outside your repository by default.

## Review and continue

Read the saved plan before requesting Apply. "Proceed" starts the approval
process; each write batch still needs approval. High-impact changes need separate
typed confirmation. Authentication changes also need approval.

Required read-only inventories within your requested scope run without an extra
skill-level approval question. Copilot's tool permissions and organization
policies still apply.

For a report only, ask:

```text
Use the github-enterprise-setup skill in Assess mode for enterprise
<enterprise-slug> on <host>, covering <scope>. Report gaps and prioritized
recommendations. Do not create a change plan or change GitHub.
```

To continue saved work in a new conversation:

```text
Use the github-enterprise-setup skill to resume the run at <absolute-run-path>.
Recheck identity and live state before continuing.
```

The agent reuses known context in the same conversation. It asks for the run path
when it is unknown rather than choosing a run by age.

**Legacy wizard runs are incompatible.** Keep those files for reference. Start a
new Plan with fresh discovery; an old wizard approval does not approve skill
changes.

## Update or remove

```bash
copilot plugin marketplace update frontier-agentic-devops
copilot plugin update github-enterprise-setup
```

To remove the plugin:

```bash
copilot plugin uninstall github-enterprise-setup
```

## Develop and validate

The canonical source is `skills/github-enterprise-setup/`. The repository's
`.agents/skills/github-enterprise-setup` link points to it for local discovery.
Edit the canonical source, including its tracked offline evaluations. Keep
generated evaluation results in the ignored authoring workspace.

From the repository root:

```bash
npm run test:setup-plugin
copilot plugin marketplace add .
copilot plugin install github-enterprise-setup@frontier-agentic-devops
```

A local-directory marketplace loads the source live in a new session. For a
cached packaging check, `copilot plugin install ./plugins/github-enterprise-setup`
still works but direct installs are deprecated; reinstall after editing.

**Test outside this repository** so the project skill cannot hide a broken
package. Use a separate `COPILOT_HOME` for smoke tests to leave your normal
plugin configuration unchanged. Check the installed skill source and all bundled
references. Then test Assess, Plan, an approved low-risk Apply, and Resume against
a controlled enterprise before claiming live end-to-end validation.

Publish the marketplace and plugin together before sharing the remote install
commands. No marketplace registration or enterprise changes happen when this
repository is cloned.

See GitHub's [plugin authoring guide](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating)
and [marketplace guide](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace)
for the distribution format. [MIT license](LICENSE).
