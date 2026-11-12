# Ch30: Copilot policy baseline

**Session outcome:** An approved pilot team can use the selected Copilot feature under the customer's policy. A real session or review confirms the access works, and the owner has a tested way to remove it.

## Prerequisites

Involve the Copilot policy owner and the administrator who manages access. Pick a small approved pilot team and one eligible repository. An authorized policy export helps you prepare, but you still need access to configure and test the pilot.

Choose one feature the team needs, such as Copilot Chat or code review. Don't enable every AI feature, install third-party agents, or add MCP servers in this session.

## Configure the pilot

1. Select the customer organization and check its subscription and identity model. Record which Copilot features are available and which the plan or policy blocks.
2. Capture dated enterprise AI Controls and organization Copilot settings. For each relevant policy, record the effective value and who controls it, and whether the enterprise enforces it or the organization manages it. Without enterprise access, mark that evidence unavailable.
3. With the identity owner, check the seat-assignment source and a real offboarding record. Verify when access actually ended under the current plan. A billing charge ending doesn't mean access ended.
4. Check public-code matching and the permitted GitHub.com features. Have the owner approve what code and data users may submit, and record how users request an exception.
5. Have the policy owner approve the selected feature and pilot audience. In the effective enterprise or organization Copilot policy, enable only what this pilot needs, or verify the existing policy already allows it. If an enterprise policy blocks the feature, stop and get enterprise-owner approval. Don't work around it.
6. Under **Organization settings → Copilot → Access**, assign access the way the customer approves, by user or by team. Reuse existing seats. Record the prior access state, so the owner can reverse a test grant without removing someone else's working access.
7. Have an intended pilot user sign in with their own identity and use the selected feature on approved non-sensitive content. For Chat, ask it to explain a small function and check the answer against the code. For code review, request **Copilot** in a small PR's **Reviewers** sidebar and assess its comments. Keep required human review. If you need repository setup, see [Ch31](../31-copilot-environment-instructions/README.md).
8. With the access owner and a consenting temporary test user, remove that user's pilot access through the same assignment source. Allow for the documented propagation delay, then test again. Check for another entitlement before you claim access ended. Restore an approved grant if the user needs ongoing access.
9. Keep the pilot policy, the session or review, and the revocation result in the adoption issue. Name the next approved team and who will grant its access. Leave the pilot enabled only if its owner accepts it.

## Optional controls already used or proposed

- For each third-party agent or agent app, review vendor data handling and the installed App's permissions and repository selection. Policy approval alone doesn't approve an installation.
- Check existing MCP configuration and permitted tools. Record the host and data boundary. Don't run server tools or expose a new credential.
- Check eligibility for agentic activity streaming and any existing destination. A missing or preview feature stays unverified. Configuring a stream needs a separate approved change.

Reuse evidence from Ch29 and Ch31. Use Ch19 for a cloud agent pilot and Ch34 for cross-organization configuration.

## Completion

Keep the live access and revocation results as [completion evidence](../../../README.md#completion-evidence). A policy export alone is assessment evidence. If an entitlement, approval, or usable feature is missing, mark implementation **blocked / not tested**.

## References

- [Enterprise Copilot policies](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-enterprise/manage-enterprise-policies)
- [Organization Copilot access](https://docs.github.com/en/copilot/how-tos/administer-copilot/manage-for-organization/manage-access)
- [Agent management](https://docs.github.com/en/copilot/concepts/enterprise/agent-management)
