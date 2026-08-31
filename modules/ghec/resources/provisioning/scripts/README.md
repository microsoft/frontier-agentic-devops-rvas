# `scripts/`: Provisioning scripts

> This shared engine creates the starting state for one activity. Every artifact
> uses the `ghec-<chid>-*` namespace. Provisioning is idempotent and supports
> dry runs; teardown refuses artifacts outside that namespace.

## What lives here

| File | Purpose |
|---|---|
| `setup.sh` | Bash entrypoint (macOS / Linux). |
| `setup.ps1` | PowerShell entrypoint (Windows / cross-platform `pwsh`). |
| `versions.lock` | Pinned versions (Juice Shop `v20.0.0`, min `gh`). Canonical version list. |
| `lib/*.sh` / `lib/*.ps1` | Shared helpers: `log`, `common` (dry-run + meta reader), `auth`, `guards`, `gh`, `juice-shop-import`. |
| `../challenges/<chid>-<slug>/provision.sh` | Per-activity provisioning logic (`.ps1` twin alongside). |

## Prerequisites

- `gh` (GitHub CLI ≥ 2.0), `git`, and `jq` on your `PATH`.
- Org-owner access to the target org. The minimum input is always an org. No activity requires an enterprise owner as its minimum input.
- Run `doctor` first; it verifies all of the above and prints the exact token scopes for the activity you picked.

## Authentication (no token ever touches your shell history)

Authenticate with the device flow or set an environment variable. Never pass a token as a CLI argument.

```bash
gh auth login                 # interactive device flow (recommended)
# or:
export GH_TOKEN=...           # set in your environment, not as a flag
```

The scripts read authentication through `gh`. They do not provide a `--token` flag.

If `doctor` or `provision` reports missing scopes for Projects v2 operations, refresh scopes in place:

```bash
gh auth refresh -h github.com -s project,read:project
```

## Command surface

```
# Bash
./setup.sh <doctor|provision|status|teardown> <ch##> --org <org> \
    [--enterprise <slug>] [--ref <juiceShopRef>] [--dry-run] [--yes]

# PowerShell
./setup.ps1 <doctor|provision|status|teardown> <ch##> -Org <org> `
    [-Enterprise <slug>] [-Ref <juiceShopRef>] [-DryRun] [-Yes]
```

| Command | Does |
|---|---|
| `doctor` | Verifies `gh`/`git`/`jq`, auth, and the activity's `requires`; prints minimum token scopes; warns without blocking on metered cost and on EMU for `ch19`. Changes nothing. |
| `provision` | Creates all `ghec-<chid>-*` starting state. Idempotent — re-run to reconcile (create-if-absent). |
| `status` | Reports which `ghec-<chid>-*` artifacts currently exist. |
| `teardown` | Deletes only `ghec-<chid>-*`. Requires confirmation (type the activity ID) unless `--yes`. |

### Examples

```bash
./setup.sh doctor    ch01 --org acme-co            # preflight
./setup.sh provision ch01 --org acme-co --dry-run  # preview the plan, no changes
./setup.sh provision ch01 --org acme-co            # actually create
./setup.sh status    ch01 --org acme-co            # what exists?
./setup.sh teardown  ch01 --org acme-co            # delete (confirm), or add --yes
```

## Namespacing and teardown safety

- Every created resource is prefixed `ghec-<chid>-*` (e.g. `ghec-ch01-issues-labels-projects`, `ghec-ch12-juice-shop`).
- `teardown` calls `guard_prefix` before every deletion. It refuses any name that does not start with `ghec-<chid>-`, which protects pre-existing customer repositories and projects.
- `--dry-run` routes every mutation through a planner that prints `[plan] would run: …` and changes nothing. Use it first against a customer org.
- `provision` only creates missing state and is idempotent. `teardown` is the only destructive path. It checks the prefix and asks for confirmation.
- Some platform/admin changes (audit settings, org policies) can't be cleanly reverted by script — those activities document manual cleanup in their `README.md`.

## Juice Shop import (GHAS activities)

`app: juice-shop` activities import OWASP Juice Shop at the pinned ref (default `v20.0.0` from
`versions.lock`; override per-activity in `meta.yml` or with `--ref`). The importer shallow-clones
the tag, strips history, fresh-inits, and pushes to a public `ghec-<chid>-juice-shop` repo.
Juice Shop is MIT-licensed. The import preserves its `LICENSE` and never vendors the project into this repository.

## Authoring a new activity provisioner (the contract)

`setup.sh` reads `challenges/<chid>-<slug>/meta.yml` (`app`, `requires`, `provision_creates`,
`juice_shop_ref`), then sources `challenges/<chid>-<slug>/provision.sh` and calls into it.

Each `provision.sh` must define exactly three functions:

```bash
ghec_provision    # create-if-absent, idempotent, dry-run aware
ghec_teardown     # delete ONLY ghec-<chid>-* (call guard_prefix first)
ghec_status       # report what currently exists
```

`setup.sh` exports for you: `ORG CHID SLUG APP JUICE_SHOP_REF DRY_RUN ASSUME_YES NAMESPACE REPO META`,
and the lib helpers are in scope: `log_*`, `run_mutation`, `gh_*`, `guard_prefix`, `meta_*`,
`juice_shop_import`. The PowerShell twin (`provision.ps1`) defines `Invoke-GhecProvision` /
`Invoke-GhecTeardown` / `Invoke-GhecStatus` and uses the `$Global:Ghec*` globals.

`ch01` is the worked reference — copy its `provision.sh` / `provision.ps1` shape for new activities.

Rules every provisioner upholds: route mutations through `run_mutation` / `Invoke-GhecMutation`;
check-then-create for idempotency; name everything `ghec-<chid>-*`; `guard_prefix` before any delete.

See [../CONTRIBUTING-BUILD.md](../CONTRIBUTING-BUILD.md) for the full build contract.
