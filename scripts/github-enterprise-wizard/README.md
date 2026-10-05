# GitHub enterprise setup wizard

**Configure a customer workspace from a reviewed plan.** The wizard uses Bash 3.2+,
`gh`, and `jq` on macOS or Linux. It supports Enterprise Cloud on `github.com`
and customer `ghe.com` domains. Git and a SHA-256 utility are also required.

It does not provision the curriculum's lab fixtures or deploy external cloud
infrastructure. The website's session builder remains a curriculum selector.

## Start

Authenticate to the intended host using customer-managed credentials. The saved
configuration names the expected GitHub login; the wizard refuses a different
identity. Tokens stay in `gh` authentication or the runtime environment.

```bash
gh auth login --hostname github.com
bash scripts/github-enterprise-wizard.sh init --output "$HOME/github-setup.json"
bash scripts/github-enterprise-wizard.sh doctor --config "$HOME/github-setup.json"
bash scripts/github-enterprise-wizard.sh plan \
  --config "$HOME/github-setup.json" --output "$HOME/github-plan.json"
```

In a terminal, `init` shows **one question per page**. The header shows the
current section out of six and the question number. Allow roughly 5-10 minutes
for one starter project; extra packages or organizations take longer. This
estimate covers the interview, not provisioning.

Move through menus with Up/Down and toggle checklists with Space.
**Enter or Right advances; B or Left goes back.** Returning to a page restores
your selection, including checkboxes. Right keeps it and moves forward.
E opens the answer editor. **In the editor, Enter edits the selected answer;
Right or Left returns without editing.** Esc cancels from a menu; Ctrl+C stops anywhere.
Cancelling before Save leaves the output file untouched.

Text fields show saved answers as defaults. Enter or Right accepts the current
input, or keeps the default when blank. **Enter `:clear` to empty an optional
saved field.** Use Ctrl+F to move the text cursor right; enter `:back` or `:edit`
for navigation. Earlier answers stay saved during the
interview. Changing one resets later choices so they cannot carry settings from
a different account or organization. Invalid attempts are not saved and do not
discard later answers. Required fields reject blank or whitespace-only input.

Malformed names, recipient lists, billing emails and approval counts retry at
the same question. Copied agents need readable local Markdown files without
literal GitHub credentials. Cross-field errors still appear at final review.

`init` uses bounded, read-only lookups to suggest the active username, other
saved accounts, and accessible enterprises. It also lists organizations in the
selected enterprise and repositories when you choose adoption. Results are
cached for the interview. Failed lookups leave manual input available.
**The wizard never switches accounts.** Selecting a different login skips
resource discovery and shows the account-switch command to run yourself.

Workspace, Actions with Codespaces, Code Security, and Code Quality start
selected. Their feature prompts also default to enabled. Required packages are
included automatically. A new project can use the default Developers team and
`service` repository, with a Node.js starter and working CI.
You can change those names or choose Python or a customer template.
Duplicate resources must be corrected before continuing. New organizations skip
existing-repository adoption. Bundled CI and gh-aw exclude organization-only
Actions policies because they need GitHub-owned actions. Shared member profiles
are written only to the private `.github-private` repository.

The shared organization baseline gives members read access by default. Members
can create private or internal repositories, but not public repositories. They
cannot fork private repositories, delete repositories, or change visibility.
Private Pages sites remain available, web commits require signoff, and visible
teams are used unless the configuration says otherwise. The plan also flags
organizations with fewer than two recorded owners.

The configuration also carries an **enterprise policy baseline**. The plan
applies GitHub Actions permissions, fork safeguards, artifact retention,
repository-runner restrictions, Codespaces access, enterprise 2FA, custom
properties, and an Evaluate-mode enterprise ruleset. It exports PAT, audit,
Codespaces, app, and 2FA-readiness inventories before related changes.

`init` asks for explicit confirmation before it includes risky controls. The
prompt explains the expected impact. PAT policy, Codespaces constraints,
personal-account offboarding, and app approval remain attestable owner
handoffs because GitHub does not expose supported write APIs for those settings.
Codespaces access and enterprise 2FA use supported APIs after confirmation.
Enterprise 2FA and offboarding are never applied to EMU.

The baseline does **not** configure domain restrictions, IP allow lists,
Conditional Access, hosted runner private networking, or Copilot usage-record
streaming.

