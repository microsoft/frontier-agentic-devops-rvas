# Ch31 — Copilot Environment & Instructions — Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md). `README.md` is the canonical task, evidence, and Definition of Done guide.

## Assurance record

- **Authorized scope:** customer target/default branch, data boundary, approvers, and named repository, Copilot, security, and runner owners.
- **Evidence:** default-branch commit SHA; Actions workflow URL/log; instruction inventory and precedence review; cloud-agent session and/or code-review URL; runner/secrets decision.
- **Open risk:** unavailable policy/feature, conflicting instruction, non-ephemeral runner, service, secret, or unobserved behavior, with accountable owner.
- **Next decision:** approve an eligible pilot, remediate the environment, retain inspect-and-propose, or mark unavailable/not applicable.

## Reviewer focus

- Confirm the customer target came first. `ghec-ch31-*` is a safe fallback only and must not be represented as customer-production evidence.
- Open the default branch and confirm `.github/workflows/copilot-setup-steps.yml` has exactly one `copilot-setup-steps` job. Verify a normal Actions run succeeded; a feature-branch file alone is not activated for Copilot.
- Check the job uses only supported customization surfaces, minimal permissions, an explicit timeout no greater than 59 minutes, and no unjustified service, write scope, or secret.
- Verify the team understands the shared baseline: cloud agent and code review use setup steps by default. Require a documented, review-specific reason before accepting `copilot-code-review.yml`.
- Inspect repository-wide, matching path-specific, agent, and organization instructions. Confirm GitHub.com precedence is recorded as personal, path-specific repository, repository-wide, agent, then organization, and that conflicts are resolved rather than left to model behavior.
- Check the runner evidence: standard hosted baseline or approved cost/network posture; ephemeral single-use cloud-agent runner; ARC-only Ubuntu x64 self-hosted code-review runner; no broad internal network.
- Confirm Agents secrets/variables—not Actions, Codespaces, or Dependabot types—are the only cloud-agent environment inputs. No demonstration secret is acceptable.
- Require actual visible evidence: Actions log plus a cloud-agent session log and/or code-review result. Where unavailable or limited, accept only a dated decision package that names the limitation and owner.
- **Governance controls:** for approved cloud-agent use, confirm `COP-CLOUD-AGENT` in the existing register with policy, repository eligibility, review gates, environment evidence, and owner. Otherwise use `inspect-and-propose`, `not applicable`, or the customer equivalent.
