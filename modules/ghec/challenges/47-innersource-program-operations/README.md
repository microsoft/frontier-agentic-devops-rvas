# Ch47 — InnerSource Program Operations

> Deliver an InnerSource operating model: program charter, discoverable pilot hub, maintainer expectations, contribution-ready backlog, and adoption evidence.

| | |
|---|---|
| Track | Developer Flow |
| Difficulty | Intermediate |
| Duration | ~3.5 hrs total, multi-session |
| Minimum input | An org + repository admin rights. |
| App | Provisioned InnerSource hub repository (created by setup) |
| EMU compatible | yes |

## Customer delivery target

- Customer objective: turn ad hoc internal collaboration into an operated InnerSource program.
- Customer-tenant target: a real hub or pilot repository that teams can discover and contribute to.
- Approval and safety boundary: do not loosen production branch protections or repository access during setup; access decisions remain explicit participant work.
- Records to keep: charter, maintainer roster, contribution guidelines, labels, pilot backlog, adoption metrics, and next review.
- Adoption owner / handover: the InnerSource program owner or developer experience team accepts ongoing operations.
- Next action and owner: onboard the first pilot repository cohort or publish the hub.

## Prerequisites

- An organization on GitHub Enterprise Cloud.
- A token with the scopes listed by `modules/ghec/resources/provisioning/scripts/setup.sh doctor ch47 --org <org>`.
- Local tooling: `gh >= 2.x`, `git`, `jq`.
- A candidate repository or program hub, or the seeded fallback repository.

## Customer delivery objectives

This delivery engagement establishes:

- Define a program charter with owner, scope, metrics, and operating cadence.
- Make an InnerSource hub discoverable with README, CONTRIBUTING, CODEOWNERS, support path, and labels.
- Prepare contribution-ready issues with maintainer ownership and response expectations.
- Document access, review, and branch protection expectations without weakening controls.
- Record adoption evidence and next pilot actions.

## Scenario

Several teams want to share internal tools, but contributors cannot tell what is safe to change, who reviews pull requests, or how maintainers prioritize outside help. Your job is to create the operating layer: a hub, clear contribution paths, labeled work, maintainer expectations, and metrics.

> [!IMPORTANT]
> Prefer a real customer hub or pilot repository. If none is available, use the `ghec-ch47-innersource-hub` fallback and transfer the operating model to the approved target after validation.

## Sample test repository or environment

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch47 --org <org>
```
```powershell
modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch47 --org <org>
```

What setup creates:

- `ghec-ch47-innersource-hub` with README, CONTRIBUTING, CODEOWNERS, and support notes.
- InnerSource labels for contribution readiness and maintainer workflow.
- Sample program issues for charter, pilot intake, and metrics.

## Tasks

### Part A — Define the operating charter

1. Name the program owner, participating repository cohort, maintainer expectations, and success metrics.
2. Decide what qualifies a repository for InnerSource participation.
3. Record review cadence, escalation path, and exception process.

### Part B — Make the hub discoverable

4. Review or create README content that explains the program, how to find work, and how to get support.
5. Review `CONTRIBUTING.md` for contribution flow, review SLA, and maintainer responsibilities.
6. Confirm CODEOWNERS or maintainer mapping exists for the pilot areas.

### Part C — Prepare contribution-ready work

7. Create or triage issues labeled for contribution readiness:
   ```bash
   gh issue list --repo <org>/ghec-ch47-innersource-hub --label 'innersource: good-first-contribution'
   ```
8. Ensure each issue has context, acceptance criteria, owner, and expected review path.
9. Record which labels indicate blocked, ready, mentored, or maintainer-needed work.

### Part D — Verify controls and metrics

10. Confirm branch protection, required reviews, or rulesets remain compatible with safe contributions.
11. Record adoption metrics: active pilot repos, ready issues, response SLA, merged external-to-team PRs, and maintainer load.
12. Handover the program runbook and next review.

## Validation / Definition of Done

- [ ] Program charter names scope, owner, metrics, cadence, and participating repositories.
- [ ] Hub or pilot repository has README, CONTRIBUTING, CODEOWNERS, support path, and labels.
- [ ] Contribution-ready issues are labeled and include owner, acceptance criteria, and review route.
- [ ] Access and branch/review expectations are documented without weakening production controls.
- [ ] Governance evidence records owner, onboarding path, metrics, exceptions, and next review.
- [ ] Adoption handover names the program owner and first pilot/review action.

## Reference links

- Using InnerSource in your enterprise — https://docs.github.com/en/enterprise-cloud@latest/admin/concepts/enterprise-best-practices/use-innersource
- About CODEOWNERS — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- Setting guidelines for contributors — https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/setting-guidelines-for-repository-contributors
- Managing labels — https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels
- About READMEs — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-repository-readmes
