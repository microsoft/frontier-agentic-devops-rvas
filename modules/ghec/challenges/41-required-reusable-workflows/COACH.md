# Ch41: Required Reusable Workflows Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); `README.md` is canonical for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record workflow library, consumer cohort, enforcement mechanism, and approving owner.
- **Evidence:** link reusable workflow version, consumer workflow run, PR merge-block evidence, and ruleset/required-workflow setting.
- **Open risk:** record unpinned actions, missing exceptions, breaking-change risk, or `none`.
- **Next decision:** record next repository cohort and workflow version review.

## Reviewer focus

- Confirm setup did not enforce org-wide controls.
- Verify the reusable workflow is called by immutable tag or SHA where required by policy.
- Confirm private workflow-library Actions **Access** is configured before the consumer run; otherwise the caller fails even when the YAML is correct.
- Ask how teams request exceptions and how library changes are rolled out.
- Confirm the merge gate actually blocks when the reusable workflow fails or is absent.