Feature choices use **Enable Yes/No**, with no separate cost confirmations.
Enabling Copilot seats requires named users or teams. Enabling security features
or Code Quality also selects any required licensing handoff; Code Quality includes
its live analysis. Billing details stay in the plan, which needs one approval
before apply. Blank Copilot recipient lists still allow content setup.
Copilot defaults enable MCP, released models, GitHub.com, CLI, cloud-agent pilots,
and Balanced code review. Kimi and Claude Fable stay disabled unless the operator
confirms their separate model-risk or data-retention requirements. Copilot
approvals do not count as human approvals. Shared Copilot setup writes
`copilot/managed-settings.json` with auto model selection, bypass mode disabled,
and only built-in MCP servers allowed until administrators approve more. It also
adds four manually selected enterprise agents:

- **Security Reviewer** reports supported security findings without editing files.
- **CI Investigator** diagnoses failed builds and tests without changing code.
- **Test Author** writes focused tests but cannot change production files.
- **Documentation Maintainer** updates docs from verified repository behavior.

The agents use small tool allowlists and cannot run automatically from model
inference. Administrators can edit or replace them in `.github-private`.
When shared Copilot content is selected, the plan sets that organization as the
enterprise custom-agent source and asks GitHub to create the protective agent
ruleset. Apply verifies the selected organization and `.github-private`
repository.
Existing-resource adoption remains explicit. Managed
users cannot select public repositories; SHA-pin enforcement defaults off for
existing organizations until their workflows have been reviewed. Actions use
read-only workflow tokens, cannot approve pull requests, and retain artifacts
and logs for 90 days.

The security baseline creates an enforced organization configuration for
dependency graph, Dependabot alerts and security updates, CodeQL default setup,
secret scanning, push protection, validity checks, broader secret patterns,
AI-detected secrets, and private vulnerability reporting. It also generates
dependency review for supported starter stacks and security-overview reports.
GitHub must assign the configuration ID before the wizard can set it as the
default for new repositories or attach it to existing repositories, so the plan
records those owner steps. Delegated push-protection bypass also stays pending
until a reviewer team or role ID is selected.

Default-branch rules block high-severity CodeQL findings after analysis is ready.
Code Quality starts with an error-level rule in **Evaluate** mode. Review its
ruleset insights before changing that rule to Active. Coverage thresholds remain
unset until repositories upload real coverage data.

The interview ends with a configuration summary and the exact `doctor` and
`plan` commands to run next. If validation fails, section 6 shows the exact error
and offers **Fix an answer** or **Cancel interview without saving**. Saving stays
blocked until the error is fixed. The wizard changes no GitHub settings. Use
`init --no-discovery` for an offline interview or `init --plain` for numbered
text choices with scrollable output instead of clean pages. Exact option values
take precedence over item numbers. Redirected input is
offline and uses text prompts. Set `NO_COLOR`
to disable color while keeping keyboard controls.
Keyboard menus need at least 16 rows and 20 columns; use `--plain` in smaller terminals.

Use the example configuration beside this guide for non-interactive setup.
JSON is validated before planning; unknown fields are errors. Organizations can
override shared defaults. The catalogue lists the package choices and their
curriculum references:

```bash
bash scripts/github-enterprise-wizard.sh catalog
```

Confirm the declared account type in enterprise settings. The API checks the
authenticated identity and enterprise membership, but that does not establish
the enterprise's identity model or legal compliance.

## Review and apply

Read the complete plan, including its file contents and purchase recipients.
The summary printed by `plan` shows operation IDs and decisions. Existing
resources require explicit adoption before updates; matching settings do not
authorize unrelated changes.

```bash
bash scripts/github-enterprise-wizard.sh apply \
  --plan "$HOME/github-plan.json" --run "$HOME/github-setup-run"
```

Interactive apply asks for the plan's exact digest. In CI, pass that digest:

```bash
DIGEST="$(jq -r .digest "$HOME/github-plan.json")"
bash scripts/github-enterprise-wizard.sh apply \
  --plan "$HOME/github-plan.json" --run "$HOME/github-setup-run" \
  --approve "$DIGEST"
```

**Approval includes the plan's selected purchases and live runs.** The plan shows
billing warnings when pricing or usage is not known; it adds no separate cost
confirmation. Only selected supported purchases run. Subscription enablement
without a supported API remains an owner handoff.

Plans are bound to their contents and the wizard implementation. Generate a new
plan after changing configuration or updating the wizard. A digest detects
changes; it is not a digital signature or an authorization system.

The run directory stores the approved plan and an atomic ledger. It may contain
customer configuration and reports; keep it outside source control. New files
use private permissions. No tokens or raw API error bodies are recorded.

## Existing resources

