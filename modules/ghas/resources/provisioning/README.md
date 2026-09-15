# GHAS Admin Fixtures

The Admin & Governance track uses four separate provisioners. Each script owns a
small repository or a fixed set of fixture artifacts. Run the script beside the
activity that needs it instead of provisioning every lab at once.

## Prerequisites

- GitHub CLI authenticated to the target organization
- Git and the tools named by the activity
- Permission to create repositories in the organization

Use `--dry-run` or `-DryRun` to inspect planned changes. Use `status` after
provisioning to check the files, branches, issues, and pull requests that the lab
expects.

## Fixture map

| Activities | Default repository | Provisioner |
| --- | --- | --- |
| `ghas-admin-01`, `ghas-admin-06` | `ghas-admin-01-06-security-operations` | `challenges/admin-01-06-security-configuration-campaigns-fixture/` |
| `ghas-admin-02` | `ghas-admin-02-secret-operations` | `challenges/02-admin-secret-protection-operations-rebuild-secret-operations/` |
| `ghas-admin-03`, `ghas-admin-04` | `ghas-admin-03-04-codeql-live-lab` | `challenges/ghas-admin-codeql-live-20260915/` |
| `ghas-admin-05` | `ghas-admin-05-dependency-visibility-fixture` | `challenges/ghas-admin-05-dependency-visibility-fixture/` |

The repository names and branch names do not overlap. The 01/06 fixture is shared
on purpose because the final activity measures the rollout started in activity 01.
The CodeQL fixture is also shared because activity 04 tests the pull request
prepared in activity 03.

## Bash

Run these commands from the curriculum repository root:

```bash
bash modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.sh provision --org <org>
bash modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.sh provision --org <org>
bash modules/ghas/resources/provisioning/challenges/ghas-admin-codeql-live-20260915/provision.sh provision --org <org>
bash modules/ghas/resources/provisioning/challenges/ghas-admin-05-dependency-visibility-fixture/provision.sh provision --org <org>
```

Replace `provision` with `status` to inspect a fixture. Teardown for the 01/06,
02, and 05 fixtures deletes the repository and requires `--yes`. CodeQL teardown
keeps the repository, removes only its fixture files and branches, and also
requires `--yes`.

## PowerShell

```powershell
pwsh -File modules/ghas/resources/provisioning/challenges/admin-01-06-security-configuration-campaigns-fixture/provision.ps1 provision -Org <org>
pwsh -File modules/ghas/resources/provisioning/challenges/02-admin-secret-protection-operations-rebuild-secret-operations/provision.ps1 provision -Org <org>
pwsh -File modules/ghas/resources/provisioning/challenges/ghas-admin-codeql-live-20260915/provision.ps1 -Action provision -Org <org>
pwsh -File modules/ghas/resources/provisioning/challenges/ghas-admin-05-dependency-visibility-fixture/provision.ps1 provision -Org <org>
```

Use `status` in place of `provision`. Add `-Yes` for teardown.

**Do not replace seeded values with live credentials.** The fixtures use
synthetic data and disposable branches so learners can prove the controls without
putting production secrets at risk.
