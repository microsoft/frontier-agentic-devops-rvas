# Ch30: Copilot policy baseline

**Session outcome:** An approved pilot team can use the selected Copilot feature under the customer's policy. A real session or review verifies access, and the owner has a tested way to remove it.

## Prerequisites

Include the Copilot policy owner and the administrator who can manage access. Select a small approved pilot team and one eligible repository. An authorized policy export supports preparation but cannot replace access to configure and test the pilot.

Choose one feature the team needs, such as Copilot Chat or code review. Do not enable every AI feature, install third-party agents, or add MCP servers for this session.

## Configure the pilot

1. Select the customer organization and inspect its subscription and identity model. Record which Copilot features are available and which are blocked by plan or policy.
2. Capture dated enterprise AI Controls and organization Copilot settings. For each relevant policy, record the effective value and who controls it. Distinguish enterprise enforcement from delegated or organization-managed settings. Without enterprise access, mark that evidence unavailable.
3. Check the seat-assignment source and an actual offboarding record with the identity owner. Verify when access ended against the current plan's behavior; do not equate a billing charge ending with access revocation.
4. Inspect public-code matching and the permitted GitHub.com features. Have the owner approve what code and data users may submit. Record how users request an exception.
5. Have the policy owner approve the selected feature and pilot audience. In the effective enterprise or organization Copilot policy, enable only what this pilot needs, or verify the existing policy already permits it. If an enterprise policy blocks the feature, stop and obtain enterprise-owner approval; do not work around it.
6. Under **Organization settings → Copilot → Access**, assign access through the customer's approved user or team mechanism. Reuse existing seats. Record the prior access state so the owner can reverse a test grant without removing someone else's working access.
7. Have an intended pilot user sign in with their own identity and use the selected feature on approved non-sensitive content. For Chat, ask it to explain a small function and check the answer against the code. For code review, request **Copilot** in a small PR's **Reviewers** sidebar and assess its comments. Preserve required human review. [Ch31](../31-copilot-environment-instructions/README.md) provides repository setup when it is needed.
8. With the access owner and a consenting temporary test user, remove that user's pilot access through the same assignment source. Allow for the documented propagation behavior and test again. Check for another entitlement before claiming access ended. Restore an approved grant if the user needs ongoing access.
9. Keep the pilot policy, useful session or review, and revocation result in the adoption issue. Name the next approved team and the owner who will grant its access. Leave the working pilot enabled only when its owner accepts it.

## Optional controls already used or proposed

- For each third-party agent or agent app, review vendor data handling and the installed App's permissions and repository selection. Policy approval alone does not approve an installation.
- Inspect existing MCP configuration and permitted tools. Record the host and data boundary. Do not run server tools or expose a new credential.
- Check eligibility for agentic activity streaming and any existing destination. A missing or preview feature remains unverified. Configuring a stream needs a separate approved change.

Reuse existing evidence from Ch29 and Ch31. Use Ch19 for an eligible cloud-agent pilot and Ch34 for cross-organization configuration.

## Completion

Keep the live access and revocation results as [completion evidence](../../../README.md#completion-evidence). A policy export alone is assessment evidence. Missing entitlement, approval, or a usable feature leaves implementation **blocked / not tested**.

## References

- [Enterprise Copilot policies](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-enterprise-policies)
- [Organization Copilot access](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-organization/manage-access)
- [Agent management](https://docs.github.com/en/copilot/concepts/enterprise/agent-management)