Choose adoption explicitly. Updates change the selected settings, preserving
unrelated ones. Existing repository content is proposed through pull requests;
it becomes ready after merge and content verification. New repositories receive
their approved initial content directly.

Repository templates do not copy access, rulesets, or protected environments.
The workspace adapters apply those separately. Node.js and Python
starters include working checks; other stacks can use customer templates.

An inaccessible API resource is not treated as an empty result. A 404 can mean
missing access; creation also requires the approved organization scope and an
explicit creation operation. Resources that appear after planning need a new
adoption plan. Template source commits are recorded and checked before creation.

## Packages and boundaries

The catalogue covers workspace setup, Actions, access governance, Copilot,
Code Security, and Code Quality. It also includes gh-aw and the curriculum's
migration/integration and operating capabilities.

The adapters apply supported GitHub settings and export selected reports.
External or UI-only work becomes a named handoff. Some advanced operations need
customer-supplied settings or workflow content; selecting a package alone does
not invent those values.

- A root enterprise account must already exist. `doctor` verifies that the
  authenticated account can access it before planning. Organization creation
  uses GraphQL under that enterprise.
- Any required SSO and SCIM setup must already be complete. The wizard does not
  inspect, configure, verify, or create handoffs for it.
- Cloud-side OIDC trust and runner compute stay outside this script.
- Copilot selected-seat purchases need an enabled subscription and selected-seat
  management. Feature/model policies can require an owner in the UI.
- `.github-private` is a real shared configuration repository. The wizard can
  set its organization as the enterprise custom-agent source after the files
  are ready.
- Code Quality is separate from CodeQL and Copilot review. Product entitlement
  and analysis completion are prerequisites for its gates.
- Installed gh-aw tooling compiles source during planning so generated locks
  are included in approval. Missing tooling or compiler prerequisites stay
  pending. Documentation and test pilots produce reports rather than write
  files. No extension is installed automatically.
- Migration tools and source-system permissions need customer setup. An
  inventory export does not claim that a migration completed.

And a budget is not a universal hard spending limit. Check the product's billing
behavior before approving purchases or live workflow usage.

## Resume and verify

```bash
bash scripts/github-enterprise-wizard.sh status --run "$HOME/github-setup-run"
bash scripts/github-enterprise-wizard.sh resume \
  --run "$HOME/github-setup-run" --approve "$DIGEST"
bash scripts/github-enterprise-wizard.sh verify --run "$HOME/github-setup-run"
```

Independent packages continue when another fails. Dependents wait. Live dispatch
and purchase attempts are recorded before sending the request; an uncertain
response is reconciled rather than blindly repeated. Concurrent matching
workflow runs remain unverified when the wizard cannot identify its own run.

Verification reads configuration and checks already-dispatched workflows. It
does not purchase seats or start another run. Reports refresh through read-only
calls. A crashed process can leave `.lock`; check that no process is using the
run before removing that specific directory.

| Result | Meaning |
|---|---|
| `ready` | The action's read-back or live check succeeded |
| `unverified` | A write/run needs further verification |
| `pending` | Adoption, review, or an owner/external prerequisite is outstanding |
| `unsupported` | No verified executor is available |
| `failed` | An operation failed or state changed after planning |
| `attested` | The operator supplied external completion evidence; not API-verified |

Exit codes are **0** for a saved configuration or when every action is ready or
attested, **1** for a stopped interview, **2** for failure or invalid input in
other commands, and **3** for incomplete work. Ctrl+C returns **130**.
A successful configuration read
does not prove that users can access every client or that an external service
works.

For a completed manual handoff, record a credential-free HTTPS evidence URL:

```bash
bash scripts/github-enterprise-wizard.sh attest \
  --run "$HOME/github-setup-run" --action "ACTION_ID_FROM_STATUS" \
  --evidence "https://github.com/customer/project/issues/123" \
  --approve "$DIGEST"
```

Manual actions can be attested. A Code Quality analysis can also use external
evidence when its configuration is verified but the API returned no run ID.
Tracked runs still require automatic verification. Query strings and embedded
credentials are rejected. Resume after recording evidence to unblock dependents.

## Development

```bash
npm run test:wizard
/bin/bash -n scripts/github-enterprise-wizard.sh
```

Tests invoke the real Bash script with `jq` and a fake `gh`. They do not contact
customer accounts, purchase seats, or dispatch live workflows. CI includes
macOS system Bash and Linux. Live customer checks require approval of their
own saved plan; this repository's test workflow never provisions an account.
The keyboard tests use Python 3's standard-library pseudo-terminal support.
Python is needed for these tests, not for running the wizard.
