# scripts/ — wth Provisioning CLI

> Owned by **Yen** (Automation Engineer). This is the shared engine that stands up the
> starting state for any single challenge inside **your own org**. One challenge per run,
> everything namespaced `wth-<chid>-*`, idempotent, dry-run aware, and prefix-guarded so
> teardown can never touch anything that isn't ours.

## What lives here

| File | Purpose |
|---|---|
| `setup.sh` | Bash entrypoint (macOS / Linux). |
| `setup.ps1` | PowerShell entrypoint (Windows / cross-platform `pwsh`). |
| `versions.lock` | Pinned versions (Juice Shop `v20.0.0`, min `gh`). Single source of truth. |
| `lib/*.sh` / `lib/*.ps1` | Shared helpers: `log`, `common` (dry-run + meta reader), `auth`, `guards`, `gh`, `juice-shop-import`. |
| `../challenges/<chid>-<slug>/provision.sh` | Per-challenge provisioning logic (`.ps1` twin alongside). |

## Prerequisites

- **`gh`** (GitHub CLI ≥ 2.0), **`git`**, and **`jq`** on your `PATH`.
- **Org-owner access** to the target org. The minimum input is always an **org** — never anything stricter (no enterprise-owner requirement).
- Run `doctor` first; it verifies all of the above and prints the exact token scopes for the challenge you picked.

## Authentication (no token ever touches your shell history)

Authenticate with the device flow, or set an env var — **never** pass a token as a CLI argument:

```bash
gh auth login                 # interactive device flow (recommended)
# or:
export GH_TOKEN=...           # set in your environment, not as a flag
```

The scripts read auth purely through `gh`. There is no `--token` flag anywhere, by design.

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
| `doctor` | Preflight only. Verifies `gh`/`git`/`jq`, auth, the challenge's `requires`, prints **minimum token scopes**, and warns (never blocks) on metered cost and on EMU for `ch19`. Changes nothing. |
| `provision` | Creates all `wth-<chid>-*` starting state. **Idempotent** — re-run to reconcile (create-if-absent). |
| `status` | Reports which `wth-<chid>-*` artifacts currently exist. |
| `teardown` | Deletes **only** `wth-<chid>-*`. Requires confirmation (type the challenge id) unless `--yes`. |

### Examples

```bash
./setup.sh doctor    ch01 --org acme-co            # preflight
./setup.sh provision ch01 --org acme-co --dry-run  # preview the plan, no changes
./setup.sh provision ch01 --org acme-co            # actually create
./setup.sh status    ch01 --org acme-co            # what exists?
./setup.sh teardown  ch01 --org acme-co            # delete (confirm), or add --yes
```

## Namespacing & teardown safety model

- **Every** created resource is prefixed `wth-<chid>-*` (e.g. `wth-ch01-issues-labels-projects`, `wth-ch12-juice-shop`).
- `teardown` calls `guard_prefix` before every deletion. Any name that does not start with `wth-<chid>-` is **refused**, so the tool can never delete a pre-existing customer repo or project.
- `--dry-run` routes every mutation through a planner that prints `[plan] would run: …` and changes nothing. Use it first against a customer org.
- `provision` is create-only and idempotent; `teardown` is the only destructive path and is double-guarded (prefix + confirmation).
- Some platform/admin changes (audit settings, org policies) can't be cleanly reverted by script — those challenges document manual cleanup in their `COACH.md`.

## Juice Shop import (GHAS challenges)

`app: juice-shop` challenges import **OWASP Juice Shop** at the pinned ref (default `v20.0.0` from
`versions.lock`; override per-challenge in `meta.yml` or with `--ref`). The importer shallow-clones
the tag, **strips history**, fresh-inits, and pushes to a **public** `wth-<chid>-juice-shop` repo.
Juice Shop is MIT-licensed; its `LICENSE` is preserved in the push. **It is never vendored into this repo.**

## Authoring a new challenge provisioner (the contract)

`setup.sh` reads `challenges/<chid>-<slug>/meta.yml` (`app`, `requires`, `provision_creates`,
`juice_shop_ref`), then sources `challenges/<chid>-<slug>/provision.sh` and calls into it.

Each `provision.sh` **must** define exactly three functions:

```bash
wth_provision    # create-if-absent, idempotent, dry-run aware
wth_teardown     # delete ONLY wth-<chid>-* (call guard_prefix first)
wth_status       # report what currently exists
```

`setup.sh` exports for you: `ORG CHID SLUG APP JUICE_SHOP_REF DRY_RUN ASSUME_YES NAMESPACE REPO META`,
and the lib helpers are in scope: `log_*`, `run_mutation`, `gh_*`, `guard_prefix`, `meta_*`,
`juice_shop_import`. The PowerShell twin (`provision.ps1`) defines `Invoke-WthProvision` /
`Invoke-WthTeardown` / `Invoke-WthStatus` and uses the `$Global:Wth*` globals.

**`ch01` is the worked reference** — copy its `provision.sh` / `provision.ps1` shape for new challenges.

Rules every provisioner upholds: route mutations through `run_mutation` / `Invoke-WthMutation`;
check-then-create for idempotency; name everything `wth-<chid>-*`; `guard_prefix` before any delete.

See [../CONTRIBUTING-BUILD.md](../CONTRIBUTING-BUILD.md) for the full build contract.
